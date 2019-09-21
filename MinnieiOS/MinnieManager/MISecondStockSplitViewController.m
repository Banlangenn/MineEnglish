//
//  MISecondStockSplitViewController.m
//  MinnieManager
//
//  Created by songzhen on 2019/7/19.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "SettingsViewController.h"
#import "MIStockDetailViewController.h"
#import "MITeacherDetailViewController.h"
#import "MISecondStockSplitViewController.h"
#import "HomeworkSessionsContainerViewController.h"
#import "MIStudentDetailViewController.h"
#import "MIStudentRecordViewController.h"
#import "MIZeroMessagesViewController.h"
#import "ClassManagerViewController.h"
#import "MICampusManagerViewController.h"
#import "TeacherAwardsViewController.h"
#import "ExchangeRequestsViewController.h"
#import "MISelectImageViewController.h"
#import "MILookImagesViewController.h"
#import "SearchHomeworkViewController.h"
#import "CircleHomeworksViewController.h"


@interface MISecondStockSplitViewController ()<
MICampusManagerViewControllerDelegate
>

@property (nonatomic, strong) HomeworkSessionsContainerViewController *reaTimTaskMasterVC;
@property (nonatomic, strong) MIStockDetailViewController *reaTimTaskDetailVC;


@property (nonatomic, strong) MITeacherDetailViewController *teacherManagerMasterVC;
@property (nonatomic, strong) MIStockDetailViewController *teacherManagerDetailVC;

// 任务管理

// 当前展开的文件夹 id
@property (nonatomic, assign) NSInteger fileId;
@property (nonatomic, strong) MITaskListViewController *taskManagerMasterVC;
@property (nonatomic, strong) MIStockDetailViewController *taskManagerDetailVC;


@property (nonatomic, strong) MIActivityRankListViewController *activityMasterVC;
@property (nonatomic, strong) MIStockDetailViewController *activityDetailVC;


@property (nonatomic, strong) MIZeroMessagesViewController * zeroMessagesVC;// 零分动态
@property (nonatomic, strong) MIStudentDetailViewController *teachStatistickMasterVC;
@property (nonatomic, strong) MIStudentRecordViewController *teachStatistickDetailVC;


@property (nonatomic, assign) NSInteger classId;
@property (nonatomic, strong) MICampusManagerViewController *campusMasterVC;
@property (nonatomic, strong) MIStockDetailViewController *campusDetailVC;


@property (nonatomic, strong) TeacherAwardsViewController *giftMasterVC;
@property (nonatomic, strong) ExchangeRequestsViewController *giftDetailVC;

@property (nonatomic, strong) MISelectImageViewController *imageMasterVC;
@property (nonatomic, strong) MILookImagesViewController *imageDetailVC;

@property (nonatomic, strong) SettingsViewController *setterMasterVC;
@property (nonatomic, strong) MIStockDetailViewController *setterDetailVC;

@end

@implementation MISecondStockSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor emptyBgColor];
    
    if (self.rootModularType == MIRootModularType_RealTimeTask) {
        
        [self configureReaTimTaskUI];
    } else if (self.rootModularType == MIRootModularType_TeacherManager) {
        
        [self configureTeacherManagerUI];
    } else if (self.rootModularType == MIRootModularType_TaskManager) {
       
        [self configureTaskManagerUI];
    } else if (self.rootModularType == MIRootModularType_ActivityManager) {
        
        [self configureActivityManagerUI];
    } else if (self.rootModularType == MIRootModularType_TeachingStatistic) {
   
        [self configureTeachStatisticUI];
    } else if (self.rootModularType == MIRootModularType_CampusManager) {
      
        [self configureCampusManagerUI];
    } else if (self.rootModularType == MIRootModularType_GiftManager) {
        
        [self configureGiftManagerUI];
    } else if (self.rootModularType == MIRootModularType_ImagesManager) {
        
        [self configureImageManagerUI];
    } else if (self.rootModularType == MIRootModularType_SetterManager) {
     
        [self configureSetterUI];
    }
}

#pragma mark - 实时任务
- (void)configureReaTimTaskUI{
    
    self.reaTimTaskMasterVC = [[HomeworkSessionsContainerViewController alloc] initWithNibName:NSStringFromClass([HomeworkSessionsContainerViewController class]) bundle:nil];
    UINavigationController *masterNav = [[UINavigationController alloc] initWithRootViewController:self.reaTimTaskMasterVC];
    [masterNav setNavigationBarHidden:YES animated:NO];
    
    self.reaTimTaskDetailVC = [[MIStockDetailViewController alloc] init];
    UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:self.reaTimTaskDetailVC];
    [detailNav setNavigationBarHidden:YES animated:NO];
    
    WeakifySelf;
    self.reaTimTaskMasterVC.pushVCCallBack = ^(UIViewController *vc) {
        [weakSelf.reaTimTaskDetailVC.navigationController popToRootViewControllerAnimated:YES];
        [weakSelf.reaTimTaskDetailVC.navigationController pushViewController:vc animated:YES];
    };
    self.reaTimTaskMasterVC.popDetailVCCallBack = ^{
        [weakSelf.reaTimTaskDetailVC.navigationController popToRootViewControllerAnimated:YES];
    };
    
    self.viewControllers = @[masterNav, detailNav];
}

- (void)updateHomeworkSessionWithTeacher:(Teacher *_Nullable)teacher{
    
    if (teacher == nil) {
        
        self.reaTimTaskMasterVC.view.hidden = YES;
    } else {
        
        self.reaTimTaskMasterVC.view.hidden = NO;
        [self.reaTimTaskMasterVC updateHomeworkSessionWithTeacher:teacher];
    }
    [self.reaTimTaskDetailVC.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - 教师管理
- (void)configureTeacherManagerUI{
   
    self.teacherManagerMasterVC = [[MITeacherDetailViewController alloc] init];
    WeakifySelf;
    self.teacherManagerMasterVC.pushCallBack = ^(UIViewController * _Nonnull vc) {
        
        [weakSelf.teacherManagerDetailVC.navigationController popToRootViewControllerAnimated:YES];
        [weakSelf.teacherManagerDetailVC.navigationController pushViewController:vc animated:YES];
    };
    self.teacherManagerMasterVC.editSuccessCallBack = ^(BOOL isDelete) {
        
        if (weakSelf.editTeacherCallBack) {
            weakSelf.editTeacherCallBack(isDelete);
        }
    };
    
    UINavigationController *masterNav = [[UINavigationController alloc] initWithRootViewController:self.teacherManagerMasterVC];
    [masterNav setNavigationBarHidden:YES animated:NO];
    
    self.teacherManagerDetailVC = [[MIStockDetailViewController alloc] init];
    UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:self.teacherManagerDetailVC];
    [detailNav setNavigationBarHidden:YES animated:NO];
    self.viewControllers = @[masterNav, detailNav];
}

- (void)updateTeacher:(Teacher * _Nullable)teacher{
    
    [self.teacherManagerMasterVC updateTeacher:teacher];
    [self.teacherManagerDetailVC.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - 任务管理
- (void)configureTaskManagerUI{
    
    UINavigationController *masterNav = [[UINavigationController alloc] initWithRootViewController:self.taskManagerMasterVC];
    [masterNav setNavigationBarHidden:YES animated:NO];
    
    self.taskManagerDetailVC = [[MIStockDetailViewController alloc] init];
    UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:self.taskManagerDetailVC];
    [detailNav setNavigationBarHidden:YES animated:NO];
    self.viewControllers = @[masterNav, detailNav];
}

- (void)searchHomework{
    
    if (self.taskManagerMasterVC.navigationController.viewControllers.count > 1) {
        return;
    }
    [self.taskManagerMasterVC resetSelectIndex];
    [self.taskManagerDetailVC.navigationController popToRootViewControllerAnimated:YES];
    
    SearchHomeworkViewController *searchHomeworkVC = [[SearchHomeworkViewController alloc] initWithNibName:@"SearchHomeworkViewController" bundle:nil];
    WeakifySelf;
    searchHomeworkVC.pushVCCallBack = ^(UIViewController *VC) {
        [weakSelf.taskManagerDetailVC.navigationController popToRootViewControllerAnimated:NO];
        [weakSelf.taskManagerDetailVC.navigationController pushViewController:VC animated:YES];
    };
    searchHomeworkVC.popDetailCallBack = ^{
        [weakSelf.taskManagerDetailVC.navigationController popToRootViewControllerAnimated:NO];
    };
    searchHomeworkVC.fieldId = self.fileId;
    [self.taskManagerMasterVC.navigationController pushViewController:searchHomeworkVC animated:NO];
}


- (void)updateTaskListBySubFileInfo:(FileInfo * _Nullable)fileInfo folderIndex:(NSInteger)folder{
    
    self.fileId = fileInfo.fileId;
    if (self.taskManagerMasterVC.navigationController.viewControllers.count > 1) {
        [self.taskManagerMasterVC.navigationController popToRootViewControllerAnimated:NO];
    }
    
    [self.taskManagerMasterVC showTaskListWithFoldInfo:fileInfo folderIndex:folder];
    
    if (self.taskManagerDetailVC.navigationController.viewControllers.count > 1) {
        [self.taskManagerDetailVC.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)updateTaskListByParentFileWithParentId:(NSInteger)parentId folderIndex:(NSInteger)folder{
    
    self.fileId = parentId;
    if (self.taskManagerMasterVC.navigationController.viewControllers.count > 1) {
        [self.taskManagerMasterVC.navigationController popToRootViewControllerAnimated:NO];
    }
    
    [self.taskManagerMasterVC showTaskListWithFoldInfo:nil folderIndex:folder];
    
    if (self.taskManagerDetailVC.navigationController.viewControllers.count > 1) {
        [self.taskManagerDetailVC.navigationController popToRootViewControllerAnimated:NO];
    }
}

// yes 添加文件夹 no 添加文件
- (void)showEmptyViewWithIsFolder:(BOOL)isAddFolder folderIndex:(NSInteger)folder{
   
    self.fileId = 0;
    if (self.taskManagerMasterVC.navigationController.viewControllers.count > 1) {
        [self.taskManagerMasterVC.navigationController popToRootViewControllerAnimated:NO];
    }
    
    [self.taskManagerMasterVC showEmptyViewWithIsFolder:isAddFolder folderIndex:folder];
    
    if (self.taskManagerDetailVC.navigationController.viewControllers.count > 1) {
        [self.taskManagerDetailVC.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (MITaskListViewController *)taskManagerMasterVC{
    
    if (!_taskManagerMasterVC) {
        
        _taskManagerMasterVC = [[MITaskListViewController alloc] initWithNibName:NSStringFromClass([MITaskListViewController class]) bundle:nil];
        _taskManagerMasterVC.addFolderCallBack = self.addFolderCallBack;
        
        WeakifySelf;
        _taskManagerMasterVC.createTaskCallBack = ^(UIViewController * _Nullable VC, NSInteger createState) {
            
            if (createState == 0) {
                
                if (VC) {
                    [weakSelf.navigationController pushViewController:VC animated:YES];
                }
            } else if (createState == 1) {
                
                if (weakSelf.taskManagerDetailVC.navigationController.viewControllers.count > 1) {
                    [weakSelf.taskManagerDetailVC.navigationController popToRootViewControllerAnimated:NO];
                }
            }
            [weakSelf.taskManagerDetailVC.navigationController popToRootViewControllerAnimated:NO];
        };
        
        _taskManagerMasterVC.pushVCCallBack = ^(UIViewController *VC) {
            [weakSelf.taskManagerDetailVC.navigationController popToRootViewControllerAnimated:NO];
            [weakSelf.taskManagerDetailVC.navigationController pushViewController:VC animated:YES];
        };
    }
    return _taskManagerMasterVC;
}
#pragma mark - 活动管理
- (void)configureActivityManagerUI{
  
    self.activityMasterVC = [[MIActivityRankListViewController alloc] initWithNibName:NSStringFromClass([MIActivityRankListViewController class]) bundle:nil];
    self.activityMasterVC.callback = self.createCallback;
    WeakifySelf;
    self.activityMasterVC.pushVCCallback = ^(UIViewController * _Nullable VC) {
        [weakSelf.activityDetailVC.navigationController popToRootViewControllerAnimated:NO];
        [weakSelf.activityDetailVC.navigationController pushViewController:VC animated:YES];
    };
    
    UINavigationController *masterNav = [[UINavigationController alloc] initWithRootViewController:self.activityMasterVC];
    self.activityDetailVC = [[MIStockDetailViewController alloc] init];
    [masterNav setNavigationBarHidden:YES animated:NO];
    
    UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:self.activityDetailVC];
    [detailNav setNavigationBarHidden:YES animated:NO];
    
    self.viewControllers = @[masterNav, detailNav];
}

- (void)updateRankListWithActivityModel:(ActivityInfo *_Nullable)model index:(NSInteger)currentIndex{
    
    [self.activityMasterVC updateRankListWithActivityModel:model index:currentIndex];
    if (self.activityDetailVC.navigationController.viewControllers.count > 1) {
        [self.activityDetailVC.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)createActivity{
    
    [self.activityMasterVC createActivity];
}

#pragma mark - 教学统计
- (void)configureTeachStatisticUI{
    
    self.teachStatistickMasterVC = [[MIStudentDetailViewController alloc] initWithNibName:NSStringFromClass([MIStudentDetailViewController class]) bundle:nil];
    UINavigationController *masterNav = [[UINavigationController alloc] initWithRootViewController:self.teachStatistickMasterVC];
    [masterNav setNavigationBarHidden:YES animated:NO];
    
    self.teachStatistickDetailVC = [[MIStudentRecordViewController alloc] init];
    UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:self.teachStatistickDetailVC];
    [detailNav setNavigationBarHidden:YES animated:NO];
    
    self.viewControllers = @[masterNav, detailNav];
}

- (void)updateStudent:(User * _Nullable)student{
    
    if (student != nil) {
        self.teachStatistickMasterVC.view.hidden = NO;
        self.teachStatistickDetailVC.view.hidden = NO;
        [self.teachStatistickDetailVC updateStudentRecordWithStudentId:student.userId];
        [self.teachStatistickMasterVC updateStudent:student];
        [self hiddenZeroMessages];
        if (self.displayMode != CSSplitDisplayModeDisplayPrimaryAndSecondary) {
            [self setDisplayMode:CSSplitDisplayModeDisplayPrimaryAndSecondary withAnimated:NO];
        }
    } else {
        
        self.teachStatistickMasterVC.view.hidden = YES;
        [self.zeroMessagesVC updateZeroMessages];
        [self.teachStatistickMasterVC.navigationController pushViewController:self.zeroMessagesVC animated:NO];
        if (self.displayMode != CSSplitDisplayModeOnlyDisplayPrimary) {
            [self setDisplayMode:CSSplitDisplayModeOnlyDisplayPrimary withAnimated:NO];
        }
    }
}

- (void)hiddenZeroMessages{
    [self.teachStatistickMasterVC.navigationController popToRootViewControllerAnimated:NO];
}

- (MIZeroMessagesViewController *)zeroMessagesVC{
    
    if (!_zeroMessagesVC) {
        _zeroMessagesVC = [[MIZeroMessagesViewController alloc] initWithNibName:NSStringFromClass([MIZeroMessagesViewController class]) bundle:nil];
//        WeakifySelf;
//        _zeroMessagesVC.pushVCCallback = ^(UIViewController *VC) {
//            [weakSelf.teacherManagerDetailVC.navigationController popToRootViewControllerAnimated:NO];
//            [weakSelf.teacherManagerDetailVC.navigationController pushViewController:VC animated:YES];
//        };
    }
    return _zeroMessagesVC;
}

#pragma mark - 班级管理
- (void)configureCampusManagerUI{
 
    self.classId = -1;
    self.campusMasterVC = [[MICampusManagerViewController alloc] init];
    self.campusMasterVC.delegate = self;
    UINavigationController *masterNav = [[UINavigationController alloc] initWithRootViewController:self.campusMasterVC];
    [masterNav setNavigationBarHidden:YES animated:NO];
    
    self.campusDetailVC = [[MIStockDetailViewController alloc] init];
    UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:self.campusDetailVC];
    [detailNav setNavigationBarHidden:YES animated:NO];
    
    self.viewControllers = @[masterNav, detailNav];
}

- (void)updateCampusInfo{
    
    [self.campusMasterVC updateCampusInfo];
}

#pragma mark - MICampusManagerViewControllerDelegate
- (void)campusManagerViewControllerEditClazz:(Clazz *)clazz{
    
    if (clazz.classId == self.classId) {
        return;
    }
    [self.campusDetailVC.navigationController popToRootViewControllerAnimated:NO];
  
    if (clazz.classId == 0) {
        
        ClassManagerViewController *classManagerVC = [[ClassManagerViewController alloc] initWithNibName:@"ClassManagerViewController" bundle:nil];
            WeakifySelf;
        classManagerVC.cancelCallBack = ^{
            weakSelf.classId = -1;
            [weakSelf.campusMasterVC resetSelectIndex];
        };
        classManagerVC.successCallBack = ^{
            weakSelf.classId = -1;
            [weakSelf.campusMasterVC updateClassInfo];
        };
        classManagerVC.editCampusCallBack = ^{
            [weakSelf.campusMasterVC updateCampusInfo];
        };
            self.classId = clazz.classId;
            classManagerVC.classId = clazz.classId;
            [self.campusDetailVC.navigationController pushViewController:classManagerVC animated:YES];
    } else {
     
        
        CircleHomeworksViewController *homeworksVC = [[CircleHomeworksViewController alloc] initWithNibName:@"CircleHomeworksViewController" bundle:nil];
        homeworksVC.clazz = clazz;
        WeakifySelf;
        homeworksVC.cancelCallBack = ^{
            weakSelf.classId = -1;
            [weakSelf.campusMasterVC resetSelectIndex];
        };
        homeworksVC.editSuccessCallBack = ^{
            weakSelf.classId = -1;
            [weakSelf.campusMasterVC updateClassInfo];
        };
        self.classId = clazz.classId;
        [self.campusDetailVC.navigationController pushViewController:homeworksVC animated:YES];
    }
}

- (void)campusManagerViewControllerPopEditClassState{
  
    if (self.classId != 0) {
       
        self.classId = -1;
        [self.campusDetailVC.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - 礼物管理
- (void)configureGiftManagerUI{
    
    self.giftMasterVC = [[TeacherAwardsViewController alloc] initWithNibName:@"TeacherAwardsViewController" bundle:nil];
    UINavigationController *masterNav = [[UINavigationController alloc] initWithRootViewController:self.giftMasterVC];
    [masterNav setNavigationBarHidden:YES animated:NO];
    
    self.giftDetailVC = [[ExchangeRequestsViewController alloc] initWithNibName:@"ExchangeRequestsViewController" bundle:nil];
    self.giftDetailVC.isAwardListByClass = YES;
    UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:self.giftDetailVC];
    [detailNav setNavigationBarHidden:YES animated:NO];
    
    self.viewControllers = @[masterNav, detailNav];
}

- (void)updateAwards{

    [self.giftMasterVC updateAwards];
}

- (void)updateExchangeAwardsList{
    
    UINavigationController *nav = ((UINavigationController *)self.viewControllers[1]);
    if ([nav.viewControllers.lastObject isKindOfClass:[ExchangeRequestsViewController class]]) {
        return;
    }
    ExchangeRequestsViewController *vc = [[ExchangeRequestsViewController alloc] initWithNibName:@"ExchangeRequestsViewController" bundle:nil];
    [vc setExchanged:NO];
    [self.giftDetailVC.navigationController pushViewController:vc animated:NO];
}

#pragma mark - 首页管理
- (void)configureImageManagerUI{
    
    self.imageMasterVC = [[MISelectImageViewController alloc] initWithNibName:@"MISelectImageViewController" bundle:nil];
    UINavigationController *masterNav = [[UINavigationController alloc] initWithRootViewController:self.imageMasterVC];
    [masterNav setNavigationBarHidden:YES animated:NO];
    
    WeakifySelf;
    self.imageMasterVC.imageCallBack = ^(NSString * _Nonnull imageUrl) {
        
        weakSelf.imageDetailVC.imageUrl = imageUrl;
    };
    
    self.imageDetailVC = [[MILookImagesViewController alloc] initWithNibName:@"MILookImagesViewController" bundle:nil];
    UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:self.imageDetailVC];
    [detailNav setNavigationBarHidden:YES animated:NO];
    self.imageDetailVC.uploadImagesCallBack = ^{
        [weakSelf.imageMasterVC saveImages];
    };
    
    self.viewControllers = @[masterNav, detailNav];
}

- (void)updateImages{
    
    [self.imageMasterVC updateData];
}

#pragma mark - 设置
- (void)configureSetterUI{
    
    self.setterMasterVC = [[SettingsViewController alloc] initWithNibName:NSStringFromClass([SettingsViewController class]) bundle:nil];
    self.setterMasterVC.hiddenBackBtn = YES;
    
    UINavigationController *masterNav = [[UINavigationController alloc] initWithRootViewController:self.setterMasterVC];
    [masterNav setNavigationBarHidden:YES animated:NO];
    
    self.setterDetailVC = [[MIStockDetailViewController alloc] init];
    UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:self.setterDetailVC];
    [detailNav setNavigationBarHidden:YES animated:NO];
    
    self.viewControllers = @[masterNav, detailNav];
    
    WeakifySelf;
    self.setterMasterVC.pushCallBack = ^(UIViewController * _Nullable VC) {
        [weakSelf.setterDetailVC.navigationController popToRootViewControllerAnimated:NO];
        [weakSelf.setterDetailVC.navigationController pushViewController: VC animated:YES];
    };
    self.setterMasterVC.popResetPasswordVCCallBack = ^{
        [weakSelf.setterDetailVC.navigationController popToRootViewControllerAnimated:NO];
    };
}


- (void)updatePrimaryCloumnScale:(NSInteger)offset{
   
    if (self.primaryCloumnScale != offset) {
        self.primaryCloumnScale = offset;
        [self setDisplayMode:CSSplitDisplayModeDisplayPrimaryAndSecondary withAnimated:YES];
    }
}

@end
