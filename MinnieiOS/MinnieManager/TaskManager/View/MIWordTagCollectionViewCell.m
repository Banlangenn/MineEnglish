//
//  MIWordTagCollectionViewCell.m
//  MinnieManager
//
//  Created by songzhen on 2019/6/6.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "WordInfo.h"
#import "MIWordTagCollectionViewCell.h"

NSString * const MIWordTagCollectionViewCellId = @"MIWordTagCollectionViewCellId";

@interface MIWordTagCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@property (weak, nonatomic) IBOutlet UIImageView *cancelImageV;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftImgContraint;
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UILabel *chineseLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *specLineView;

@end

@implementation MIWordTagCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    //ios 12 上特有的Bug
    if (@available(iOS 12.0, *)) {
        // Addresses a separate issue and prevent auto layout warnings due to the temporary width constraint in the xib.
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Code below is needed to make the self-sizing cell work when building for iOS 12 from Xcode 10.0:
        
        NSLayoutConstraint *leftConstraint = [self.contentView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:0];
        NSLayoutConstraint *rightConstraint = [self.contentView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:0];
        NSLayoutConstraint *topConstraint = [self.contentView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0];
        NSLayoutConstraint *bottomConstraint = [self.contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0];
        
        [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, bottomConstraint]];
    }
    
    self.bgView.layer.cornerRadius = 12.f;
    self.bgView.layer.masksToBounds = YES;
    self.bgView.layer.borderWidth = 1.0;
    self.bgView.layer.borderColor = [UIColor colorWithHex:0xDDDDDD].CGColor;
}

- (void)setupWithTag:(id)tag {
    
    if ([tag isKindOfClass:[NSString class]]) {
        
        self.textLabel.text = tag;
        self.chineseLabel.hidden = YES;
        self.bottomConstraint.constant = 5;
        self.specLineView.hidden = YES;
    } else if ([tag isKindOfClass:[WordInfo class]]) {
        WordInfo *info = tag;
        self.textLabel.text = info.english;
        self.chineseLabel.text = info.chinese;
        self.chineseLabel.hidden = NO;
        self.specLineView.hidden = NO;
        if ([info.chinese isEqualToString:@"添加单词"] && [info.english isEqualToString:@"+"]) {
            self.specLineView.hidden = YES;
        } else if ([info.chinese isEqualToString:@"从文件导入"] && [info.english isEqualToString:@"+"]) {
            self.specLineView.hidden = YES;
        }
        self.bottomConstraint.constant = 32;
    }
}
- (void)setupWithText:(id)text isEditState:(BOOL)isEditState isLast:(BOOL)isLast{
    
    [self setupWithTag:text];
    self.textLabel.textColor = [UIColor detailColor];
    self.chineseLabel.textColor = [UIColor detailColor];
    if (isEditState) {
        self.cancelImageV.hidden = NO;
    } else {
        self.cancelImageV.hidden = YES;
    }
    if (isLast) {
        self.textLabel.textColor = [UIColor mainColor];
        self.chineseLabel.textColor = [UIColor mainColor];
        self.cancelImageV.hidden = YES;
    }
    CGSize sizeItem = [MIWordTagCollectionViewCell cellSizeWithTag:text];
    self.leftImgContraint.constant = sizeItem.width - 17;
}

+ (CGSize)cellSizeWithTag:(id)tag {
  
    static MIWordTagCollectionViewCell *tempCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tempCell = [[[NSBundle mainBundle] loadNibNamed:@"MIWordTagCollectionViewCell" owner:nil options:nil] lastObject];
    });
    [tempCell setupWithTag:tag];

    CGSize itemSize = [tempCell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
//    itemSize.width = itemSize.width + 10;
    return itemSize;
}


@end
