//
//  AchieverListCollectionViewCell.h
//  Minnie
//
//  Created by 栋栋 施 on 2018/11/5.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserMedalDto.h"
extern NSString * const AchieverListCollectionViewCellId;

@interface AchieverListCollectionViewCell : UICollectionViewCell

- (void)setMedalData:(UserMedalDetail *)data forMedalPics:(UserMedalPics *)pics atIndex:(NSInteger)index;

@end
