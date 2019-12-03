//
//  MICheckWordsViewController.m
//  Minnie
//
//  Created by songzhen on 2019/6/9.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "AudioPlayer.h"
#import "MIReadingWordsView.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "MICheckWordsViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "MIRecordWaveView.h"
#import <AFNetworking/AFNetworking.h>
#import "AudioPlayerManager.h"
#import "ISRDataHelper.h"
#import <iflyMSC/iflyMSC.h>
#import "MITagsTableViewCell.h"

@interface MICheckWordsViewController ()<
UITableViewDelegate,
UITableViewDataSource,
NSURLSessionDownloadDelegate,
IFlySpeechRecognizerDelegate
>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *vedioBgView;

@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;
@property (weak, nonatomic) IBOutlet UILabel *startRecordLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong,nonatomic) MIReadingWordsView *wordsView;

@property (strong,nonatomic) MIRecordWaveView *recordWaveView;

@property (strong,nonatomic, ) AudioPlayerManager *audioPlayer;


@property (strong,nonatomic) HomeworkItem *currentWordItem;


@property (strong,nonatomic) NSURLSessionDownloadTask *downloadTask;

@property (strong,nonatomic) IFlySpeechRecognizer *iFlySpeechRecognizer;

@property (strong, nonatomic) NSMutableArray *wrongArray; // 识别结果
@property (assign, nonatomic,) NSInteger recognizerIndex;
@property (strong, nonatomic) UILabel *recognizerLabel;
@property (assign, nonatomic) NSInteger recognizerCount;
@property (strong, nonatomic) NSMutableString *answer;

@end

@implementation MICheckWordsViewController

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    // 查看作业
    [self cancelDownload];
    [self stopRecognizer];
    [self.audioPlayer resetCurrentPlayer];
    // 移除音频文件
    [[NSFileManager defaultManager] removeItemAtPath:[self filePath] error:nil];
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self configureData];
    [self configureUI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)configureData{
   
    self.titleLabel.text = kHomeworkTaskWordMemoryName;
    HomeworkItem *wordItem = self.homework.items.lastObject;
    
    // 处理要显示的单词数组
    if (self.randomDictWords.count > 0) {
     
        NSMutableArray *array = [NSMutableArray array];
        for (NSDictionary *wordDict in self.randomDictWords) {
            WordInfo *wordInfo = [[WordInfo alloc] init];
            wordInfo.chinese = wordDict[@"chinese"];
            wordInfo.english = wordDict[@"english"];
            [array addObject:wordInfo];
        }
        wordItem.randomWords = (NSArray<WordInfo> *)array;
    } else {
        wordItem.randomWords = wordItem.words;
    }
    
    if (self.commitPlayTime.integerValue > 0) {
        wordItem.commitPlaytime = self.commitPlayTime.integerValue;
    } else {
        if (wordItem.playtime == 0) {
            wordItem.playtime = 1000;
        }
        wordItem.commitPlaytime = wordItem.playtime;
    }
    self.currentWordItem = wordItem;
    
#if TEACHERSIDE || MANAGERSIDE
    
    // 单词识别结果(教师端显示)
//     NSDictionary *dict = [Utils getWordsText];
//     NSString *key = [self.audioUrl.lastPathComponent stringByDeletingPathExtension];
//     NSArray *textArray = [dict objectForKey:key];
//     if (textArray.count == 0) {
//         [self downloadWithUrl:self.audioUrl];
//     } else {
//         self.resultArray = textArray;
//     }
    self.wrongArray = [NSMutableArray array];
    _answer = [NSMutableString string];
    for (NSInteger i = 0; i < self.currentWordItem.randomWords.count; i++) {
        
        // 答案
        WordInfo *wordInfo = self.currentWordItem.randomWords[i];
        [_answer appendString:wordInfo.chinese];
        if (i < self.resultArray.count - 1) {
            [_answer appendString:@"，"];
        }
        // 识别结果
        NSString *text;
        if (i < self.resultArray.count) {
           
            text = self.resultArray[i];
            if (![text isEqualToString:wordInfo.chinese]) {
                  
                [self.wrongArray addObject:text];
            }
        }
    }
    self.tableView.hidden = NO;
#else
    self.tableView.hidden = YES;

#endif
}

- (void) configureUI{

    [self.tableView registerNib:[UINib nibWithNibName:@"MITagsTableViewCell" bundle:nil] forCellReuseIdentifier:MITagsTableViewCellId];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.startRecordBtn setBackgroundImage:[UIImage imageNamed:@"btn_play_green"] forState:UIControlStateNormal];
    [self.startRecordBtn setBackgroundImage:[UIImage imageNamed:@"btn_stop_green"] forState:UIControlStateSelected];
    self.startRecordLabel.text = @"点击查看录音";
    
    self.wordsView.wordsItem = self.currentWordItem;
    self.wordsView.hidden = NO;
    [self.vedioBgView addSubview:self.wordsView];
    WeakifySelf;
    [self.wordsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf.vedioBgView);
    }];
    
    self.recognizerLabel = [[UILabel alloc] init];
    self.recognizerLabel.font = [UIFont systemFontOfSize:14];
    self.recognizerLabel.numberOfLines = 0;
    self.recognizerLabel.textAlignment = NSTextAlignmentLeft;
}

- (NSAttributedString *)dealwithTextArray:(NSArray *)textArray{
    
    NSArray *words = self.currentWordItem.randomWords;
    NSMutableAttributedString *textAttr = [[NSMutableAttributedString alloc] init];
    for (NSInteger i = 0; i < textArray.count; i++) {
        NSString *text = textArray[i];
        WordInfo *wordInfo;
        if (i < words.count) {
            wordInfo = words[i];
        }
        NSDictionary *attri;
        if ([text isEqualToString:wordInfo.chinese]) {
            
           attri = @{NSFontAttributeName:[UIFont systemFontOfSize:14],
                     NSForegroundColorAttributeName:[UIColor blackColor]};
        } else {
            attri = @{NSFontAttributeName:[UIFont systemFontOfSize:14],
                      NSForegroundColorAttributeName:[UIColor redColor]};
        }
        NSAttributedString *attStr = [[NSAttributedString alloc] initWithString:text attributes:attri];
        [textAttr appendAttributedString:attStr];
        
        if (i < textArray.count - 1) {
            [textAttr appendAttributedString:[[NSAttributedString alloc] initWithString:@"、"]];
        }
    }
    return textAttr;
}
#pragma mark  actions
- (IBAction)backAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)startRecordAction:(id)sender {
   
    if (self.startRecordBtn.selected) { // 查看录音
        
        [self.audioPlayer play:NO];

        self.startRecordBtn.selected = NO;
        self.startRecordLabel.text = @"点击查看录音";
    } else {
        
        // 播放单词录音
        [self.audioPlayer play:YES];
        
        self.startRecordBtn.selected = YES;
        self.startRecordLabel.text = @"点击停止播放";
    }
}

- (IBAction)leftButtonAction:(id)sender {
   
    [self.audioPlayer play:NO];
    if (self.audioPlayer.current >= self.audioPlayer.duration) {
        // 播放倒数第二个
        CGFloat tempTime = (self.currentWordItem.randomWords.count - 2) * self.currentWordItem.commitPlaytime/1000;
        [self.audioPlayer seekToTime:tempTime];
        return;
    }
    
    CGFloat previousTime = self.audioPlayer.current - self.currentWordItem.commitPlaytime/1000;
    if (previousTime >= 0) {
         [self.audioPlayer seekToTime:previousTime];
    } else {
        [self.audioPlayer seekToTime:0];
    }
}

- (IBAction)rightButtonAction:(id)sender {
    
    [self.audioPlayer play:NO];
    
    CGFloat nextTime = self.audioPlayer.current + self.currentWordItem.commitPlaytime/1000;
    if (nextTime >= self.audioPlayer.duration) {
        // 播放第一个
        [self.audioPlayer seekToTime:0];
    } else {
        [self.audioPlayer seekToTime:nextTime];
    }
}

#pragma mark - tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
   
    if (indexPath.row == 0) {

        MITagsTableViewCell *tagsCell = [tableView dequeueReusableCellWithIdentifier:MITagsTableViewCellId forIndexPath:indexPath];
        tagsCell.type = HomeworkTagsTableViewCellSelectNoneType;
        tagsCell.selectionStyle = UITableViewCellSelectionStyleNone;

        tagsCell.selBgColor = [UIColor redColor];
        tagsCell.normalBgColor = [UIColor colorWithHex:0xebebeb];
        tagsCell.normalTextColor = [UIColor blackColor];
        tagsCell.cornerRadius = 8;
        tagsCell.righLabel.hidden = YES;
        tagsCell.managerBtn.hidden = YES;
        [tagsCell setupWithTags:self.resultArray selectedTags:self.wrongArray typeTitle:@"学生:" collectionWidth:ScreenWidth - 20];
        WeakifySelf;
        [tagsCell setSelectCallback:^(NSString *tag) {
            
            NSInteger index = [self.resultArray indexOfObject:tag];
            CGFloat time = index * weakSelf.currentWordItem.commitPlaytime/1000;
            [weakSelf.audioPlayer seekToTime:time];
        }];
        
        return tagsCell;
    } else {
        
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"recognizerCellId"];
        if (!cell) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"recognizerCellId"];
            [cell addSubview:self.recognizerLabel];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            CALayer *layer = [CALayer layer];
            layer.frame = CGRectMake(0, 0, ScreenWidth, 0.5);
            layer.backgroundColor = [UIColor lightGrayColor].CGColor;
            [cell.layer addSublayer:layer];
           

            UILabel *titleLabel = [[UILabel alloc] init];
            titleLabel.font = [UIFont boldSystemFontOfSize:16];
            titleLabel.text = @"教师:";
            titleLabel.textAlignment = NSTextAlignmentLeft;
            [cell addSubview:titleLabel];
            
            [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                
                make.height.equalTo(@18);
                make.top.equalTo(cell.mas_top).offset(20);
                make.left.equalTo(cell.mas_left).offset(15);
                make.right.equalTo(cell.mas_right).offset(-15);
            }];
            
            [self.recognizerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
               
                make.top.equalTo(titleLabel.mas_bottom).offset(25);
                make.left.equalTo(cell.mas_left).offset(15);
                make.right.equalTo(cell.mas_right).offset(-15);
            }];
        }
        
        self.recognizerLabel.text = self.answer;

        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row == 0) {
        
        return [MITagsTableViewCell heightWithTags:self.resultArray collectionWidth:ScreenWidth - 20] + 50;
    } else {
        return 200;
    }
}

#pragma mark setter && getter

- (MIReadingWordsView *)wordsView{
    
    if (!_wordsView) {
        
        _wordsView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIReadingWordsView class]) owner:nil options:nil].lastObject;
        WeakifySelf;
        _wordsView.sliderValueChangedCallback = ^(BOOL sliding, CGFloat value) {
            if (sliding) {

                [weakSelf.audioPlayer play:NO];
            } else {
               
                if (value * weakSelf.audioPlayer.duration >= weakSelf.audioPlayer.duration) {
                     
                     [weakSelf.audioPlayer seekToTime:weakSelf.audioPlayer.duration];
                 } else {
                     [weakSelf.audioPlayer seekToTime:value * weakSelf.audioPlayer.duration];
                 }
                 weakSelf.startRecordBtn.selected = YES;
                 weakSelf.startRecordLabel.text = @"点击停止播放";
            }
                     
        };
        _wordsView.playBtnChangedCallback = ^(BOOL isPlay) {
          
            if (isPlay) {
                // 播放单词录音
                [weakSelf.audioPlayer play:YES];
            } else {

                [weakSelf.audioPlayer play:NO];
            }
        };
    }
    return _wordsView;
}

- (AudioPlayerManager *)audioPlayer{
    
    if (!_audioPlayer) {
        
        _audioPlayer = [[AudioPlayerManager alloc] initWithUrl:self.audioUrl];
        
        WeakifySelf;
        _audioPlayer.statusBlock = ^(AVPlayerItemStatus status) {
            
            if (status == AVPlayerItemStatusFailed) {
                
                weakSelf.startRecordBtn.selected = NO;
                weakSelf.startRecordLabel.text = @"点击查看录音";
            } else if (status == AVPlayerItemStatusReadyToPlay) {
                
                weakSelf.startRecordBtn.selected = YES;
                weakSelf.startRecordLabel.text = @"点击停止播放";
            }
        };
        
        _audioPlayer.progressBlock = ^(CGFloat time, CGFloat duration) {
 
            if (weakSelf.currentWordItem.commitPlaytime > 0) {

                NSInteger currentIndex = time/(weakSelf.currentWordItem.commitPlaytime/1000);
                [weakSelf.wordsView showWordsWithIndex:currentIndex];
            }
        };
        
        _audioPlayer.finishedBlock = ^{
            
            weakSelf.startRecordBtn.selected = NO;
            weakSelf.startRecordLabel.text = @"点击查看录音";
            [weakSelf.audioPlayer play:NO];
        };
    }
    return _audioPlayer;
}

- (MIRecordWaveView *)recordWaveView{
    
    if (!_recordWaveView) {
        _recordWaveView = [[MIRecordWaveView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 150)];
    }
    
//    [self.recordAniBgView addSubview:_recordWaveView];
    return _recordWaveView;
}


- (void)didEnterBackground{
    
    [self.audioPlayer play:NO];
    
    self.startRecordBtn.selected = NO;
    self.startRecordLabel.text = @"点击查看录音";
}


#pragma mark - 下载音频
- (void)downloadWithUrl:(NSString *)vedioUrl{

    NSString *path = [self filePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        self.recognizerIndex = 0;
        self.recognizerCount = [self componentsCount];
        [self recognizerAudioStreamIndex:0 count:self.recognizerCount];
        return;
   }
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:vedioUrl]];
    [self.downloadTask resume];
}

- (void)cancelDownload{
   
    [self.downloadTask suspend];
    [self.downloadTask cancel];
    self.downloadTask = nil;
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{

    NSError *error = nil;
    NSString *path = [self filePath];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:path] error:&error];
    self.recognizerIndex = 0;
    self.recognizerCount = [self componentsCount];
    [self recognizerAudioStreamIndex:self.recognizerIndex count:self.recognizerCount];
}

- (NSString *)filePath{
   
    NSString *url = @"wordsAudio";
    NSString *cacheDirectory = NSTemporaryDirectory();
    NSString *pathComponent = [url stringByAppendingPathExtension:@"wav"];
    NSString *filePath = [cacheDirectory stringByAppendingPathComponent:pathComponent];
    NSLog(@"filePath %@",filePath);
    return filePath;
}

- (NSUInteger)componentsCount{// 分段数量

    NSData *data = [NSData dataWithContentsOfFile:[self filePath]];    //从文件中读取音频
    return floor((CGFloat)data.length/[self componentSize]);
}


- (NSUInteger)componentSize{// 分段字节大小
    
    //采样频率(kHz) x 采样位数 x 声道数 x 时间(秒) / 8 = 文件大小(kb)
    NSUInteger interval = 8 * 16 * 1 * (self.currentWordItem.commitPlaytime/1000) / 8 * 1000;
    return interval;
}

#pragma mark - 音频识别
- (void)recognizerAudioStreamIndex:(NSInteger)index count:(NSInteger)count{

    NSLog(@"recognizerIndex :%lu",index);
    //设置音频源为音频流（-1）
    [self.iFlySpeechRecognizer setParameter:@"-1" forKey:@"audio_source"];
    //启动识别服务
    [self.iFlySpeechRecognizer startListening];

    //写入音频数据
    NSString *pcmFilePath = [self filePath];
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
    } else {
        
       [Utils saveWordsTextWithKey:[self.audioUrl.lastPathComponent stringByDeletingPathExtension] value:self.resultArray];
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
        resultFromJson = @"     ";
    }
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.resultArray];
    [tempArray addObject:resultFromJson];
    self.resultArray = tempArray;
}


- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
