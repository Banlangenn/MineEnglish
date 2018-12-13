//
//  HomeworkTagsTableViewCell.h
//  X5Teacher
//
//  Created by yebw on 2018/1/24.
//  Copyright © 2018年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^HomeworkTagsTableViewCellSelectCallback)(NSString *);
typedef void(^HomeworkTagsTableViewCellManageCallback)(void);

extern NSString * const HomeworkTagsTableViewCellId;

@interface HomeworkTagsTableViewCell : UITableViewCell

@property (nonatomic, copy) HomeworkTagsTableViewCellSelectCallback selectCallback;
@property (nonatomic, copy) HomeworkTagsTableViewCellManageCallback manageCallback;

@property (nonatomic, assign) BOOL bSingleSelect;

- (void)setupWithTags:(NSArray <NSString *> *)tags
         selectedTags:(NSArray <NSString *> *)selectedTags
            typeTitle:(NSString *)title;

+ (CGFloat)heightWithTags:(NSArray <NSString *> *)tags typeTitle:(NSString *)title;

@end
