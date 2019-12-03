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
#import "MIReadingWordsView.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "MICheckWordsViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioPlayerViewController.h"
#import "MReadWordsViewController.h"
#import <iflyMSC/iflyMSC.h>
#import "ISRDataHelper.h"
#import "lame.h"


static NSString * const kKeyOfCreateTimestamp = @"createTimestamp";
static NSString * const kKeyOfAudioDuration = @"audioDuration";
static NSString * const kKeyOfVideoDuration = @"videoDuration";

@interface MReadWordsViewController ()<
AVAudioRecorderDelegate,
IFlySpeechRecognizerDelegate
>


@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *wordLabel;
@property (weak, nonatomic) IBOutlet UIView *progressBgView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressHeight;

@property (weak, nonatomic) IBOutlet UIButton *backBtn;

@property (strong,nonatomic) NSTimer *wordsTimer;

@property (assign,nonatomic) int currentWordIndex;
@property (nonatomic,strong) HomeworkItem *wordsItem;

@property (nonatomic,strong) NSMutableArray *progressViews;

// 1:正在录制  2:录制完成
@property (assign,nonatomic) NSInteger recordState;

// 录音
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;

// 语音识别
@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;
@property (strong, nonatomic) NSArray *resultArray; // 识别结果
@property (assign, nonatomic,) NSInteger recognizerIndex;
@property (assign, nonatomic) NSInteger recognizerCount;

@property (assign,nonatomic) BOOL recognizing;


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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _progressViews = [NSMutableArray array];
    HomeworkItem *tempWordItem =  self.homework.items.lastObject;
    // 处理单词随机
    if ([tempWordItem.type isEqualToString:@"word"]) {
       
        self.wordsItem = tempWordItem;
        if (self.wordsItem.playMode) {

            NSMutableArray * randomWords = [NSMutableArray arrayWithArray:self.wordsItem.words];
            [randomWords shuffle];
            self.wordsItem.randomWords = (NSArray<WordInfo> *)randomWords;
        } else {
            self.wordsItem.randomWords = self.wordsItem.words;
        }
    }
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus == AVAuthorizationStatusAuthorized) {

        [self startTask];
    } else {
        
        [HUD showWithMessage:@"请先打开您的麦克风"];
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
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
//        progress.layer.cornerRadius = progressHeight/2.0;
        [self.progressBgView addSubview:progress];
        
        [_progressViews addObject:progress];
    }
//    self.progressBgView.layer.cornerRadius = 2.0;
    
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
    
    self.wordLabel.hidden = NO;
    self.timeLabel.hidden = YES;
    self.wordLabel.text = [NSString stringWithFormat:@"Ready"];
    
     if (self.wordsItem.randomWords.count == 0) {
         [HUD showErrorWithMessage:@"无单词内容"];
         [self.navigationController popViewControllerAnimated:YES];
         return;
     }
    
    [self startCountTime];
}

- (void)stopTask{
    
    [self invalidateTimer];
}

#pragma mark - 1.开始倒计时 ，播放单词
- (void)startCountTime{

    [self stopTask];
    _recordState = 1;
    _currentWordIndex = 0;

    // 启动定时器
    [self invalidateTimer];
    [self.wordsTimer fireDate];
    
    for (UIView *progress in self.progressViews) {
        progress.backgroundColor = [UIColor detailColor];
    }
}

- (void)starRecoreFound{
    
    [self removeRecordSound];
    // 开始录音
    NSString *soundFilePath = [self getRecordSoundPath];
    NSURL *url = [NSURL fileURLWithPath:soundFilePath];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    
    NSError *error = nil;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:[self audioRecordingSettings] error:&error];
    self.audioRecorder.delegate = self;
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
    // 停止录制
    [[AudioPlayer sharedPlayer] stop];
    [weakSelf.audioRecorder stop];
    weakSelf.audioRecorder = nil;
    self.duration = ceil([[NSDate date] timeIntervalSinceDate:self.startTime]);

    // 开始识别
    self.recognizing = YES;
    self.recognizerIndex = 0;
    self.resultArray = nil;
    self.recognizerCount = [self componentsCount];
    [self recognizerAudioStreamIndex:self.recognizerIndex count:self.recognizerCount];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    
//    NSLog(@" audioRecorderDidFinishRecording 耗时%.fms", [[NSDate date] timeIntervalSinceDate:self.startTime]*1000);
}

#pragma mark - 定时播放任务
- (void)countTimeMethod {

    NSInteger index = 0;

    NSInteger playTime = (int)self.wordsItem.playtime/1000;
    if (playTime == 0) {
        playTime = 1;
    }

    if (playTime == 1) { // 单词播放时间间隔为1单独处理

        if (_currentWordIndex <= 0) {

            index = _currentWordIndex;
            _currentWordIndex ++;
            if (index == 0) {

                self.wordLabel.hidden = NO;
                self.timeLabel.hidden = YES;
                self.wordLabel.text = [NSString stringWithFormat:@"Go!"];
            }
            return;
        } else {
            
            index = _currentWordIndex;
            _currentWordIndex ++;
        }
        
        if (index == 1) {

            WordInfo *tempWord = self.wordsItem.randomWords.firstObject;
            self.wordLabel.text = tempWord.english;
            UIView *view = self.progressViews.firstObject;
            view.backgroundColor = [UIColor mainColor];
           
            [self starRecoreFound];  // 开始录音
        } else {
            
            if (index >= self.wordsItem.randomWords.count) { // 停止录音
              
                // 停止计时
               [self invalidateTimer];
               // 停止录音
               [self stopRecordFound];
               [self performSelector:@selector(showPlayGoodJob) withObject:nil afterDelay:1.0];
                
               UIView *view = self.progressViews.lastObject;
               view.backgroundColor = [UIColor mainColor];
               return;
            } else { // 播放单词
                
                self.wordLabel.hidden = NO;
                self.timeLabel.hidden = YES;
                
                WordInfo *tempWord = self.wordsItem.randomWords[index - 1];
                self.wordLabel.text = tempWord.english;
                
                if (index - 1 <= self.progressViews.count) {
                    WeakifySelf;
                    [UIView animateWithDuration:0.5 animations:^{
                        
                        UIView *view = weakSelf.progressViews[index - 1];
                        view.backgroundColor = [UIColor mainColor];
                    }];
                }
            }
        }
        
    } else { // ready go播放间隔为1，单词播放间隔不为1

        if (_currentWordIndex <= 0) {
            index = _currentWordIndex;
            _currentWordIndex ++;

            if (index == 0) {

                self.wordLabel.hidden = NO;
                self.timeLabel.hidden = YES;
                self.wordLabel.text = [NSString stringWithFormat:@"Go!"];
            }
            return;
        } else {
         
            NSInteger totalTime = self.wordsItem.randomWords.count * playTime;
            if (_currentWordIndex > totalTime) {
               
                // 停止计时
                [self invalidateTimer];
                // 停止录音
                [self stopRecordFound];
                [self performSelector:@selector(showPlayGoodJob) withObject:nil afterDelay:1.0];
                return;
            }

            if (_currentWordIndex%playTime == 1) {
                index = _currentWordIndex/playTime;
                _currentWordIndex ++;
            } else {

               _currentWordIndex ++;
                return;
            }
        }
        
        if (index <= 0) {// 倒计时

            if (index == 0) {

                WordInfo *tempWord = self.wordsItem.randomWords.firstObject;
                self.wordLabel.text = tempWord.english;
                UIView *view = self.progressViews.firstObject;
                view.backgroundColor = [UIColor mainColor];
                // 开始录音
                [self starRecoreFound];
            }
        } else { // 播放单词
            
            if (index < self.wordsItem.randomWords.count) {
                
                self.wordLabel.hidden = NO;
                self.timeLabel.hidden = YES;
                
                WordInfo *tempWord = self.wordsItem.randomWords[index];
                self.wordLabel.text = tempWord.english;
                
                if (index < self.progressViews.count) {
                    WeakifySelf;
                    [UIView animateWithDuration:0.5 animations:^{
                        
                        UIView *view = weakSelf.progressViews[index];
                        view.backgroundColor = [UIColor mainColor];
                    }];
                }
            }
        }
    }

//    NSLog(@" wordLabel %.fs  %@", [[NSDate date] timeIntervalSinceDate:self.startTime],self.wordLabel.text);
}

#pragma mark - 3.是否提交
- (void)finishedToast{

    if (self.recognizing == YES) {
        [HUD showProgressWithMessage:@"正在处理中，请稍后"];
        return;
    } else {
        [HUD hideAnimated:YES];
    }
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
    
    NSString *soundFilePath = [self getRecordSoundPath];
    NSData *data = [NSData dataWithContentsOfFile:soundFilePath];
    if (data.length == 0) {
        [HUD showErrorWithMessage:@"未找到录制语音文件"];
        [self finishedToast];
        return;
    }
    if (self.duration <= 2) {
        [HUD showErrorWithMessage:@"录制语音时间过短"];
        [self finishedToast];
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [HUD showProgressWithMessage:@"正在上传语音..."];
        WeakifySelf;
        [[FileUploader shareInstance] uploadData:data
                                            type:UploadFileTypeWav
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
                                                                    @"randomWords":wordsArray,
                                                                    @"recognitionWords":self.resultArray,
                                                                    @"playtime":@(self.wordsItem.playtime)
                                                       }];
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

- (void)showFirstWord{
    
    WordInfo *tempWord = self.wordsItem.randomWords.firstObject;
    self.wordLabel.text = tempWord.english;
}

- (void)showPlayGoodJob{

    _recordState = 2;
   
    self.wordLabel.text = @"Good job!"; // 播放完成提示音
    [[AudioPlayer sharedPlayer] playLocalURL:@"goodjob"];
    [self performSelector:@selector(finishedToast) withObject:nil afterDelay:0.2];
}

#pragma mark - 音频识别
- (void)recognizerAudioStreamIndex:(NSInteger)index count:(NSInteger)count{

    NSLog(@"recognizerIndex :%lu",index);
    //设置音频源为音频流（-1）
    [self.iFlySpeechRecognizer setParameter:@"-1" forKey:@"audio_source"];
    //启动识别服务
    [self.iFlySpeechRecognizer startListening];

    //写入音频数据
    NSString *pcmFilePath = [self getRecordSoundPath];
    NSData *data = [NSData dataWithContentsOfFile:pcmFilePath];    //从文件中读取音频

    //采样频率(kHz) x 采样位数 x 声道数 x 时间(秒) / 8 = 文件大小(kb)
    NSUInteger interval = [self componentSize];
    
    NSInteger lastLength = 44 + interval * index;
    // 音频数据分段
    if (index >= count - 1) {// 最后一段
        interval = data.length - lastLength;
    }
    if (lastLength + interval <= data.length) {

        NSData *piceData = [data subdataWithRange:NSMakeRange(lastLength, interval)];
        BOOL success = [self.iFlySpeechRecognizer writeAudio:piceData];//写入音频
        NSLog(@"writeAudio %d",success);
    }
   
//    整段识别
//    for (int i = 0; i < count; i++) {
//
//        if (index == count - 1) {// 最后一段
//            interval = data.length - lastLength;
//        }
//        if (lastLength + interval <= data.length) {
//
//            NSData *piceData = [data subdataWithRange:NSMakeRange(lastLength, interval)];
//            [self.iFlySpeechRecognizer writeAudio:piceData];
//        }
//        lastLength += interval;
//    }

    //音频写入结束或出错时，必须调用结束识别接口
    [self.iFlySpeechRecognizer stopListening];//音频数据写入完成，进入等待状态
}

- (void)stopRecognizer{
    [self.iFlySpeechRecognizer cancel];
    [self.iFlySpeechRecognizer stopListening];
    [self.iFlySpeechRecognizer destroy];
}

- (IFlySpeechRecognizer *)iFlySpeechRecognizer{
    
    if (!_iFlySpeechRecognizer) {
        
        _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
        [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
//        [_iFlySpeechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        _iFlySpeechRecognizer.delegate = self;
        
        //采样率
//        [_iFlySpeechRecognizer setParameter:@"16000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
        [_iFlySpeechRecognizer setParameter:@"8000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
        //(EOS) 后端点
        [_iFlySpeechRecognizer setParameter:@"10000" forKey:[IFlySpeechConstant VAD_EOS]];
        //(BOS) 前端点
        [_iFlySpeechRecognizer setParameter:@"10000" forKey:[IFlySpeechConstant VAD_BOS]];
        //set language
        [_iFlySpeechRecognizer setParameter:@"zh_cn" forKey:[IFlySpeechConstant LANGUAGE]];
        //set accent
        [_iFlySpeechRecognizer setParameter:@"mandarin" forKey:[IFlySpeechConstant ACCENT]];
        // 是否有标点
        [_iFlySpeechRecognizer setParameter:@"0" forKey:[IFlySpeechConstant ASR_PTT]];
    }
    return _iFlySpeechRecognizer;
}

#pragma mark - IFlySpeechRecognizerDelegate
- (void) onCompleted:(IFlySpeechError *) error
{
    [self stopRecognizer];
    self.iFlySpeechRecognizer = nil;
    self.recognizerIndex++;
    if (self.recognizerIndex < self.recognizerCount) {

        [self recognizerAudioStreamIndex:self.recognizerIndex count:self.recognizerCount];
        NSLog(@"xxxxxxxxxxxxxxxxxxxxxxx");
    } else {
        self.recognizing = NO;
        [self finishedToast];
        NSLog(@"xxxxxxxxxxxxxxxxxxxxxxx finish");
    }
}

- (void)onResults:(NSArray *)results isLast:(BOOL)isLast {

    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    NSString * resultFromJson =  nil;
    resultFromJson = [ISRDataHelper stringFromJson:resultString];
    NSLog(@"resultFromJson=%@ %d",resultFromJson,isLast);
    
    if (resultFromJson.length == 0) {
        // 无识别结果
        resultFromJson = @"";
    }
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.resultArray];
    [tempArray addObject:resultFromJson];
    self.resultArray = tempArray;
}

- (NSUInteger)componentsCount{// 分段数量

    NSData *data = [NSData dataWithContentsOfFile:[self getRecordSoundPath]];    //从文件中读取音频
    return floor((CGFloat)data.length/[self componentSize]);
}


- (NSUInteger)componentSize{// 分段字节大小

    //采样频率(kHz) x 采样位数 x 声道数 x 时间(秒) / 8 = 文件大小(kb)
    NSUInteger interval = 8 * 16 * 1 * (self.wordsItem.playtime/1000) / 8 * 1000;
    return interval;
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
    if ([NSData dataWithContentsOfURL:[NSURL URLWithString:soundFilePath]].length) {

        [[NSFileManager defaultManager] removeItemAtPath:soundFilePath
                                                error:nil];
    }
}

- (NSString *)getRecordSoundPath{
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sample.wav"];
    return soundFilePath;
}

- (NSDictionary *)audioRecordingSettings{
    
    NSDictionary *settings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithFloat:8000], AVSampleRateKey,//采样率
                          [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,// 录音格式
                          [NSNumber numberWithInt:1], AVNumberOfChannelsKey,//声道数
                          [NSNumber numberWithInt:16], AVEncoderBitRateKey,// 编码比特率
                          [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,// 位深度
                          [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,//大端还是小端,是内存的组织方式
                          [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,//采样信号是整数还是浮点数
                          [NSNumber numberWithInt:AVAudioQualityMedium],AVEncoderAudioQualityKey,
                          nil];
    return settings;
}

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
