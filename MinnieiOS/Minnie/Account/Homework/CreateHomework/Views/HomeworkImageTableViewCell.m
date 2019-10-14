//
//  HomeworkImageTableViewCell.m
//  X5Teacher
//
//  Created by yebw on 2018/1/24.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "HomeworkImageTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

NSString * const HomeworkImageTableViewCellId = @"HomeworkImageTableViewCellId";
CGFloat const HomeworkImageTableViewCellHeight = 112.f;

@interface HomeworkImageTableViewCell()

@property (nonatomic, weak) IBOutlet UIImageView *coverImageView;
@property (nonatomic, copy) NSString *imageUrl;

@end

@implementation HomeworkImageTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.coverImageView.layer.cornerRadius = 12;
    self.coverImageView.layer.masksToBounds = YES;
}

- (void)setupWithImageUrl:(NSString *)imageUrl {
    self.imageUrl = imageUrl;

    [self.coverImageView sd_setImageWithURL:[imageUrl imageURLWithWidth:182.f]];
}

- (IBAction)deleteButtonPressed:(id)sender {
    if (self.deleteCallback != nil) {
        self.deleteCallback(YES);
    }
}

- (IBAction)addButtonPressed:(id)sender {
    if (self.deleteCallback != nil) {
        self.deleteCallback(NO);
    }
}

- (IBAction)imageButtonPressed:(id)sender {
    
    if (self.imageCalback) {
        self.imageCalback(self.imageUrl);
    }
}


@end


