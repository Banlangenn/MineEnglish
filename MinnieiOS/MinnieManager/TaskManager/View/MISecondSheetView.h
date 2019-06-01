//
//  SecondSheetView.h
//  Manager
//
//  Created by songzhen on 2019/5/27.
//  Copyright © 2019 songzhen. All rights reserved.
//  任务管理文件夹

#import <UIKit/UIKit.h>
#import "MIFirLevelFolderModel.h"

#define kFolderModularWidth         204.f

@protocol SecondSheetViewDelegate <NSObject>

@optional

// 查看发送记录
- (void)toSendRecord;

// 点击任务管理一级文件夹
- (void)secondSheetViewFirstLevelData:(MIFirLevelFolderModel *_Nullable)data index:(NSInteger)index;

// 点击任务管理二级文件夹
- (void)secondSheetViewSecondLevelData:(MIFirLevelFolderModel *_Nullable)data index:(NSInteger)index;


@end

NS_ASSUME_NONNULL_BEGIN

@interface MISecondSheetView : UIView


@property (nonatomic, weak) id<SecondSheetViewDelegate> delegate;

- (void)updateData:(NSArray *)taskArray;

// 新建二级文件夹
- (void)addSecondLevelFolderIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
