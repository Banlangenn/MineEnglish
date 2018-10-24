//
//  StudentSelectorTableViewCell.m
//  X5Teacher
//
//  Created by yebw on 2017/12/27.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "StudentSelectorTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

NSString * const StudentSelectorTableViewCellId = @"StudentSelectorTableViewCellId";
CGFloat const StudentSelectorTableViewCellHeight = 50.f;

@interface StudentSelectorTableViewCell()

@property (nonatomic, weak) IBOutlet UIImageView *choiceStateImageView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *choiceStateImageViewWidthConstraint;
@property (nonatomic, weak) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@end

@implementation StudentSelectorTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.avatarImageView.layer.cornerRadius = 18.f;
    self.avatarImageView.layer.masksToBounds = YES;
}

- (void)setChoice:(BOOL)choice {
    _choice = choice;
    
    if (choice) {
        self.choiceStateImageView.image = [UIImage imageNamed:@"icon_mission_choice"];
    } else {
        self.choiceStateImageView.image = [UIImage imageNamed:@"icon_mission_choice_disabled"];
    }
}

- (void)setReviewMode:(BOOL)reviewMode {
    _reviewMode = reviewMode;
    
    if (reviewMode) {
        self.choiceStateImageViewWidthConstraint.constant = 15.f;
    } else {
        self.choiceStateImageViewWidthConstraint.constant = 48.f;
    }
    
    self.choiceStateImageView.hidden = reviewMode;
}

- (void)setupWithStudent:(User *)student {
    [self.avatarImageView sd_setImageWithURL:[student.avatarUrl imageURLWithWidth:36.f]];
    self.nameLabel.text = student.nickname;
}

@end

