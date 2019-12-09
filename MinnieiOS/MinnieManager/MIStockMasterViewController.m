//
//  CSStockMasterTableViewController.m
//  CSCustomSplitViewController_Demo
//
//  Created by Huang Chusheng on 16/11/22.
//  Copyright © 2016年 Aaron. All rights reserved.
//

#import "ManagerServce.h"
#import "MIRootSheetView.h"
#import "MISecondTeachersView.h"
#import "MISecondSheetView.h"
#import "SettingsViewController.h"
#import "MISecondActivitySheetView.h"
#import "MISecondTeachStatisticsView.h"
#import "MIStockDetailViewController.h"
#import "MIStockMasterViewController.h"
#import "MISecondStockSplitViewController.h"
#import "HomeWorkSendHistoryViewController.h"

@interface MIStockMasterViewController ()<
RootSheetViewDelete,
SecondSheetViewDelegate,
MISecondTeachersViewDelegate,
MISecondActivitySheetViewDelegate,
MISecondTeachStatisticsViewDelegate
>
// 根菜单视图
@property (nonatomic, strong)MIRootSheetView *firstSheetView;

// 实时任务 教师列表
@property (nonatomic, strong) MISecondTeachersView *reaTimTasSheetView;
// 教师管理 教师列表
@property (nonatomic, strong) MISecondTeachersView *teacherManagerSheetView;
// 任务管理 文件夹列表
@property (nonatomic, strong) MISecondSheetView *secondSheetView;
// 活动管理 活动列表
@property (nonatomic, strong) MISecondActivitySheetView *secondActivitySheetView;
// 学员管理 学生列表
@property (nonatomic, strong) MISecondTeachStatisticsView *secondTeaStaSheetView;

// 实时任务
@property (nonatomic, strong) MISecondStockSplitViewController *reaTimTasStockSplitVC;
// 教师管理
@property (nonatomic, strong) MISecondStockSplitViewController *teacherStockSplitVC;
// 任务管理
@property (nonatomic, strong) MISecondStockSplitViewController *taskManagerStockSplitVC;
// 活动管理
@property (nonatomic, strong) MISecondStockSplitViewController *activityStockSplitVC;
// 学员管理
@property (nonatomic, strong) MISecondStockSplitViewController *teaStaStockSplitVC;
// 校区管理
@property (nonatomic, strong) MISecondStockSplitViewController *camManStockSplitVC;
// 礼物管理
@property (nonatomic, strong) MISecondStockSplitViewController *giftStockSplitVC;
// 首页管理
@property (nonatomic, strong) MISecondStockSplitViewController *imagesStockSplitVC;
// 设置
@property (nonatomic, strong) MISecondStockSplitViewController *setterStockSplitVC;

@end

@implementation MIStockMasterViewController


- (void)viewDidLoad {
  
    [super viewDidLoad];
   
    [self.view addSubview:self.firstSheetView];
    [self.view addSubview:self.reaTimTasSheetView];
    
    // 默认选中 实时任务
    self.firstSheetView.selectType = MIManagerFuncRealTaskModule;
}

#pragma mark - RootSheetViewDelete
- (void)rootSheetViewClickedType:(MIManagerFuncModule)type{
    
    UINavigationController *nav = ((UINavigationController *)self.customSplitViewController.viewControllers[1]);
    [nav popToRootViewControllerAnimated:YES];
 
    // 活动
    [_secondActivitySheetView resetCurrentIndex];
    [self.teaStaStockSplitVC hiddenZeroMessages];
    
    NSInteger cloumnScale = 0;
    if (type == MIManagerFuncRealTaskModule) { // 实时任务
        
        [self.view addSubview:self.reaTimTasSheetView];
        _secondSheetView.hidden = YES;
        _secondActivitySheetView.hidden = YES;
        _teacherManagerSheetView.hidden = YES;
        _secondTeaStaSheetView.hidden = YES;
        
        self.reaTimTasSheetView.hidden = NO;
        cloumnScale = kRootModularWidth + kColumnSecondWidth;
        [self.secondDetailVC addSubViewController:self.reaTimTasStockSplitVC];
        
        [self.reaTimTasSheetView updateTeacherListWithListType:0 resetIndex:YES];
        [self.reaTimTasStockSplitVC updateHomeworkSessionWithTeacher:nil];
        
    } else if (type == MIManagerFuncTeacherModule){ // 教师管理
        
        [self.view addSubview:self.teacherManagerSheetView];
        _secondSheetView.hidden = YES;
        _reaTimTasSheetView.hidden = YES;
        _secondActivitySheetView.hidden = YES;
        _secondTeaStaSheetView.hidden = YES;
        
        self.teacherManagerSheetView.hidden = NO;
        cloumnScale = kRootModularWidth + kColumnSecondWidth;
        [self.secondDetailVC addSubViewController:self.teacherStockSplitVC];
        
        [self.teacherManagerSheetView updateTeacherListWithListType:1 resetIndex:YES];
        [self.teacherStockSplitVC updateTeacher:nil];
        
    } else if (type == MIManagerFuncTaskModule){ // 任务管理 不展开文件夹，不显示内容
       
        [self.view addSubview:self.secondSheetView];
        _reaTimTasSheetView.hidden = YES;
        _secondActivitySheetView.hidden = YES;
        _teacherManagerSheetView.hidden = YES;
        _secondTeaStaSheetView.hidden = YES;
        
        self.secondSheetView.hidden = NO;
        cloumnScale = kRootModularWidth + kColumnSecondWidth;
        [self.secondDetailVC addSubViewController:self.taskManagerStockSplitVC];
        
        [self.taskManagerStockSplitVC updateTaskListBySubFileInfo:nil folderIndex:-1];
        [_secondSheetView collapseAllFolders];
        [_secondSheetView updateFileListInfo];
        
    } else if (type == MIManagerFuncActivityModule) { // 活动管理
        
        [self.view addSubview:self.secondActivitySheetView];
        _secondSheetView.hidden = YES;
        _reaTimTasSheetView.hidden = YES;
        _teacherManagerSheetView.hidden = YES;
        _secondTeaStaSheetView.hidden = YES;
        
        self.secondActivitySheetView.hidden = NO;
        cloumnScale = kRootModularWidth + kColumnSecondWidth;
        [self.secondDetailVC addSubViewController:self.activityStockSplitVC];
        
        [_secondActivitySheetView updateActivityListInfo];
    } else if (type == MIManagerFuncTeachingModule) { // 学员管理
        
        [self.view addSubview:self.secondTeaStaSheetView];
        _secondSheetView.hidden = YES;
        _reaTimTasSheetView.hidden = YES;
        _secondActivitySheetView.hidden = YES;
        _teacherManagerSheetView.hidden = YES;
        
        self.secondTeaStaSheetView.hidden = NO;
        cloumnScale = kRootModularWidth + kColumnSecondWidth;
        [self.secondDetailVC addSubViewController:self.teaStaStockSplitVC];
        
        [self.secondTeaStaSheetView updateStudentList];
        [self.teaStaStockSplitVC updateStudent:nil];
    } else if (type == MIManagerFuncCampusModule) { // 班级管理
        cloumnScale = kRootModularWidth;
        [self.secondDetailVC addSubViewController:self.camManStockSplitVC];
    } else if (type == MIManagerFuncGiftsModule) { // 礼物管理
        cloumnScale = kRootModularWidth;
        [self.secondDetailVC addSubViewController:self.giftStockSplitVC];
    } else if (type == MIManagerFuncImagesModule) { // 图片管理
        
        cloumnScale = kRootModularWidth;
        [self.secondDetailVC addSubViewController:self.imagesStockSplitVC];
        
        [self.imagesStockSplitVC updateImages];
    } else if (type == MIManagerFuncSettingModule) { // 设置
        cloumnScale = kRootModularWidth;
        [self.secondDetailVC addSubViewController:self.setterStockSplitVC];
    }
    if (self.cloumnSacleCallBack) {
        self.cloumnSacleCallBack(cloumnScale);
    }
}

#pragma mark - 实时任务 && 教师管理
- (void)secondTeaManViewDidClicledWithTeacher:(Teacher *)teacher listType:(NSInteger)type{
    
    if (type == 0) {// 实时任务
        [self.reaTimTasStockSplitVC updateHomeworkSessionWithTeacher:teacher];
    } else {
        [self.teacherStockSplitVC updateTeacher:teacher];
    }
}

#pragma mark - 学员管理 MISecondTeachStatisticsViewDelegate
-(void)secondTeachStatisticsViewDidClicledWithStudent:(Student *)student{
    
    [self.teaStaStockSplitVC updateStudent:student];
}

#pragma mark - 发送记录
- (void)toSendRecord{
    
    UINavigationController *nav = ((UINavigationController *)self.customSplitViewController.viewControllers[1]);
    if ([nav.viewControllers.lastObject isKindOfClass:[HomeWorkSendHistoryViewController class]]) {
        return;
    }
    [nav popToRootViewControllerAnimated:YES];
    
    [_secondSheetView collapseAllFolders];
    [self.taskManagerStockSplitVC updateTaskListBySubFileInfo:nil folderIndex:-1];
    
    self.customSplitViewController.primaryCloumnScale = kRootModularWidth + kColumnSecondWidth;
    [self.customSplitViewController setDisplayMode:CSSplitDisplayModeDisplayPrimaryAndSecondary withAnimated:YES];
   
    HomeWorkSendHistoryViewController * historyHomeworkVC = [[HomeWorkSendHistoryViewController alloc] initWithNibName:@"HomeWorkSendHistoryViewController" bundle:nil];
    [self.secondDetailVC.navigationController pushViewController:historyHomeworkVC animated:YES];
}
#pragma mark - 搜索作业
- (void)toSearchHomework{
    
    [self.taskManagerStockSplitVC searchHomework];
}


#pragma mark - 任务管理 一级文件夹 && 二级文件夹
#pragma mark - SecondSheetViewDelegate
- (void)secondSheetViewFirstLevelData:(ParentFileInfo *_Nullable)data
                                index:(NSInteger)index
                             selected:(BOOL)selected{

    [self popToRootDetailViewController];
    [self.secondDetailVC addSubViewController:self.taskManagerStockSplitVC];
    if (data.subFileList.count) { // 显示空内容
//        [self.taskManagerStockSplitVC showTaskListWithFoldInfo:nil folderIndex:index];
        if (selected) {
            [self.taskManagerStockSplitVC updateTaskListByParentFileWithParentId:data.fileInfo.fileId folderIndex:index];
        } else {
            [self.taskManagerStockSplitVC updateTaskListByParentFileWithParentId:0 folderIndex:index];
        }
    } else {// 显示创建文件夹
        [self.taskManagerStockSplitVC showEmptyViewWithIsFolder:YES folderIndex:index];
    }
}

- (void)secondSheetViewSecondLevelData:(FileInfo *_Nullable)data index:(NSInteger)index{
    
    [self popToRootDetailViewController];
    [self.secondDetailVC addSubViewController:self.taskManagerStockSplitVC];
    [self.taskManagerStockSplitVC updateTaskListBySubFileInfo:data folderIndex:index];
}

- (void)secondSheetViewDeleteFile{

    [self.taskManagerStockSplitVC updateTaskListBySubFileInfo:nil folderIndex:-1];
}

#pragma mark - 活动管理
#pragma mark - MISecondActivitySheetViewDelegate
- (void)secondActivitySheetViewCreateActivity{
    
    [self popToRootDetailViewController];
    [self.secondDetailVC addSubViewController:self.activityStockSplitVC];
    [self.activityStockSplitVC createActivity];
}

- (void)secondActivitySheetViewDidClickedActivity:(ActivityInfo *_Nullable)data index:(NSInteger)index{
    
    [self popToRootDetailViewController];
    [self.secondDetailVC addSubViewController:self.activityStockSplitVC];
    [self.activityStockSplitVC updateRankListWithActivityModel:data index:index];
}

- (void)popToRootDetailViewController{
    
    UINavigationController *nav = ((UINavigationController *)self.customSplitViewController.viewControllers[1]);
    [nav popToRootViewControllerAnimated:YES];
}

#pragma mark - setter && getter
- (MISecondStockSplitViewController *)reaTimTasStockSplitVC{
    
    if (!_reaTimTasStockSplitVC) {
        _reaTimTasStockSplitVC = [[MISecondStockSplitViewController alloc] init];
    }
    _reaTimTasStockSplitVC.rootModularType = MIRootModularType_RealTimeTask;
    [_reaTimTasStockSplitVC updatePrimaryCloumnScale:kColumnThreeWidth];
    return _reaTimTasStockSplitVC;
}

- (MISecondStockSplitViewController *)teacherStockSplitVC{
    if (!_teacherStockSplitVC) {
        _teacherStockSplitVC = [[MISecondStockSplitViewController alloc] init];
        WeakifySelf;
        _teacherStockSplitVC.editTeacherCallBack = ^(BOOL isDelete) {
          
            if (isDelete) {
                [weakSelf.teacherStockSplitVC updateTeacher:nil];
                [weakSelf.teacherManagerSheetView updateTeacherListWithListType:1 resetIndex:YES];
            } else {
                [weakSelf.teacherManagerSheetView updateTeacherListWithListType:1 resetIndex:NO];
            }
        };
    }
    _teacherStockSplitVC.rootModularType = MIRootModularType_TeacherManager;
    [_teacherStockSplitVC updatePrimaryCloumnScale:kColumnThreeWidth];
    return _teacherStockSplitVC;
}

- (MISecondStockSplitViewController *)taskManagerStockSplitVC{
   
    if (!_taskManagerStockSplitVC) {
        WeakifySelf;
        _taskManagerStockSplitVC = [[MISecondStockSplitViewController alloc] init];
        _taskManagerStockSplitVC.addFolderCallBack = ^(NSInteger folderIndex) {
            [weakSelf.secondSheetView addSecondLevelFolderIndex:folderIndex];
        };
    }
    _taskManagerStockSplitVC.rootModularType = MIRootModularType_TaskManager;
    [_taskManagerStockSplitVC updatePrimaryCloumnScale:kColumnThreeWidth];
    return _taskManagerStockSplitVC;
}

- (MISecondStockSplitViewController *)activityStockSplitVC{
    
    if (!_activityStockSplitVC) {
        WeakifySelf;
        _activityStockSplitVC = [[MISecondStockSplitViewController alloc] init];
        _activityStockSplitVC.createCallback = ^(NSInteger activityIndex) {
          
            [weakSelf.secondActivitySheetView activitySheetDidEditIndex:activityIndex];
        };
    }
    _activityStockSplitVC.rootModularType = MIRootModularType_ActivityManager;
    [_activityStockSplitVC updatePrimaryCloumnScale:kColumnThreeWidth];
    return _activityStockSplitVC;
}

- (MISecondStockSplitViewController *)teaStaStockSplitVC{
    
    if (!_teaStaStockSplitVC) {
        _teaStaStockSplitVC = [[MISecondStockSplitViewController alloc] init];
    }
    [_teaStaStockSplitVC updatePrimaryCloumnScale:kColumnThreeWidth];
    _teaStaStockSplitVC.rootModularType = MIRootModularType_TeachingStatistic;
    return _teaStaStockSplitVC;
}

- (MISecondStockSplitViewController *)camManStockSplitVC{
    if (!_camManStockSplitVC) {
        _camManStockSplitVC = [[MISecondStockSplitViewController alloc] init];
    }
    _camManStockSplitVC.rootModularType = MIRootModularType_CampusManager;
    CGFloat columnThreeWidth = (ScreenWidth - kRootModularWidth)/2.0;
    [_camManStockSplitVC updatePrimaryCloumnScale:columnThreeWidth];
    return _camManStockSplitVC;
}


- (MISecondStockSplitViewController *)imagesStockSplitVC{
    
    if (!_imagesStockSplitVC) {
        _imagesStockSplitVC = [[MISecondStockSplitViewController alloc] init];
    }
    _imagesStockSplitVC.rootModularType = MIRootModularType_ImagesManager;
    CGFloat columnThreeWidth = (ScreenWidth - kRootModularWidth)/2.0;
    [_imagesStockSplitVC updatePrimaryCloumnScale:columnThreeWidth];
    return _imagesStockSplitVC;
}

- (MISecondStockSplitViewController *)giftStockSplitVC{
    
    if (!_giftStockSplitVC) {
        _giftStockSplitVC = [[MISecondStockSplitViewController alloc] init];
    }
    _giftStockSplitVC.rootModularType = MIRootModularType_GiftManager;
    CGFloat columnThreeWidth = (ScreenWidth - kRootModularWidth)/2.0 + 80;
    [_giftStockSplitVC updatePrimaryCloumnScale:columnThreeWidth];
    return _giftStockSplitVC;
}

- (MISecondStockSplitViewController *)setterStockSplitVC{
    
    if (!_setterStockSplitVC) {
        _setterStockSplitVC = [[MISecondStockSplitViewController alloc] init];
    }
    _setterStockSplitVC.rootModularType = MIRootModularType_SetterManager;
    CGFloat columnThreeWidth = (ScreenWidth - kRootModularWidth)/2.0;
    [_setterStockSplitVC updatePrimaryCloumnScale:columnThreeWidth];
    return _setterStockSplitVC;
}

- (MIRootSheetView *)firstSheetView{
    
    if (!_firstSheetView) {
        
        _firstSheetView = [[MIRootSheetView alloc] initWithFrame:CGRectMake(0, 0, kRootModularWidth, ScreenHeight)];
        _firstSheetView.delegate = self;
    }
    return _firstSheetView;
}

- (MISecondTeachersView *)reaTimTasSheetView{
    if (!_reaTimTasSheetView) {
        
        _reaTimTasSheetView = [[MISecondTeachersView alloc] initWithFrame:CGRectMake(kRootModularWidth, 0, kColumnSecondWidth, ScreenHeight)];
        _reaTimTasSheetView.delegate = self;
    }
    return _reaTimTasSheetView;
}
- (MISecondTeachersView *)teacherManagerSheetView{
    
    if (!_teacherManagerSheetView) {
        
        _teacherManagerSheetView = [[MISecondTeachersView alloc] initWithFrame:CGRectMake(kRootModularWidth, 0, kColumnSecondWidth, ScreenHeight)];
        _teacherManagerSheetView.delegate = self;
    }
    return _teacherManagerSheetView;
}

- (MISecondSheetView *)secondSheetView{
    
    if (!_secondSheetView) {
        
        _secondSheetView = [[MISecondSheetView alloc] initWithFrame:CGRectMake(kRootModularWidth, 0, kColumnSecondWidth, ScreenHeight)];
        _secondSheetView.delegate = self;
    }
    return _secondSheetView;
}

- (MISecondActivitySheetView *)secondActivitySheetView{
    if (!_secondActivitySheetView) {
        
        _secondActivitySheetView = [[MISecondActivitySheetView alloc] initWithFrame:CGRectMake(kRootModularWidth, 0, kColumnSecondWidth, ScreenHeight)];
        _secondActivitySheetView.delegate = self;
    }
    return _secondActivitySheetView;
}

- (MISecondTeachStatisticsView *)secondTeaStaSheetView{
    if (!_secondTeaStaSheetView) {
        
        _secondTeaStaSheetView = [[MISecondTeachStatisticsView alloc] initWithFrame:CGRectMake(kRootModularWidth, 0, kColumnSecondWidth, self.view.frame.size.height)];
        _secondTeaStaSheetView.delegate = self;
    }
    return _secondTeaStaSheetView;
}

@end
