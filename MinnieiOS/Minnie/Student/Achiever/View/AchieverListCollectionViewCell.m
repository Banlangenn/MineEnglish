//
//  AchieverListCollectionViewCell.m
//  Minnie
//
//  Created by 栋栋 施 on 2018/11/5.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import "AchieverListCollectionViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
NSString * const AchieverListCollectionViewCellId = @"AchieverListCollectionViewCellId";

@interface AchieverListCollectionViewCell()

@property (weak, nonatomic) IBOutlet UIImageView *medalImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *getLabel;

@end


@implementation AchieverListCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.getLabel.layer.cornerRadius = 10.0;
    self.getLabel.clipsToBounds = YES;
    // Initialization code
}

- (void)setMedalData:(UserMedalDetail *)data forMedalPics:(UserMedalPics *)pics atIndex:(NSInteger)index
{
    self.getLabel.hidden = YES;
    NSArray * titles = [pics.medalDesc componentsSeparatedByString:@";"];
    if (index == 0)
    {
        if (data.firstFlag == 2)
        {
            [self.medalImageView sd_setImageWithURL:[NSURL URLWithString:pics.firstPicB]];
        }
        else
        {
            if (data.firstFlag == 1)
            {
                self.getLabel.hidden = NO;
            }
            [self.medalImageView sd_setImageWithURL:[NSURL URLWithString:pics.firstPicD]];
        }
    }
    else if (index == 1)
    {
        if (data.sencondFlag == 2)
        {
            [self.medalImageView sd_setImageWithURL:[NSURL URLWithString:pics.secondPicB]];
        }
        else
        {
            if (data.sencondFlag == 1)
            {
                self.getLabel.hidden = NO;
            }

            [self.medalImageView sd_setImageWithURL:[NSURL URLWithString:pics.secondPicD]];
        }
    }
    else
    {
        if (data.thirdFlag == 2)
        {
            
            [self.medalImageView sd_setImageWithURL:[NSURL URLWithString:pics.thirdPicB]];
        }
        else
        {
            if (data.thirdFlag == 1)
            {
                self.getLabel.hidden = NO;
            }
            [self.medalImageView sd_setImageWithURL:[NSURL URLWithString:pics.thirdPicD]];
        }
    }
    
    if (titles.count > index)
    {
        self.nameLabel.text = [titles objectAtIndex:index];
    }
}



@end
