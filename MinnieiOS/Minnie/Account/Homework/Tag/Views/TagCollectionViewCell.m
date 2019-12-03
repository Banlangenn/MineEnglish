//
//  TagCollectionViewCell.m
//  X5Teacher
//
//  Created by yebw on 2017/12/20.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "TagCollectionViewCell.h"
#import "UIColor+HEX.h"

NSString * const TagCollectionViewCellId = @"TagCollectionViewCellId";

@interface TagCollectionViewCell()

@property (nonatomic, weak) IBOutlet UIImageView *bgImageView;
@property (nonatomic, weak) IBOutlet UILabel *tagLabel;

@end

@implementation TagCollectionViewCell

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
    
    self.bgImageView.layer.cornerRadius = 14.f;
    self.bgImageView.layer.masksToBounds = YES;
    self.bgImageView.layer.borderWidth = 1.0;
    self.bgImageView.layer.borderColor = [UIColor colorWithHex:0xebebeb].CGColor;
}

- (void)setupWithTag:(NSString *)tag {
    self.tagLabel.text = tag;
}

#pragma mark - setter && getter
- (void)setChoice:(BOOL)choice {
    _choice = choice;
    
    if (choice) {
        
        self.tagLabel.textColor = [UIColor whiteColor];
        self.bgImageView.backgroundColor = self.selBgColor;
        self.bgImageView.layer.borderColor = [UIColor clearColor].CGColor;
    } else {
        self.tagLabel.textColor = self.normalTextColor;
        self.bgImageView.backgroundColor = self.normalBgColor;
        self.bgImageView.layer.borderColor = [UIColor colorWithHex:0xebebeb].CGColor;
    }
}

- (void)setSelBgColor:(UIColor *)selBgColor{

    _selBgColor = selBgColor;
    if (!selBgColor) {
        _selBgColor = [UIColor colorWithHex:0x00ce00];
    }
}

- (void)setNormalBgColor:(UIColor *)normalBgColor{

    _normalBgColor = normalBgColor;
    if (!normalBgColor) {
        _normalBgColor = [UIColor whiteColor];
    }
}

- (void)setNormalTextColor:(UIColor *)normalTextColor{

    _normalTextColor = normalTextColor;
    if (!normalTextColor) {
        _normalTextColor = [UIColor colorWithHex:0x666666];
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius{
    _cornerRadius = cornerRadius;
    if (_cornerRadius == 0) {
        _cornerRadius = 14.f;
    }
    self.bgImageView.layer.cornerRadius = _cornerRadius;
}

+ (CGSize)cellSizeWithTag:(NSString *)tag {
    static TagCollectionViewCell *tempCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tempCell = [[[NSBundle mainBundle] loadNibNamed:@"TagCollectionViewCell" owner:nil options:nil] lastObject];
    });
    
    [tempCell setupWithTag:tag];

    return [tempCell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

@end
