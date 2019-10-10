//
//  MIFollowUpViewController.m
//  Minnie
//
//  Created by songzhen on 2019/8/26.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "PushManager.h"
#import "AudioPlayer.h"
#import "FileUploader.h"
#import "MIToastView.h"
#import "MIFollowUpViewController.h"

static NSString * const kKeyOfCreateTimestamp = @"createTimestamp";
static NSString * const kKeyOfAudioDuration = @"audioDuration";
static NSString * const kKeyOfVideoDuration = @"videoDuration";

@interface MIFollowUpViewController (){
    
    id _progressObserve;
}
@property (weak, nonatomic) IBOutlet UIButton *backBtn;

@property (weak, nonatomic) IBOutlet UIImageView *coverImageV;
@property (weak, nonatomic) IBOutlet UIView *recordingView;

@property (weak, nonatomic) IBOutlet UIView *recordGrayView;
@property (weak, nonatomic) IBOutlet UIView *recordRedView;
@property (weak, nonatomic) IBOutlet UIView *startRecordView;
@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageTopConstraint;

@property (strong,nonatomic) HomeworkItem *followItem;

@property (strong,nonatomic) NSTimer *followTimer;

// 音频播放
@property (nonatomic, strong) AVPlayer *audioPlayer;
// 1:正在录制  2:录制完成
@property (assign,nonatomic) NSInteger recordState;

// 录音
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startBtnConstraintHeight;


@end

@implementation MIFollowUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.followItem = self.homework.otherItem.firstObject;
    [self configureUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    
    if (self.isChecking) {
        
        [self.audioPlayer pause];
    } else {
        
        [self stopRecordFound];
        [self invalidateTimer];
        [self.audioPlayer pause];
        [self removeRecordSound];
        [self removePlayerProgress];
    }
}


- (void)configureUI{
    
    if (isIPhoneX) {
        
        self.startBtnConstraintHeight.constant = 60;
    } else {
       
        self.startBtnConstraintHeight.constant = 44;
    }
    
    self.recordGrayView.layer.cornerRadius = 15;
    self.recordGrayView.layer.masksToBounds = YES;
    self.recordGrayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
    
    self.recordRedView.layer.cornerRadius = 7.5;
    self.recordRedView.layer.masksToBounds = YES;
    
//    [self.coverImageV sd_setImageWithURL:[self.followItem.audioCoverUrl imageURLWithWidth:ScreenWidth] placeholderImage:[UIImage imageNamed:@"attachment_placeholder"]];
    
    WeakifySelf;
    [self.coverImageV sd_setImageWithURL:[NSURL URLWithString:self.followItem.audioCoverUrl] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
       
        if (image.size.width > 0) {
            // 图片显示区域高度
            CGFloat contentHeight = ScreenHeight- kNaviBarHeight - kTabBarHeight - 12;
            CGFloat imageHeight = ScreenWidth * image.size.height / image.size.width;
            CGFloat pointY = 0;
            if (imageHeight < contentHeight) {
             
                pointY = (contentHeight - imageHeight)/2.0;
            }
            weakSelf.imageTopConstraint.constant = pointY;
            weakSelf.imageHeightConstraint.constant = imageHeight;
        }
    }];
    
    
    if (self.isChecking) {
        self.recordingView.hidden = YES;
        [self.startRecordBtn setImage:[UIImage imageNamed:@"btn_play_green"] forState:UIControlStateNormal];
        [self.startRecordBtn setImage:[UIImage imageNamed:@"btn_stop_green"] forState:UIControlStateSelected];
        [self.startRecordBtn setTitle:@"" forState:UIControlStateNormal];
    } else {
        
        self.recordingView.hidden = NO;
        [self.startRecordBtn setImage:[UIImage imageNamed:@"nil"] forState:UIControlStateNormal];
        [self.startRecordBtn setImage:[UIImage imageNamed:@"nil"] forState:UIControlStateNormal];
        [self.startRecordBtn setTitle:@"开始" forState:UIControlStateNormal];
    }
}


- (IBAction)backAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)startRecordAction:(id)sender {
    
    if (self.isChecking) {
       
        if (self.startRecordBtn.selected) {
          
            [self.audioPlayer pause];
            self.startRecordBtn.selected = NO;
        } else {
           
            // 播放音频
            if (self.followItem.audioUrl.length) {
               
                self.audioPlayer = [self getPlayerWith:self.audioUrl isLocal:NO];
                self.audioPlayer.volume = 0.5;
                [self.audioPlayer play];
                
                self.startRecordBtn.selected = YES;
            }
        }
    } else {
        
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if (authStatus == AVAuthorizationStatusAuthorized) {

            [self startTask];
        } else {

            [HUD showWithMessage:@"请先打开您的麦克风"];
        }
    }
}

#pragma mark - 录音
- (void)starRecoreFound{
    
    [self removeRecordSound];
    
    // 开始录音
    NSString *soundFilePath = [self getRecordSoundPath];
    [[NSFileManager defaultManager] removeItemAtPath:soundFilePath error:nil];
    NSURL *url = [NSURL fileURLWithPath:soundFilePath];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    NSError *error = nil;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:[self audioRecordingSettings] error:&error];
    self.audioRecorder.meteringEnabled = YES;
    if ([self.audioRecorder prepareToRecord]){
        self.audioRecorder.meteringEnabled = YES;
        [self.audioRecorder record];
        self.duration = 0;
        self.startTime = [NSDate date];
        NSLog(@"starRecoreFound::%@",[NSDate date]);
    }
}

- (void)stopRecordFound{
    
    WeakifySelf;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 停止录制
        [[AudioPlayer sharedPlayer] stop];
        [weakSelf.audioRecorder stop];
        weakSelf.audioRecorder = nil;
        weakSelf.duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
        NSLog(@"stopRecordFound::%@",[NSDate date]);
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
    });
}

#pragma mark - private
- (void)removeRecordSound{
    
    NSString *soundFilePath = [self getRecordSoundPath];
    [[NSFileManager defaultManager] removeItemAtPath:soundFilePath
                                               error:nil];
}

- (NSString *)getRecordSoundPath{
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sample.aac"];
    return soundFilePath;
}

- (NSDictionary *)audioRecordingSettings{
    
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
                              [NSNumber numberWithFloat:16000], AVSampleRateKey,
                              [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                              [NSNumber numberWithInt:AVAudioQualityMedium], AVSampleRateConverterAudioQualityKey,
                              [NSNumber numberWithInt:64000], AVEncoderBitRateKey,
                              [NSNumber numberWithInt:8], AVEncoderBitDepthHintKey,
                              nil];
    
    return settings;
}


- (AVPlayer *)getPlayerWith:(NSString *)urlStr isLocal:(BOOL)isLocal{
    
    AVAudioSession *session =[AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    
    AVPlayerItem *playerItem;
    if (urlStr.length) {
        
        if (isLocal) {
            playerItem = [[AVPlayerItem alloc]initWithURL:[NSURL fileURLWithPath:urlStr]];
        } else {
            playerItem = [[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:urlStr]];
        }
    }
    AVPlayer *recordPlayer = [AVPlayer playerWithPlayerItem:playerItem];
    if (@available(iOS 10.0, *)) {
        
        recordPlayer.automaticallyWaitsToMinimizeStalling = NO;
    }
    recordPlayer.volume = 1.0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vedioPlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    return recordPlayer;
}


#pragma mark - 进度
- (void)removePlayerProgress{
    
    if (_progressObserve) {
        
        [self.audioPlayer removeTimeObserver:_progressObserve];
        _progressObserve = nil;
    }
}

- (void)addPlayerProgress{
    
    if (!_progressObserve) {
        WeakifySelf;
        // 监听进度
        _progressObserve = [self.audioPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            
            if (!weakSelf) return;
            CGFloat currentTime = weakSelf.audioPlayer.currentItem.currentTime.value/weakSelf.audioPlayer.currentItem.currentTime.timescale;// 计算当前在第几秒
            CGFloat duration = CMTimeGetSeconds(weakSelf.audioPlayer.currentItem.duration);
            int surplus = duration - currentTime;
            NSString *surplusTime = [NSString stringWithFormat:@"%.2d:%.2d",surplus/60,surplus%60];
            [weakSelf.startRecordBtn setTitle:surplusTime forState:UIControlStateNormal];
        }];
    }
}


#pragma mark - 1.开始任务
- (void)startTask{

    _recordState = 1;
//    self.startRecordView.hidden = YES;
    // 播放音频
    if (self.followItem.audioUrl.length) {
        [self removePlayerProgress];
        self.audioPlayer = [self getPlayerWith:self.followItem.audioUrl isLocal:NO];
        [self addPlayerProgress];
        self.audioPlayer.volume = 0.5;
        [self.audioPlayer play];
    }
    // 开始录音
    [self starRecoreFound];
    // 开启播放状态
    [self startTimer];
}

#pragma mark - 2.音视频播放完成
- (void)vedioPlayDidEnd:(NSNotification *)notify{
    
    AVPlayerItem *playItem = notify.object;
    if (playItem == self.audioPlayer.currentItem) {
       
        if (self.isChecking) {
            self.startRecordBtn.selected = NO;
        } else {
           
            _recordState = 2;
            [self stopRecordFound];
            [self invalidateTimer];
            [self.audioPlayer pause];
            [self finishedToast];
        }
    }
}

#pragma mark - 3.是否提交
- (void)finishedToast{
    
    WeakifySelf;
    [MIToastView setTitle:@"是否提交作业？"
                  confirm:@"重新来过"
                   cancel:@"立即提交"
                superView:self.view
             confirmBlock:^{
                 
                 [weakSelf startTask];
             } cancelBlock:^{
                 
                 [weakSelf uploadRecord];
             }];
    
    [self.view addSubview:self.backBtn];
}

#pragma mark - 4.上传录制音频
- (void)uploadRecord{
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sample.aac"];
    NSData *data = [NSData dataWithContentsOfFile:soundFilePath];
    if (data.length == 0) {
        [HUD showErrorWithMessage:@"未找到录制语音文件"];
        [self finishedToast];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [HUD showProgressWithMessage:@"正在上传语音..."];
        WeakifySelf;
        [[FileUploader shareInstance] uploadData:data
                                            type:UploadFileTypeAudio
                                   progressBlock:^(NSInteger number) {
                                       [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传语音%@%%...", @(number)]];
                                   }
                                 completionBlock:^(NSString * _Nullable audioUrl, NSError * _Nullable error) {
                                     if (audioUrl.length > 0) {
                                         [[NSFileManager defaultManager] removeItemAtPath:soundFilePath
                                                                                    error:nil];
                                         
                                         [HUD hideAnimated:YES];
                                         [weakSelf sendAudioMessage:[NSURL URLWithString:audioUrl] duration:weakSelf.duration];
                                     } else {
                                         [HUD showErrorWithMessage:@"音频上传失败"];
                                         [weakSelf finishedToast];
                                     }
                                 }];
    });
}
#pragma mark - 5.发送消息
- (void)sendAudioMessage:(NSURL *)audioURL duration:(CGFloat)duration {
    int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    AVFile *file = [AVFile fileWithRemoteURL:audioURL];
    NSInteger d = (NSInteger)duration;
    NSString *typeName =  kHomeworkTaskFollowUpName;
    AVIMAudioMessage *message = [AVIMAudioMessage messageWithText:@"audio"
                                                             file:file
                                                       attributes:@{kKeyOfCreateTimestamp:@(timestamp),
                                                                    kKeyOfAudioDuration:@(d),
                                                                    @"typeName":typeName}];
    [self sendMessage:message];
}

- (void)sendMessage:(AVIMMessage *)message {
    
    //发送消息之前进行IM服务判断
    NSString *userId;
    NSString *clientId = [IMManager sharedManager].client.clientId;
    AVIMClientStatus status = [IMManager sharedManager].client.status;
#if MANAGERSIDE
    userId = [NSString stringWithFormat:@"%@", @(self.teacher.userId)];
#else
    userId = [NSString stringWithFormat:@"%@", @(APP.currentUser.userId)];
#endif
    if ([userId isEqualToString:clientId] && status == AVIMClientStatusOpened) {
    } else {
        [[IMManager sharedManager] setupWithClientId:userId callback:^(BOOL success,  NSError * error) {
            if (!success) return ;
        }];
    }
    if (status != AVIMClientStatusOpened) {
        [HUD showErrorWithMessage:@"IM服务暂不可用，请稍后再试"];
        [self finishedToast];
        return;
    }
    
    NSString *text = @"[语音]";
    AVIMMessageOption *option = [[AVIMMessageOption alloc] init];
    option.pushData = @{@"alert":@{@"body":text,@"action-loc-key":@"com.minine.push",@"loc-key":@(PushManagerMessage)}, @"badge":@"Increment",@"pushType" :@(PushManagerMessage),@"action":@"com.minine.push"};
    
    WeakifySelf;
    [self.conversation sendMessage:message
                            option:option
                          callback:^(BOOL succeeded, NSError * _Nullable error) {
                              
                              if (succeeded) {
                                  if (weakSelf.finishCallBack) {
                                      weakSelf.finishCallBack((AVIMAudioMessage *)message);
                                  }
                                  [[NSNotificationCenter defaultCenter] postNotificationName:kIMManagerContentMessageDidSendNotification object:nil userInfo:@{@"message": message}];
                                  
                                  [weakSelf.navigationController popViewControllerAnimated:YES];
                              } else {
                                  
                                  [HUD showErrorWithMessage:@"发送消息失败"];
                                  [weakSelf finishedToast];
                              }
                          }];
}


#pragma mark -
- (void)didEnterBackground{
    
    if (_recordState != 2) {
        
        [HUD showErrorWithMessage:@"录音失败"];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)startTimer{
    
    [self invalidateTimer];
    [self.followTimer fireDate];
}

- (void)invalidateTimer{
    
    self.recordRedView.hidden = NO;
    [self.followTimer invalidate];
    self.followTimer = nil;
}


#pragma mark setter && getter
- (NSTimer *)followTimer{
    
    if (!_followTimer) {
        
        _followTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(isRecording) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_followTimer forMode:NSDefaultRunLoopMode];
    }
    return _followTimer;
}

- (void)isRecording{
   
    static BOOL show = YES;
    self.recordRedView.hidden = !show;
    show = !show;
}

- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
