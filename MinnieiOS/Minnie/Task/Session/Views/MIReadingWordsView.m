//
//  MIReadingWordsView.m
//  Minnie
//
//  Created by songzhen on 2019/6/10.
//  Copyright © 2019 minnieedu. All rights reserved.
//
#import "MIReadingWordsView.h"
#import <AVFoundation/AVFoundation.h>

@interface WordSlider : UISlider

@end

@implementation WordSlider


- (CGRect)trackRectForBounds:(CGRect)bounds{
    
    CGRect newBounds = bounds;
    newBounds.origin.y = 5;
    newBounds.size.height = 15;
    return newBounds;
}

@end


@interface MIReadingWordsView (){
    
    
    BOOL _isSliding;
}

@property (weak, nonatomic) IBOutlet UIView *wordsView;
@property (weak, nonatomic) IBOutlet UILabel *englishLabel;

@property (strong,nonatomic) NSTimer *wordsTimer;

@property (assign,nonatomic) NSInteger currentWordIndex;
@property (weak, nonatomic) IBOutlet UIView *bgProgressView;

//@property (strong, nonatomic) WordSlider *sliderView;

@property (strong, nonatomic) UIProgressView *progressView;

@property (strong,nonatomic) NSMutableArray *progressViews;


@end


@implementation MIReadingWordsView

-(void)awakeFromNib{
   
    [super awakeFromNib];
    self.progressViews = [NSMutableArray array];
    
    self.progressView = [[UIProgressView alloc] init];
//    self.sliderView = [[WordSlider alloc] init];
    [self.bgProgressView addSubview:self.progressView];
    self.progressView.progress = 0.0;
    self.progressView.layer.cornerRadius = 0.0;
    self.progressView.layer.masksToBounds = YES;
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.edges.equalTo(self.bgProgressView);
    }];
    
//    [self.sliderView setMinimumTrackTintColor:[UIColor mainColor]];
//    [self.sliderView setMaximumTrackTintColor:[UIColor unSelectedColor]];
    
//    [self.progressView addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
//    [self.progressView addTarget:self action:@selector(sliderValueFinished:) forControlEvents:UIControlEventTouchUpInside];
//    [self.progressView setThumbImage:[UIImage imageNamed:@"thum"] forState:UIControlStateNormal];
//    [self.sliderView setThumbImage:[UIImage imageNamed:@"thum"] forState:UIControlStateHighlighted];
    
    self.progressView.progressTintColor = [UIColor mainColor];
    self.progressView.trackTintColor = [UIColor unSelectedColor];
    
    WordInfo *tempWord = _wordsItem.randomWords.firstObject;
    self.englishLabel.text = tempWord.english;
}

- (void)setWordsItem:(HomeworkItem *)wordsItem{
    
    _wordsItem = wordsItem;
    WordInfo *tempWord = _wordsItem.randomWords.firstObject;
    self.englishLabel.text = tempWord.english;
}

- (void)sliderValueChanged:(id)sender {
    
}

- (void)sliderValueFinished:(id)sender {
   
//    NSInteger tempIndex = roundf(self.sliderView.value * self.wordsItem.words.count) - 1;
//    _currentWordIndex = tempIndex;
//
//    if (self.readingWordsSeekCallBack) {
//        self.readingWordsSeekCallBack(self.sliderView.value);
//    }
//    [self startPlayWords];
//
//    _isSliding = NO;
//    [self playWords];
    
}

- (void)startPlayWords{
  
    if (_currentWordIndex >= self.wordsItem.randomWords.count) {
        _currentWordIndex = 0;
        WordInfo *tempWord = _wordsItem.randomWords.firstObject;
        self.englishLabel.text = tempWord.english;
        self.progressView.progress = 0.0;
    }
    if (_currentWordIndex == 0) {
        
        WordInfo *tempWord = _wordsItem.randomWords.firstObject;
        self.englishLabel.text = tempWord.english;
        self.progressView.progress = 1.0/self.wordsItem.randomWords.count;
    }
    [self stopPlayWords];
    [self.wordsTimer fireDate];
}

- (void)stopPlayWords{
    
    [self.wordsTimer invalidate];
    self.wordsTimer = nil;
}


- (void)seekToWordInterval:(NSInteger)interval{
    
    _currentWordIndex = _currentWordIndex + interval;

    WordInfo *tempWord;
    if (interval < 0) {
        
        if ( _currentWordIndex <= 0) {
            _currentWordIndex = 1;
        } else if ( _currentWordIndex > self.wordsItem.randomWords.count) {
             _currentWordIndex  = 1;
        }
        tempWord = self.wordsItem.randomWords[_currentWordIndex - 1];
    } else {
       
        if ( _currentWordIndex <= 0) {
            _currentWordIndex = 1;
        } else if ( _currentWordIndex > self.wordsItem.randomWords.count) {
            _currentWordIndex  = 1;
        }
        tempWord = self.wordsItem.randomWords[_currentWordIndex - 1];
    }
    self.englishLabel.text = tempWord.english;
    self.progressView.progress = (CGFloat)(_currentWordIndex -1)/self.wordsItem.randomWords.count;
    
    if (self.readingWordsSeekCallBack) {
        self.readingWordsSeekCallBack(_currentWordIndex - 1);
    }
    [self startPlayWords];
}

-(NSTimer *)wordsTimer{
    
    if (!_wordsTimer) {
        NSInteger playTime = self.wordsItem.playtime/1000;
        if (playTime == 0) {
            playTime = 2.0;
        }
        _wordsTimer = [NSTimer scheduledTimerWithTimeInterval:playTime target:self selector:@selector(playWords) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_wordsTimer forMode:NSDefaultRunLoopMode];
    }
    return _wordsTimer;
}

- (void)invalidateTimer{
    _currentWordIndex = 0;
    [self.wordsTimer invalidate];
    self.wordsTimer = nil;
}

- (void)playWords{
    
    NSInteger index = _currentWordIndex;
    if (index < self.wordsItem.randomWords.count) {
        
        WordInfo *tempWord = self.wordsItem.randomWords[index];
        self.englishLabel.text = tempWord.english;
        if (self.readingWordsProgressCallBack) {
            self.readingWordsProgressCallBack(index);
        }
    }
    
    self.progressView.progress = (CGFloat)(index+1)/self.wordsItem.randomWords.count;
    
    _currentWordIndex ++;
    
    if (index > self.wordsItem.randomWords.count) {
        
        if (self.readingWordsFinishCallBack) {
            self.readingWordsFinishCallBack();
        }
        [self stopPlayWords];
    }
}

@end
