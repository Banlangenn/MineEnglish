//
//  MIStudentWordsViewController.m
//  MinnieStudent
//
//  Created by songzhen on 2019/8/8.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <NSArray+YYAdd.h>
#import "MIToastView.h"
#import "AppDelegate.h"
#import "IMManager.h"
#import "PushManager.h"
#import "AudioPlayer.h"
#import "FileUploader.h"
#import "VICacheManager.h"
#import "MIReadingWordsView.h"
#import "VIResourceLoaderManager.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "MICheckWordsViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioPlayerViewController.h"
#import "MReadWordsViewController.h"
#import "AudioPlayerManager.h"


static NSString * const kKeyOfCreateTimestamp = @"createTimestamp";
static NSString * const kKeyOfAudioDuration = @"audioDuration";
static NSString * const kKeyOfVideoDuration = @"videoDuration";

@interface MReadWordsViewController ()


@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *wordLabel;
@property (weak, nonatomic) IBOutlet UIView *progressBgView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressHeight;

@property (weak, nonatomic) IBOutlet UIButton *backBtn;

@property (strong,nonatomic) NSTimer *wordsTimer;

@property (assign,nonatomic) NSInteger currentWordIndex;
@property (nonatomic,strong) HomeworkItem *wordsItem;

@property (nonatomic,strong) NSMutableArray *progressViews;

// 1:正在录制  2:录制完成
@property (assign,nonatomic) NSInteger recordState;
// 背景音乐
@property (nonatomic, strong) AVPlayer *bgMusicPlayer;

@property (nonatomic, strong) AudioPlayerManager *musicPlayer;

// 录音
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;

@end

@implementation MReadWordsViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setNewOrientation:YES];//调用转屏代码
    [self configureUI];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self setNewOrientation:NO];
  
    [self stopRecordFound];
    [self removeRecordSound];
    [self stopTask];
    [self.bgMusicPlayer pause];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _progressViews = [NSMutableArray array];
    HomeworkItem *tempWordItem =  self.homework.items.lastObject;
    tempWordItem.isRandom = YES;
    // 处理单词随机
    if ([tempWordItem.type isEqualToString:@"word"]) {
       
        self.wordsItem = tempWordItem;
        if (self.wordsItem.isRandom) {

            NSMutableArray * randomWords = [NSMutableArray arrayWithArray:self.wordsItem.words];
            [randomWords shuffle];
            self.wordsItem.randomWords = (NSArray<WordInfo> *)randomWords;
        } else {
            self.wordsItem.randomWords = self.wordsItem.words;
        }
    }
    
    // 准备播放
    [self.musicPlayer play:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationWillEnterForegroundNotification object:nil];

}


- (void)configureUI{
    
    CGFloat progressHeight = 5.0;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        progressHeight = 10.0;
    }
    self.progressHeight.constant = progressHeight;
    // 进度条
    CGFloat proWidth = ScreenWidth /self.wordsItem.randomWords.count;
    for (NSInteger i = 0; i < self.wordsItem.randomWords.count; i++) {
      
        UIView *progress = [[UIView alloc] init];
        if (i == 0) {
            progress.frame = CGRectMake(0, 0, proWidth - 1, progressHeight);
        } else if (i == self.wordsItem.randomWords.count - 1) {
            progress.frame = CGRectMake(i * proWidth + 1, 0, proWidth - 1, progressHeight);
        } else {
            progress.frame = CGRectMake(i * proWidth + 1, 0, proWidth - 2, progressHeight);
        }
        progress.backgroundColor = [UIColor detailColor];
        progress.layer.cornerRadius = progressHeight/2.0;
        [self.progressBgView addSubview:progress];
        
        [_progressViews addObject:progress];
    }
    self.progressBgView.layer.cornerRadius = 2.0;
    
    // 初始状态
    self.wordLabel.hidden = NO;
    self.wordLabel.text = [NSString stringWithFormat:@"Ready"];

    self.timeLabel.hidden = YES;
    self.timeLabel.layer.cornerRadius = 140;
    self.timeLabel.layer.masksToBounds = YES;
    self.timeLabel.layer.borderWidth = 5.0;
    self.timeLabel.layer.borderColor = [UIColor detailColor].CGColor;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.progressHeight.constant = 5.0;
    } else {
        self.progressHeight.constant = 10.0;
    }
}

- (IBAction)backAction:(id)sender {
  
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)startTask{
    
    [self startCountTime];
}

- (void)stopTask{
    
    [self invalidateTimer];
}

#pragma mark - 1.开始倒计时 ，播放单词
- (void)startCountTime{
   
    if (self.wordsItem.randomWords.count == 0) {
        [HUD showErrorWithMessage:@"无单词内容"];
        return;
    }
    [self stopTask];
    _recordState = 1;
    _currentWordIndex = -5;
    
    // 启动定时器
    [self invalidateTimer];
    [self.wordsTimer fireDate];
    
    for (UIView *progress in self.progressViews) {
        progress.backgroundColor = [UIColor detailColor];
    }
}

#pragma mark - 2.开始播放单词,播放背景音乐,并录音
//- (void)startPlayWords{
//
//    // 播放背景音乐
//    if (self.wordsItem.bgmusicUrl.length) {
//        self.bgMusicPlayer = [self getPlayerWith:self.wordsItem.bgmusicUrl isLocal:NO];
//        self.bgMusicPlayer.volume = 0.0;
//        [self.bgMusicPlayer play];
//        NSLog(@"startPlayWords");
//    }
//}


- (AudioPlayerManager *)musicPlayer{
    
    if (self.wordsItem.bgmusicUrl.length == 0) {
        return nil;
    }
    if (!_musicPlayer) {
        
        _musicPlayer = [[AudioPlayerManager alloc] initWithUrl:self.wordsItem.bgmusicUrl];
        WeakifySelf;
        _musicPlayer.statusBlock = ^(AVPlayerItemStatus status) {
            
            if (status == AVPlayerItemStatusReadyToPlay) {
                
                if (weakSelf.recordState != 1) {
                    [weakSelf.musicPlayer play:NO];
                }
                [weakSelf startTask];
            } else {
                
                if (weakSelf.recordState != 1) {
                [weakSelf.musicPlayer play:YES];
                }
            }
        };
        _musicPlayer.finishedBlock = ^{
            if (weakSelf.recordState == 1) {
                
                [weakSelf.musicPlayer play:YES];
            }
        };
    }
    return _musicPlayer;
}
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
    }
}

- (void)stopRecordFound{
    
    WeakifySelf;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 停止录制
        [[AudioPlayer sharedPlayer] stop];
        [weakSelf.audioRecorder stop];
        weakSelf.audioRecorder = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
    });
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
                                         [weakSelf sendAudioMessage:[NSURL URLWithString:audioUrl] duration:weakSelf. duration];
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
    NSString *typeName =  kHomeworkTaskWordMemoryName;
    
    // 随机后的单词
    NSMutableArray *wordsArray = [NSMutableArray array];
    for (WordInfo *info in self.wordsItem.randomWords) {
        NSDictionary *dict = @{@"english":info.english,
                               @"chinese":info.chinese};
        [wordsArray addObject:dict];
    }
    AVIMAudioMessage *message = [AVIMAudioMessage messageWithText:@"audio"
                                                             file:file
                                                       attributes:@{kKeyOfCreateTimestamp:@(timestamp),
                                                                    kKeyOfAudioDuration:@(d),
                                                                    @"typeName":typeName,
                                                                    @"randomWords":wordsArray}];
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

- (void)invalidateTimer{
    [self.wordsTimer invalidate];
    self.wordsTimer = nil;
}

#pragma mark - 定时播放任务
- (void)countTimeMethod {

    NSInteger index = 0;
    if (_currentWordIndex < 0) {
        index = _currentWordIndex;
        _currentWordIndex ++;
    } else {
     
        NSInteger playTime = self.wordsItem.playtime/1000;
        if (playTime < 1) {
            playTime = 1;
        }
        if (_currentWordIndex%playTime == 0) {
            index = _currentWordIndex/playTime;
            _currentWordIndex ++;
        } else {
            _currentWordIndex ++;
            return;
        }
    }
    
    if (index <= 0) {// 倒计时
        
        // 倒计时：4,3, 2, 1, 0  ready,3,2,1,go
        if (index >= -5 && index < 0) {// 播放
            
            NSString *url = [NSString stringWithFormat:@"count_%lu",-(index + 1)];
            [[AudioPlayer sharedPlayer] playLocalURL:url];
        }
        if (index == -5){
            
            self.wordLabel.hidden = NO;
            self.timeLabel.hidden = YES;
            self.wordLabel.text = [NSString stringWithFormat:@"Ready"];
        } else if (index >= -4 && index < -1) {
            
            self.wordLabel.hidden = YES;
            self.timeLabel.hidden = NO;
            self.timeLabel.text = [NSString stringWithFormat:@"%lu",-(index + 1)];
        } else if (index == -1){
            
            self.wordLabel.hidden = NO;
            self.timeLabel.hidden = YES;
            self.wordLabel.text = [NSString stringWithFormat:@"Go!"];
        }
        if (index == 0) {
            
            WordInfo *tempWord = self.wordsItem.randomWords.firstObject;
            self.wordLabel.text = tempWord.english;
            UIView *view = self.progressViews.firstObject;
            view.backgroundColor = [UIColor mainColor];
            
            [self.musicPlayer seekToTime:1.0];
            // 开始录音
            [self starRecoreFound];
        }
    } else { // 播放单词
        
        if (index > 0 && index - 1 < self.wordsItem.randomWords.count) {
            
            self.wordLabel.hidden = NO;
            self.timeLabel.hidden = YES;
            
            WordInfo *tempWord = self.wordsItem.randomWords[index - 1];
            self.wordLabel.text = tempWord.english;
            
            if (index - 1 < self.progressViews.count) {
                WeakifySelf;
                [UIView animateWithDuration:0.5 animations:^{
                    
                    UIView *view = weakSelf.progressViews[index - 1];
                    view.backgroundColor = [UIColor mainColor];
                }];
            }
        }
        
        if (index - 1 == self.wordsItem.randomWords.count) {
            
            // 停止背景音乐
            [self.musicPlayer play:NO];
            // 停止录音
            [self stopRecordFound];
            [self performSelector:@selector(playGoodJob) withObject:nil afterDelay:0.5];
        } else if (index - 1 > self.wordsItem.randomWords.count) {
            
            _recordState = 2;
            [self invalidateTimer];
            
            [self performSelector:@selector(finishedToast) withObject:nil afterDelay:0.5];
        }
    }
}

- (void)showFirstWord{
    
    WordInfo *tempWord = self.wordsItem.randomWords.firstObject;
    self.wordLabel.text = tempWord.english;
}

- (void)playGoodJob{
    
    self.wordLabel.text = @"Good job!";
    // 播放完成提示音
    [[AudioPlayer sharedPlayer] playLocalURL:@"goodjob"];
}

#pragma mark setter && getter
- (NSTimer *)wordsTimer{
    
    if (!_wordsTimer) {
        
        _wordsTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countTimeMethod) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_wordsTimer forMode:NSDefaultRunLoopMode];
    }
    return _wordsTimer;
    
}

#pragma - 设置横屏切换
- (void)setNewOrientation:(BOOL)fullscreen{
    
    AppDelegate * appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.allowRotation = fullscreen;//(打开,关闭横屏开关)
    if (fullscreen) {
        
        NSNumber *resetOrientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
        [[UIDevice currentDevice] setValue:resetOrientationTarget forKey:@"orientation"];
        NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight];
        [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
    }else{
        
        NSNumber *resetOrientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
        [[UIDevice currentDevice] setValue:resetOrientationTarget forKey:@"orientation"];
        NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
    }
}

#pragma mark -
- (void)didEnterBackground{
    
    if (_recordState != 2) {
      
        [HUD showErrorWithMessage:@"录音失败"];
        [self.navigationController popViewControllerAnimated:YES];
    }
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

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
