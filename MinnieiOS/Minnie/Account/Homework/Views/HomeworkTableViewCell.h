//
//  HomeworkTableViewCell.h
//  X5Teacher
//
//  Created by yebw on 2018/2/3.
//  Copyright © 2018年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Homework.h"

extern NSString * const HomeworkTableViewCellId;

typedef void(^HomeworkTableViewCellSendCallback)(void);
typedef void(^HomeworkTableViewCellSelectCallback)(void);

typedef void(^HomeworkTableViewCellClickImageCallback)(UIImageView *, NSString *);
typedef void(^HomeworkTableViewCellClickVideoCallback)(NSString *);

@interface HomeworkTableViewCell : UITableViewCell

@property (nonatomic, copy) HomeworkTableViewCellSelectCallback sendCallback;
@property (nonatomic, copy) HomeworkTableViewCellSelectCallback selectCallback;

@property (nonatomic, copy) HomeworkTableViewCellClickImageCallback imageCallback;
@property (nonatomic, copy) HomeworkTableViewCellClickVideoCallback videoCallback;

- (void)setupWithHomework:(Homework *)homework;
- (void)updateWithEditMode:(BOOL)editMode selected:(BOOL)selected;

+ (CGFloat)cellHeightWithHomework:(Homework *)homework;

@end
