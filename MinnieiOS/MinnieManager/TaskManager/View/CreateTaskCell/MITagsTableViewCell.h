//
//  MITagsTableViewCell.h
//  MinnieManager
//
//  Created by songzhen on 2019/6/5.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HomeworkTagsTableViewCell.h"

typedef void(^MITagsTableViewCellManageCallback)(void);
typedef void(^MITagsTableViewCellSelectCallback)(NSString *_Nullable);

extern NSString * _Nullable const MITagsTableViewCellId;


NS_ASSUME_NONNULL_BEGIN

@interface MITagsTableViewCell : UITableViewCell

@property (nonatomic, copy) MITagsTableViewCellSelectCallback selectCallback;
@property (nonatomic, copy) MITagsTableViewCellManageCallback manageCallback;

@property (nonatomic, assign) HomeworkTagsTableViewCellSelectType type; //选择状态
@property (weak, nonatomic) IBOutlet UIButton *managerBtn;
@property (weak, nonatomic) IBOutlet UIImageView *righLabel;

@property (nonatomic, strong) UIColor *selColor;

- (void)setupWithTags:(NSArray <NSString *> *)tags
         selectedTags:(NSArray <NSString *> *)selectedTags
            typeTitle:(NSString *)title
      collectionWidth:(CGFloat)collectionWidth;

+ (CGFloat)heightWithTags:(NSArray <NSString *> *)tags collectionWidth:(CGFloat)collectionWidth;

@end


NS_ASSUME_NONNULL_END
