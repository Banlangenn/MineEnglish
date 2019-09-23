//
//  MITaskSheetTableViewCell.m
//  MinnieManager
//
//  Created by songzhen on 2019/9/23.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "MITaskSheetTableViewCell.h"

NSString * const MITaskSheetTableViewCellId = @"MITaskSheetTableViewCellId";
CGFloat const MITaskSheetTableViewHeight = 156.f;

@interface MITaskSheetTableViewCell ()
@property (weak, nonatomic) IBOutlet UIView *contentBgView;
@property (weak, nonatomic) IBOutlet UILabel *imageCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoCountLabel;

@property (assign, nonatomic) NSInteger imageCount;
@property (assign, nonatomic) NSInteger videoCount;
@end

@implementation MITaskSheetTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contentBgView.layer.cornerRadius = 12.f;
    self.contentBgView.layer.masksToBounds = NO;
    self.contentBgView.layer.borderWidth = 1.f;
    self.contentBgView.layer.borderColor = [UIColor mainColor].CGColor;
}


- (IBAction)imageCutBtnAction:(id)sender {
    
    self.imageCount--;
    if (self.imageCount < 0) {
        self.imageCount = 9;
    }
    self.imageCountLabel.text = [NSString stringWithFormat:@"%lu",self.imageCount];
    if (self.imageCountCallback) {
        self.imageCountCallback(self.imageCount);
    }
}

- (IBAction)imagePlusBtnAction:(id)sender {
    
    self.imageCount++;
    if (self.imageCount > 9) {
        self.imageCount = 0;
    }
    self.imageCountLabel.text = [NSString stringWithFormat:@"%lu",self.imageCount];
    if (self.imageCountCallback) {
        self.imageCountCallback(self.imageCount);
    }
}
- (IBAction)videoCutBtnAction:(id)sender {
    
    self.videoCount--;
    if (self.videoCount < 0) {
        self.videoCount = 9;
    }
    self.videoCountLabel.text =[NSString stringWithFormat:@"%lu",self.videoCount];
    if (self.videoCountCallback) {
        self.videoCountCallback(self.videoCount);
    }
}

- (IBAction)videoPlusBtnAction:(id)sender {
    
    self.videoCount++;
    if (self.videoCount > 9) {
        self.videoCount = 0;
    }
    self.videoCountLabel.text = [NSString stringWithFormat:@"%lu",self.videoCount];
    if (self.videoCountCallback) {
        self.videoCountCallback(self.videoCount);
    }
}


- (void)setupImageCount:(NSInteger)imageCount{
    
    self.imageCount = imageCount;
    self.imageCountLabel.text = [NSString stringWithFormat:@"%lu",self.imageCount];
}

- (void)setupVideoCount:(NSInteger)videoCount{
    
    self.videoCount = videoCount;
    self.videoCountLabel.text = [NSString stringWithFormat:@"%lu",self.videoCount];
}

@end
