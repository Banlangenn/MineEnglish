//
//  HomeworkAudioTableViewCell.m
//  X5Teacher
//
//  Created by yebw on 2018/1/24.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "HomeworkAudioTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIView+AZGradient.h"
NSString * const HomeworkAudioTableViewCellId = @"HomeworkAudioTableViewCellId";
CGFloat const HomeworkAudioTableViewCellHeight = 112.f;
CGFloat const HomeworkAudioWithMp3TableViewCellHeight = 164.f;


@interface HomeworkAudioTableViewCell()

@property (nonatomic, weak) IBOutlet UIImageView *audioCoverImageView;
@property (weak, nonatomic) IBOutlet UIView * mp3ContentView;
@property (weak, nonatomic) IBOutlet UIView * mp3FileView;
@property (weak, nonatomic) IBOutlet UILabel *mp3TitleLabel;

@property (nonatomic, copy) NSString *audioUrl;
@property (nonatomic, copy) NSString *audioCoverUrl;

@end

@implementation HomeworkAudioTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.audioCoverImageView.layer.cornerRadius = 12;
    self.audioCoverImageView.layer.masksToBounds = YES;
    
    self.mp3FileView.layer.cornerRadius = 12;
    self.mp3FileView.layer.masksToBounds = YES;
    
    [self.mp3FileView az_setGradientBackgroundWithColors:@[[UIColor colorWithHex:0xFF7C6B],[UIColor colorWithHex:0xFF395D]] locations:nil startPoint:CGPointMake(0, 0) endPoint:CGPointMake(1, 0)];

    [self.audioCoverImageView az_setGradientBackgroundWithColors:@[[UIColor colorWithHex:0xFF7C6B],[UIColor colorWithHex:0xFF395D]] locations:nil startPoint:CGPointMake(0, 0) endPoint:CGPointMake(1, 0)];
}

- (void)setupWithAudioUrl:(NSString *)audioUrl
                 coverUrl:(NSString *)coverUrl {
    
    if (coverUrl.length == 0)
    {
        self.mp3ContentView.hidden = YES;
        self.mp3TitleLabel.hidden = NO;
        [self.audioCoverImageView sd_setImageWithURL:nil];
    }
    else
    {
        self.mp3ContentView.hidden = NO;
        self.mp3TitleLabel.hidden = YES;
        [self.audioCoverImageView sd_setImageWithURL:[coverUrl imageURLWithWidth:182.0]];
    }
    
    self.audioUrl = audioUrl;
    
}

- (IBAction)imageButtonPressed:(id)sender {
    if (self.audioCoverUrl.length == 0) {
        
        if (self.playAudioCallback) {
            self.playAudioCallback(self.audioCoverUrl,self.audioUrl);
        }
    } else {

        if (self.imageCallback != nil) {
            self.imageCallback(self.audioCoverUrl);
        }
    }
}

- (IBAction)audioButtonPressed:(id)sender {
    
    if (self.playAudioCallback) {
        self.playAudioCallback(self.audioCoverUrl,self.audioUrl);
    }
}

- (IBAction)deleteMp3FilePressed:(id)sender {
    if (self.deleteFileCallback != nil) {
        self.deleteFileCallback();
    }
}

- (IBAction)deleteButtonPressed:(id)sender {
    if (self.deleteCallback != nil) {
        self.deleteCallback();
    }
}

@end


