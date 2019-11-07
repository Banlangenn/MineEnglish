//
//  AppDelegate+ConfigureUI.m
//  Minnie
//
//  Created by songzhen on 2019/7/18.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "AuthService.h"
#import <Bugly/Bugly.h>
#import "IMManager.h"
#import "AppDelegate.h"
#import "PublicService.h"
#import "ManagerServce.h"
#import "AppDelegate+ConfigureUI.h"
#import "LoginViewController.h"
#import "PortraitNavigationController.h"
#import <iflyMSC/iflyMSC.h>

#if TEACHERSIDE

#import "PortraitTabBarController.h"
#import "TeacherAccountViewController.h"
#import "TeacherClassesViewController.h"
#import "HomeworkSessionsContainerViewController.h"

#elif MANAGERSIDE

#import "MIStockSplitViewController.h"

#else

#import "GuideViewController.h"
#import "PortraitTabBarController.h"
#import "TrialClassViewController.h"
#import "CircleContainerController.h"
#import "StudentAccountViewController.h"
#import "HomeworkSessionsContainerViewController.h"

#endif

@implementation AppDelegate (ConfigureUI)

#if TEACHERSIDE

- (void)toHome {
    
    [self refreshOnlineState:YES needWait:NO];
    UIColor *normalTitleColor = [UIColor colorWithHex:0x999999];
    UIColor *selectedTitleColor = [UIColor colorWithHex:0x0098FE];
    UIFont *font = [UIFont systemFontOfSize:10.f];
    NSDictionary *normalTitleAttributes = @{NSForegroundColorAttributeName: normalTitleColor,
                                            NSFontAttributeName: font};
    NSDictionary *selectedTitleAttributes = @{NSForegroundColorAttributeName: selectedTitleColor,
                                              NSFontAttributeName: font};
    
    HomeworkSessionsContainerViewController *tasksVC = [[HomeworkSessionsContainerViewController alloc] initWithNibName:NSStringFromClass([HomeworkSessionsContainerViewController class]) bundle:nil];
    UINavigationController *tasksNC = [[UINavigationController alloc] initWithRootViewController:tasksVC];
    [tasksNC setNavigationBarHidden:YES];
    UITabBarItem *tasksItem = [[UITabBarItem alloc] initWithTitle:@"消息"
                                                            image:[[UIImage imageNamed:@"buttonbar_correcting_unsel"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                    selectedImage:[[UIImage imageNamed:@"buttonbar_correcting_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [tasksItem setTitleTextAttributes:normalTitleAttributes forState:UIControlStateNormal];
    [tasksItem setTitleTextAttributes:selectedTitleAttributes forState:UIControlStateSelected];
    tasksNC.tabBarItem = tasksItem;
    
    
    TeacherClassesViewController *classesVC = [[TeacherClassesViewController alloc] initWithNibName:NSStringFromClass([TeacherClassesViewController class]) bundle:nil];
    UINavigationController *classesNC = [[UINavigationController alloc] initWithRootViewController:classesVC];
    [classesNC setNavigationBarHidden:YES];
    UITabBarItem *classesItem = [[UITabBarItem alloc] initWithTitle:@"班级"
                                                              image:[[UIImage imageNamed:@"buttonbar_class_manager_unsel"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                      selectedImage:[[UIImage imageNamed:@"buttonbar_class_manager_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [classesItem setTitleTextAttributes:normalTitleAttributes forState:UIControlStateNormal];
    [classesItem setTitleTextAttributes:selectedTitleAttributes forState:UIControlStateSelected];
    classesNC.tabBarItem = classesItem;
    
    TeacherAccountViewController *accountVC = [[TeacherAccountViewController alloc] initWithNibName:NSStringFromClass([TeacherAccountViewController class]) bundle:nil];
    
    UINavigationController *accountNC = [[UINavigationController alloc] initWithRootViewController:accountVC];
    [accountNC setNavigationBarHidden:YES];
    UITabBarItem *accountItem = [[UITabBarItem alloc] initWithTitle:@"我的"
                                                              image:[[UIImage imageNamed:@"buttonbar_my_unsel"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                      selectedImage:[[UIImage imageNamed:@"buttonbar_my_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [accountItem setTitleTextAttributes:normalTitleAttributes forState:UIControlStateNormal];
    [accountItem setTitleTextAttributes:selectedTitleAttributes forState:UIControlStateSelected];
    accountNC.tabBarItem = accountItem;
    
    PortraitTabBarController *tbBarController = [[PortraitTabBarController alloc] init];
    tbBarController.viewControllers = @[tasksNC, /*homeworksNC,*/ classesNC, accountNC];
    tbBarController.delegate = self;
    [UIApplication sharedApplication].keyWindow.rootViewController = tbBarController;
    
    if (self.handleLaunchDict)
    {
        NSDictionary * pushDict =  [self.handleLaunchDict objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        
        if (pushDict)
        {
            PushManagerType type = (PushManagerType)[[pushDict objectForKey:@"pushType"] integerValue];
            [self handleNotiForPushType:type];
        }
    }
}

#elif MANAGERSIDE
- (void)toHome {
    
    [self refreshOnlineState:YES needWait:NO];
    MIStockSplitViewController *splitView = [[MIStockSplitViewController alloc] init];
    [UIApplication sharedApplication].keyWindow.rootViewController = splitView;
}
#else

- (void)toHome {
    
    //新版本引导页
    if (!APP.userGuide)
    {
        GuideViewController * guideVc = [[GuideViewController alloc] init];
        [self.window setRootViewController:guideVc];
        return;
    }
    [self refreshOnlineState:YES needWait:NO];
    
    UIColor *normalTitleColor = [UIColor colorWithHex:0x999999];
    UIColor *selectedTitleColor = [UIColor colorWithHex:0x0098FE];
    UIFont *font = [UIFont systemFontOfSize:10.f];
    NSDictionary *normalTitleAttributes = @{NSForegroundColorAttributeName: normalTitleColor,
                                            NSFontAttributeName: font};
    NSDictionary *selectedTitleAttributes = @{NSForegroundColorAttributeName: selectedTitleColor,
                                              NSFontAttributeName: font};
    
    HomeworkSessionsContainerViewController *tasksVC = [[HomeworkSessionsContainerViewController alloc] initWithNibName:NSStringFromClass([HomeworkSessionsContainerViewController class]) bundle:nil];
    UINavigationController *tasksNC = [[UINavigationController alloc] initWithRootViewController:tasksVC];
    [tasksNC setNavigationBarHidden:YES];
    UITabBarItem *tasksItem = [[UITabBarItem alloc] initWithTitle:@"作业"
                                                            image:[[UIImage imageNamed:@"buttonbar_mission_unsel"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                    selectedImage:[[UIImage imageNamed:@"buttonbar_mission_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [tasksItem setTitleTextAttributes:normalTitleAttributes forState:UIControlStateNormal];
    [tasksItem setTitleTextAttributes:selectedTitleAttributes forState:UIControlStateSelected];
    tasksNC.tabBarItem = tasksItem;
    
    CircleContainerController *classmateVC = [[CircleContainerController alloc] initWithNibName:NSStringFromClass([CircleContainerController class]) bundle:nil];
    
    UINavigationController *classmateNC = [[UINavigationController alloc] initWithRootViewController:classmateVC];
    [classmateNC setNavigationBarHidden:YES];
    UITabBarItem *classmateItem = [[UITabBarItem alloc] initWithTitle:@"同学圈"
                                                                image:[[UIImage imageNamed:@"buttonbar_class_unsel"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                        selectedImage:[[UIImage imageNamed:@"buttonbar_class_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [classmateItem setTitleTextAttributes:normalTitleAttributes forState:UIControlStateNormal];
    [classmateItem setTitleTextAttributes:selectedTitleAttributes forState:UIControlStateSelected];
    classmateNC.tabBarItem = classmateItem;
    
    StudentAccountViewController *accountVC = [[StudentAccountViewController alloc] initWithNibName:NSStringFromClass([StudentAccountViewController class]) bundle:nil];
    
    UINavigationController *accountNC = [[UINavigationController alloc] initWithRootViewController:accountVC];
    [accountNC setNavigationBarHidden:YES];
    UITabBarItem *accountItem = [[UITabBarItem alloc] initWithTitle:@"我的"
                                                              image:[[UIImage imageNamed:@"buttonbar_my_unsel"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                      selectedImage:[[UIImage imageNamed:@"buttonbar_my_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [accountItem setTitleTextAttributes:normalTitleAttributes forState:UIControlStateNormal];
    [accountItem setTitleTextAttributes:selectedTitleAttributes forState:UIControlStateSelected];
    accountNC.tabBarItem = accountItem;
    
    PortraitTabBarController *tbBarController = [[PortraitTabBarController alloc] init];
    tbBarController.viewControllers = @[tasksNC, classmateNC, accountNC];
    tbBarController.delegate = self;
    [UIApplication sharedApplication].keyWindow.rootViewController = tbBarController;
}

#endif


- (void)loginDidSuccess:(NSNotification *)notification {
    BOOL shouldToHome = YES;
#if TEACHERSIDE
    Teacher *teacher = (Teacher *)(APP.currentUser);
    [Bugly setUserIdentifier:teacher.nickname];
#elif MANAGERSIDE
    Teacher *teacher = (Teacher *)(APP.currentUser);
    [Bugly setUserIdentifier:teacher.nickname];
#else
    Student *userInfo = (Student *)(APP.currentUser);
    [Bugly setUserIdentifier:userInfo.nickname];
    if (userInfo.clazz.classId==0 || userInfo.enrollState==1) {
        shouldToHome = NO;
    }
    
    TrialClassViewController *clzzVC = [[TrialClassViewController alloc] initWithNibName:NSStringFromClass([TrialClassViewController class]) bundle:nil];
    
    [self.window setRootViewController:clzzVC];
#endif
    
    if (shouldToHome) {
        [self toHome];
    }
}

- (void)clientDidKickOut:(NSNotification *)notification {
    if (APP.currentUser == nil) {
        return;
    }
    
    [[IMManager sharedManager] logout];
    APP.currentUser = nil;
    //新增 by shidongdong
    [self removeRemoteNotification];
    NSString *nibName = nil;
#if TEACHERSIDE
    nibName = @"LoginViewController_Teacher";
    
#elif MANAGERSIDE
    nibName = @"LoginViewController_Teacher";
#else
    nibName = @"LoginViewController_Student";
#endif
    [[NSUserDefaults standardUserDefaults]  removeObjectForKey:kWordRecognizeText];
    LoginViewController *loginVC = [[LoginViewController alloc] initWithNibName:nibName bundle:nil];
    
    PortraitNavigationController *loginNC = [[PortraitNavigationController alloc] initWithRootViewController:loginVC];
    self.window.rootViewController = loginNC;
}

- (void)handleNotiForPushType:(PushManagerType)type
{
#if TEACHERSIDE | MANAGERSIDE
#else
    if ([self.window.rootViewController isKindOfClass:[PortraitTabBarController class]])
    {
        if (type == PushManagerMessage)
        {
            PortraitTabBarController * rootTabVc = (PortraitTabBarController *)self.window.rootViewController;
            rootTabVc.selectedIndex = 0;
        }
        else if (type == PushManagerCircle)
        {
            PortraitTabBarController * rootTabVc = (PortraitTabBarController *)self.window.rootViewController;
            rootTabVc.selectedIndex = 1;
        }
    }
#endif
}

#pragma mark - UITabBarControllerDelegate
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    
    // 确保当前在首页界面
    if ([viewController isEqual:[tabBarController.viewControllers firstObject]]) {
        // ! 即将选中的页面是之前上一次选中的控制器页面
        if (![viewController isEqual:tabBarController.selectedViewController]) {
            return YES;
        }
        
        // 获取当前点击时间
        NSDate *currentDate = [NSDate date];
        CGFloat timeInterval = currentDate.timeIntervalSince1970 - self.lastSelectedDate.timeIntervalSince1970;
        
        // 两次点击时间间隔少于 0.5S 视为一次双击
        if (timeInterval < 0.5) {
            // 通知首页刷新数据
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfTabBarDoubleClick object:nil];
            
            // 双击之后将上次选中时间置为1970年0点0时0分0秒,用以避免连续三次或多次点击
            self.lastSelectedDate = [NSDate dateWithTimeIntervalSince1970:0];
            return NO;
        }
        // 若是单击将当前点击时间复制给上一次单击时间
        self.lastSelectedDate = currentDate;
        
    }
    else if ([viewController isEqual:[tabBarController.viewControllers objectAtIndex:1]])
    {
        [self showTabBarBadgeNum:0 atIndex:1];
    }
    
    return YES;
}

#pragma mark - 更新用户信息
- (void)refreshUserInfo:(NSNotification *)notification {
    NSInteger userId = APP.currentUser.userId;
    if (userId == 0) {
        return;
    }
    
    [PublicService requestUserInfoWithId:userId
                                callback:^(Result *result, NSError *error) {
                                    if (error == nil) {
#if TEACHERSIDE | MANAGERSIDE
                                        Teacher *userInfo = (Teacher *)(result.userInfo);
#else
                                        Student *userInfo = (Student *)(result.userInfo);
                                        
#endif
                                        userInfo.token = APP.currentUser.token;
                                        APP.currentUser = userInfo;
                                        
                                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfProfileUpdated
                                                                                            object:nil];
                                    }
                                }];
}

#pragma mark - 上下线同步
- (void)refreshOnlineState:(BOOL)online
                  needWait:(BOOL)needWait{
    
    NSInteger times = 0;
    if (!online) {// 在线时长
        times = (CFAbsoluteTimeGetCurrent() - self.onlineStartTime)/60;
    }
    WeakifySelf;
    if (needWait) {
        // 进入后台、退出APP，异步请求失败，结果无法返回，无法完成，使用信号量解决请求失败问题
       NSString  *url = [NSString stringWithFormat:@"%@/user/onoffline",kConfigBaseUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        request.timeoutInterval = 10;
        request.HTTPMethod = @"POST";
        // 请求体
        NSDictionary *bodyDic = @{@"isOnline":@(online),@"times":@(times)};
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyDic options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:jsonData];
        // 请求头
        NSString *tokenStr = APP.currentUser.token;
        [request setValue:tokenStr forHTTPHeaderField:@"Authorization"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        NSURLSession *session = [NSURLSession sharedSession];
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            weakSelf.onlineStartTime = CFAbsoluteTimeGetCurrent();
            
            dispatch_semaphore_signal(semaphore);
        }];
        [task resume];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    } else {
       
        [ManagerServce requestUpdateOnlineState:online
                                          times:times
                                       callback:^(Result *result, NSError *error) {
                                           if (error) {
                                               NSLog(@"更新在线状态失败 %d %lu",online,times);
                                           } else {
                                               NSLog(@"更新在线状态成功 %d %lu",online,times);
                                           }
                                           weakSelf.onlineStartTime = CFAbsoluteTimeGetCurrent();
                                       }];
    }
}


- (void)logout{
    
    NSInteger times = (CFAbsoluteTimeGetCurrent() - self.onlineStartTime)/60;
    WeakifySelf; // 先更新在线状态，后退出登录
    [ManagerServce requestUpdateOnlineState:NO
                                      times:times
                                   callback:^(Result *result, NSError *error) {

                                       [AuthService logoutWithCallback:^(Result *result, NSError *error) {
                                           
                                           if (error) {
                                               [HUD showErrorWithMessage:@"退出失败"];
                                               return ;
                                           }
                                           
                                           AppDelegate * app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                           [app removeRemoteNotification];
                                           Application.sharedInstance.currentUser = nil;
                                           [[IMManager sharedManager] logout];
                                           
                                           [APP clearData];
                                           NSString *nibName = nil;
#if TEACHERSIDE | MANAGERSIDE
                                           nibName = @"LoginViewController_Teacher";
#else
                                           nibName = @"LoginViewController_Student";
#endif
                                           LoginViewController *loginVC = [[LoginViewController alloc] initWithNibName:nibName bundle:nil];
                                           
                                           PortraitNavigationController *loginNC = [[PortraitNavigationController alloc] initWithRootViewController:loginVC];
                                           weakSelf.window.rootViewController = loginNC;

                                           [[NSUserDefaults standardUserDefaults]  removeObjectForKey:kWordRecognizeText];
                                       }];

                                   }];
}

#pragma mark - 讯飞
- (void)setupIfly{
    
    [self destroyIfly];
    
    [IFlySetting setLogFile:LVL_ALL];
    [IFlySetting showLogcat:YES];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    [IFlySetting setLogFilePath:cachePath];
    
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@", @"5da71f38"];
    [IFlySpeechUtility createUtility:initString];
}


- (void)destroyIfly{
    
    [IFlySpeechUtility destroy];
}
@end
