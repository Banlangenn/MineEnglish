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


@interface MICheckWordsViewController ()<
CAAnimationDelegate
>{

}
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *vedioBgView;

@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;
@property (weak, nonatomic) IBOutlet UILabel *startRecordLabel;

@property (strong,nonatomic) MIReadingWordsView *wordsView;

@property (nonatomic, strong) MIRecordWaveView *recordWaveView;

@property (nonatomic, strong) AudioPlayerManager *audioPlayer;
@property (weak, nonatomic) IBOutlet UIView *recordAniBgView;


@property (strong,nonatomic) HomeworkItem *currentWordItem;


@end

@implementation MICheckWordsViewController

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    // 查看作业
//    [self.wordsView invalidateTimer];
    [self.audioPlayer resetCurrentPlayer];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
 
    self.titleLabel.text = kHomeworkTaskWordMemoryName;
  
    HomeworkItem *wordItem = self.homework.items.lastObject;
    
    // 处理要显示的随机数组
    if (wordItem.playMode) {
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
        wordItem.commitPlaytime = wordItem.playtime;
    }
    self.currentWordItem = wordItem;
    
    [self configureUI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void) configureUI{
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.startRecordBtn setBackgroundImage:[UIImage imageNamed:@"btn_play_green"] forState:UIControlStateNormal];
    [self.startRecordBtn setBackgroundImage:[UIImage imageNamed:@"btn_stop_green"] forState:UIControlStateSelected];
    self.startRecordLabel.text = @"点击查看录音";
    
    self.wordsView.wordsItem = self.currentWordItem;
    self.wordsView.hidden = NO;
    [self.vedioBgView addSubview:self.wordsView];
    [self.wordsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.vedioBgView);
    }];
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
    if (self.audioPlayer.current - self.currentWordItem.commitPlaytime/1000 >= 0) {
         [self.audioPlayer seekToTime:self.audioPlayer.current - self.currentWordItem.commitPlaytime/1000];
    } else {
        [self.audioPlayer seekToTime:0];
    }
}

- (IBAction)rightButtonAction:(id)sender {
    
    [self.audioPlayer play:NO];

    if (self.audioPlayer.current + self.currentWordItem.commitPlaytime/1000 >= self.audioPlayer.duration) {
        [self.audioPlayer seekToTime:0];
    } else {
        [self.audioPlayer seekToTime:self.audioPlayer.current + self.currentWordItem.commitPlaytime/1000];
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
               
                if (value * weakSelf.audioPlayer.duration >= self.audioPlayer.duration) {
                     
                     [weakSelf.audioPlayer seekToTime:weakSelf.audioPlayer.duration];
                 } else {
                     [weakSelf.audioPlayer seekToTime:value * weakSelf.audioPlayer.duration];
                 }
                 weakSelf.startRecordBtn.selected = YES;
                 weakSelf.startRecordLabel.text = @"点击停止播放";
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
                NSLog(@"AVPlayerItemStatusReadyToPlay");
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
    
    [self.recordAniBgView addSubview:_recordWaveView];
    return _recordWaveView;
}


- (void)didEnterBackground{
    
    [self.audioPlayer play:NO];
    
    self.startRecordBtn.selected = NO;
    self.startRecordLabel.text = @"点击查看录音";
}


- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
