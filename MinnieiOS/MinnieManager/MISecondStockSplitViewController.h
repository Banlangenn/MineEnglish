//
//  MISecondStockSplitViewController.h
//  MinnieManager
//
//  Created by songzhen on 2019/7/19.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "MITaskListViewController.h"
#import "CSCustomSplitViewController.h"
#import "MIActivityRankListViewController.h"

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger,MIRootModularType) {
  
    MIRootModularType_RealTimeTask,             // 实时任务
    MIRootModularType_TeacherManager,           // 教师管理
    MIRootModularType_TaskManager,              // 任务管理
    MIRootModularType_ActivityManager,          // 活动管理
    MIRootModularType_TeachingStatistic,        // 学员管理
    MIRootModularType_CampusManager,            // 校区管理
    MIRootModularType_GiftManager,              // 礼物管理
    MIRootModularType_ImagesManager,            // 首页管理
    MIRootModularType_SetterManager             // 设置
};

@interface MISecondStockSplitViewController : CSCustomSplitViewController

@property (nonatomic,assign) MIRootModularType rootModularType;

// 任务管理，添加文件callback
@property (nonatomic, copy) void(^addFolderCallBack) (NSInteger folderIndex);

// 活动管理 创建活动callback
@property (nonatomic,copy) ActivityRankListCallback createCallback;

// 教师管理 编辑callback
@property (nonatomic, copy) void(^editTeacherCallBack)(BOOL isDelete);

/*
 *  实时任务
 */
- (void)updateHomeworkSessionWithTeacher:(Teacher *_Nullable)teacher;


/*
 *  教师管理
 */
- (void)updateTeacher:(Teacher * _Nullable)teacher;


/*
 *  任务管理
 */

// 点击二级文件夹更新任务列表  fileInfo:当前选中二级文件夹， folderIndex:当前选中文件夹索引 -1未选中
//- (void)showTaskListWithFoldInfo:(FileInfo * _Nullable)fileInfo folderIndex:(NSInteger)folder;
- (void)updateTaskListBySubFileInfo:(FileInfo * _Nullable)fileInfo folderIndex:(NSInteger)folder;

// 点击一级文件夹更新任务列表
- (void)updateTaskListByParentFileWithParentId:(NSInteger)parentId folderIndex:(NSInteger)folder;

// yes 添加文件夹 no 添加文件
- (void)showEmptyViewWithIsFolder:(BOOL)isAddFolder folderIndex:(NSInteger)folder;

- (void)searchHomework;

/*
 *  活动管理
 */
- (void)updateRankListWithActivityModel:(ActivityInfo *_Nullable)model index:(NSInteger)currentIndex;

- (void)createActivity;


/*
*  学员管理
*/
- (void)updateStudent:(Student * _Nullable)student;

- (void)hiddenZeroMessages;


/*
 *  班级管理
 */
- (void)updateCampusInfo;

/*
 *  首页管理
 */
- (void)updateImages;

/*
 *  礼物管理
 */
- (void)updateAwards;

- (void)updateExchangeAwardsList;


/*
 *  设置
 */


- (void)updatePrimaryCloumnScale:(NSInteger)offset;

@end

NS_ASSUME_NONNULL_END
