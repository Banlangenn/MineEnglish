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

@property (nonatomic, strong) UIColor *selColor;

- (void)setupWithTag:(NSString *)tag;

+ (CGSize)cellSizeWithTag:(NSString *)tag;

@end
