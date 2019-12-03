//
//  TagCollectionViewCell.h
//  X5Teacher
//
//  Created by yebw on 2017/12/20.
//  Copyright © 2017年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const TagCollectionViewCellId;

@interface TagCollectionViewCell : UICollectionViewCell

@property (nonatomic, assign) BOOL choice;

// 选中背景颜色
@property (nonatomic, strong) UIColor *selBgColor;
// 正常背景颜色
@property (nonatomic, strong) UIColor *normalBgColor;
// 正常文本颜色
@property (nonatomic, strong) UIColor *normalTextColor;
// 圆角
@property (nonatomic, assign) CGFloat cornerRadius;

- (void)setupWithTag:(NSString *)tag;

+ (CGSize)cellSizeWithTag:(NSString *)tag;

@end
