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
    newBounds.origin.y = 0;
    newBounds.size.height = 40;
    return newBounds;
}

@end


@interface MIReadingWordsView (){
    
    
    BOOL _isSliding;
}

@property (weak, nonatomic) IBOutlet UIView *wordsView;
@property (weak, nonatomic) IBOutlet UILabel *englishLabel;

@property (assign,nonatomic) BOOL isSlider;
@property (weak, nonatomic) IBOutlet UIView *bgProgressView;

@property (strong, nonatomic) WordSlider *sliderView;

@property (strong,nonatomic) NSMutableArray *progressViews;

@property (strong, nonatomic) NSDate *preDate;


@end


@implementation MIReadingWordsView

-(void)awakeFromNib{
   
    [super awakeFromNib];
    
    self.sliderView = [[WordSlider alloc] init];
    self.sliderView.minimumValue = 0.f;
    self.sliderView.maximumValue = 1.f;
    self.sliderView.value = 0.f;
    [self.bgProgressView addSubview:self.sliderView];
    [self.sliderView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.edges.equalTo(self.bgProgressView);
    }];
    
    [self.sliderView setMinimumTrackTintColor:[UIColor mainColor]];
    [self.sliderView setMaximumTrackTintColor:[UIColor unSelectedColor]];
    
    [self.sliderView addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.sliderView addTarget:self action:@selector(sliderValueFinished:) forControlEvents:UIControlEventTouchUpInside];
    [self.sliderView setThumbImage:[UIImage imageNamed:@"thum"] forState:UIControlStateNormal];
    [self.sliderView setThumbImage:[UIImage imageNamed:@"thum"] forState:UIControlStateHighlighted];
    
    [self.sliderView setMinimumTrackImage:[UIImage imageNamed:@"thum"] forState:UIControlStateNormal];
    [self.sliderView setMaximumTrackImage:[UIImage imageNamed:@"thum_trace"] forState:UIControlStateNormal];
    
    
    WordInfo *tempWord = _wordsItem.randomWords.firstObject;
    self.englishLabel.text = tempWord.english;
}

- (void)setWordsItem:(HomeworkItem *)wordsItem{
    
    _wordsItem = wordsItem;
    WordInfo *tempWord = _wordsItem.randomWords.firstObject;
    self.englishLabel.text = tempWord.english;
}


- (void)showWordsWithIndex:(NSInteger)index{
    
    if ([[NSDate date] timeIntervalSinceDate:self.preDate] < 0.1) {
        return;
    }
    if (self.isSlider) {
        return;
    }
    if (index < self.wordsItem.randomWords.count) {
        // index 从0开始
        WordInfo *tempWord = _wordsItem.randomWords[index];
        self.englishLabel.text = tempWord.english;
        self.sliderView.value = (CGFloat)(index + 1)/self.wordsItem.randomWords.count;
    } else {

        WordInfo *tempWord = _wordsItem.randomWords.lastObject;
        self.englishLabel.text = tempWord.english;
        self.sliderView.value = 1.0;
    }
    self.preDate = [NSDate date];
}

- (void)sliderValueChanged:(id)sender {
    self.isSlider = YES;
    if (self.sliderValueChangedCallback) {
        self.sliderValueChangedCallback(YES,self.sliderView.value);
    }
}

- (void)sliderValueFinished:(id)sender {
    self.isSlider = NO;
    if (self.sliderValueChangedCallback) {
        self.sliderValueChangedCallback(NO,self.sliderView.value);
    }
}

@end
