//
//  StudentSelectorTableViewCell.h
//  X5Teacher
//
//  Created by yebw on 2017/12/27.
//  Copyright © 2017年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

extern NSString * const StudentSelectorTableViewCellId;
extern CGFloat const StudentSelectorTableViewCellHeight;

@interface StudentSelectorTableViewCell : UITableViewCell

@property (nonatomic, assign) BOOL choice;
@property (nonatomic, assign) BOOL reviewMode;
@property (nonatomic, copy) NSString *className;

- (void)setupWithStudent:(User *)student;


@end

