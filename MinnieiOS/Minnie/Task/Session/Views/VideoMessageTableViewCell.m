//
//  VideoMessageTableViewCell.m
//  X5
//
//  Created by yebw on 2017/10/14.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "VideoMessageTableViewCell.h"
#import "MaskImageView.h"
#import <SDWebImage/UIImageView+WebCache.h>

CGFloat const VideoMessageTableViewCellHeight = 152.f;

NSString * const LeftVideoMessageTableViewCellId = @"LeftVideoMessageTableViewCellId";
NSString * const RightVideoMessageTableViewCellId = @"RightVideoMessageTableViewCellId";

@interface VideoMessageTableViewCell()

@property (weak, nonatomic) IBOutlet UIImageView *shareSelectImaV;

@property (nonatomic, weak) IBOutlet MaskImageView *coverImageView;

@property (nonatomic, assign) BOOL shareSelected;

@property (nonatomic, copy) NSString *currentVideoUrl;


@end

@implementation VideoMessageTableViewCell

- (void)awakeFromNib{
    
    [super awakeFromNib];
    self.coverImageView.userInteractionEnabled = YES;
    
    
    if ([self.reuseIdentifier isEqualToString:LeftVideoMessageTableViewCellId]){
        
        [self.contentView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)]];
    }
}

- (void)longPressGesture:(UILongPressGestureRecognizer *)longGest{
    
    // 教师端 长按学生发过来视频选中，指定当前选中视频为分享
    if (longGest.state == UIGestureRecognizerStateEnded) {
        
        if (self.shareSelected) {
            self.shareSelected = NO;
            self.shareSelectImaV.hidden = YES;
            
            if (self.shareVideoUrlCallBack) {
                self.shareVideoUrlCallBack(nil);
            }
        } else {
            self.shareSelected = YES;
            self.shareSelectImaV.hidden = NO;
            
            if (self.shareVideoUrlCallBack) {
                self.shareVideoUrlCallBack(self.currentVideoUrl);
            }
        }
    }
}

- (void)setupSelectedVideo:(BOOL)selected{
    
    if ([self.reuseIdentifier isEqualToString:LeftVideoMessageTableViewCellId]){
        
        self.shareSelected = selected;
        self.shareSelectImaV.hidden = !selected;
    }
}

- (void)setupWithUser:(User *)user message:(AVIMTypedMessage *)message {
    [super setupWithUser:user message:message];
    NSInteger secCount = [[message.attributes objectForKey:@"videoDuration"] integerValue];
    self.currentVideoUrl = message.file.url;
    if (secCount > 0)
    {
        NSInteger min = secCount / 60;
        NSInteger sec = secCount % 60;
        self.timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld",min,sec];
    }
    else
    {
        self.timeLabel.text = @"";
    }
    
    [self.coverImageView sd_setImageWithURL:[message.file.url videoCoverUrlWithWidth:218.f height:140.f]];

    NSString *backgroundImageName = message.ioType==AVIMMessageIOTypeIn?@"对话框_白色":@"对话框_蓝色";
    UIImage *maskImage = [[UIImage imageNamed:backgroundImageName] resizableImageWithCapInsets:UIEdgeInsetsMake(30, 20, 10, 20) resizingMode:UIImageResizingModeStretch];
    [self.coverImageView fitShapeWithMaskImage:maskImage
                                     topCapInset:30
                                    leftCapInset:20
                                            size:CGSizeMake(218, 140)];
}

- (IBAction)playButtonPressed:(id)sender {
    if (self.videoPlayCallback != nil) {
        self.videoPlayCallback();
    }
}

@end
