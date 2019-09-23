//
//  MITaskSheetTableViewCell.h
//  MinnieManager
//
//  Created by songzhen on 2019/9/23.
//  Copyright © 2019 minnieedu. All rights reserved.
//  添加任务清单

#import <UIKit/UIKit.h>

extern NSString * _Nullable const MITaskSheetTableViewCellId;

extern CGFloat const MITaskSheetTableViewHeight;

NS_ASSUME_NONNULL_BEGIN

@interface MITaskSheetTableViewCell : UITableViewCell

@property (nonatomic,copy) void (^imageCountCallback) (NSInteger count);

@property (nonatomic,copy) void (^videoCountCallback) (NSInteger count);

- (void)setupImageCount:(NSInteger)imageCount;

- (void)setupVideoCount:(NSInteger)videoCount;


@end

NS_ASSUME_NONNULL_END
