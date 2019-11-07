//
//  AppDelegate.m
//  X5Teacher
//
//  Created by yebw on 2017/11/5.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "Clazz.h"
#import "Constants.h"
#import "IMManager.h"
#import "AppDelegate.h"
#import "PushManager.h"
#import <Bugly/Bugly.h>
#import "UITabBar+KSBadge.h"
#import <AVOSCloud/AVOSCloud.h>
#import "AppDelegate+ConfigureUI.h"


@interface AppDelegate ()

@property (nonatomic, strong) NSDate *enterBackgroundDate;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.handleLaunchDict = launchOptions;
    
    [Bugly startWithAppId:@"f82097cc09"];
    // 配置leancloud
    [self setupLeanCloudServer];
    
    [self setupIfly];
    
    if (@available(iOS 11.0, *)) {
        UITableView.appearance.estimatedRowHeight = 0;
        UITableView.appearance.estimatedSectionFooterHeight = 0;
        UITableView.appearance.estimatedSectionHeaderHeight = 0;
    }
    
    self.onlineStartTime = CFAbsoluteTimeGetCurrent();
    //设置屏幕常亮不自动锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginDidSuccess:)
                                                 name:kNotificationKeyOfLoginSuccess
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clientDidKickOut:)
                                                 name:kIMManagerClientDidKickOutReceiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clientDidKickOut:)
                                                 name:kNotificationKeyOfAuthForbidden
                                               object:nil];
    
#if TEACHERSIDE | MANAGERSIDE
#else
    // 学生端老师批改作业后，刷新个人页面
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshUserInfo:)
                                                 name:kNotificationKeyOfCorrectHomework
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshUserInfo:)
                                                 name:kNotificationKeyOfRedoHomework
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshUserInfo:)
                                                 name:kNotificationKeyOfDeleteHomeworkTask
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshUserInfo:)
                                                 name:kNotificationKeyOfCommitHomework
                                               object:nil];
#endif
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSInteger num = application.applicationIconBadgeNumber;
    if (num != 0){
        AVInstallation *currentInstallation = [AVInstallation defaultInstallation];
        [currentInstallation setBadge:0];
        [currentInstallation saveEventually];
        application.applicationIconBadgeNumber=0;
    }
    
    if (self.enterBackgroundDate == nil) {
        return;
    }
    
    if ([[NSDate date] timeIntervalSinceDate:self.enterBackgroundDate] > 30.f) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfRefreshHomeworkSession object:nil];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
   
    self.enterBackgroundDate = [NSDate date];
    [self refreshOnlineState:NO needWait:YES];
}

- (void)applicationWillEnterForeground:(UIApplication *)application{
   
    [self refreshOnlineState:YES needWait:NO];
}

- (void)applicationWillTerminate:(UIApplication *)application{
    
    [self refreshOnlineState:NO needWait:YES];
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    //保存token
    APP.deviceToken = deviceToken;
    [AVOSCloud handleRemoteNotificationsWithDeviceToken:deviceToken constructingInstallationWithBlock:^(AVInstallation * _Nonnull currentInstallation) {

    }];
}

#pragma mark - system
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"%@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
   // NSDictionary * apsDict = [userInfo objectForKey:@"aps"];
    PushManagerType type = (PushManagerType)[[userInfo objectForKey:@"pushType"] integerValue];
    [self handleNotiForPushType:type];
}

#pragma mark - 学生端、教师端不支持横屏 管理端不支持竖屏
#if MANAGERSIDE

#else

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window{
    if (_allowRotation == YES) {
        return UIInterfaceOrientationMaskLandscapeRight;
    }else{
        return (UIInterfaceOrientationMaskPortrait);
    }
}

#endif

- (void)setupLeanCloudServer{
    
    // 配置 SDK 储存
    [AVOSCloud setServerURLString:@"https://avoscloud.com" forServiceModule:AVServiceModuleAPI];
    // 配置 SDK 推送
    [AVOSCloud setServerURLString:@"https://avoscloud.com" forServiceModule:AVServiceModulePush];
    // 配置 SDK 云引擎
    [AVOSCloud setServerURLString:@"https://avoscloud.com" forServiceModule:AVServiceModuleEngine];
    // 配置 SDK 即时通讯
    [AVOSCloud setServerURLString:@"https://router-g0-push.avoscloud.com" forServiceModule:AVServiceModuleRTM];
    
    [AVOSCloud setApplicationId:kAVOSCloudApplicationId clientKey:kAVOSCloudClientKey];
    [AVOSCloud setAllLogsEnabled:YES];
    [AVIMClient setUnreadNotificationEnabled:YES];
}

#pragma mark - public
- (void)showTabBarBadgeNum:(NSInteger)badge atIndex:(NSInteger)index;
{
    
#if TEACHERSIDE
#else
    // 同学圈不显示小红点
    if (index == 1) {
        return;
    }
#endif
    
    UIViewController * rootVc = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    if ([rootVc isKindOfClass:[UITabBarController class]])
    {
        UITabBarController * tabbarVc = (UITabBarController *)rootVc;
        [tabbarVc.tabBar showBadgeOnItemIndex:index totalTabbarCount:3 withInfo:badge];
    }
}

- (void)openRemoteNotification
{
    AVInstallation *currentInstallation = [AVInstallation defaultInstallation];
    
#if MANAGERSIDE
    currentInstallation.deviceProfile = @"manager_pro";
    if (APP.currentUser.authority == TeacherAuthoritySuperManager) {
        [currentInstallation addUniqueObject:@"SuperManager" forKey:@"channels"];
    }
#elif TEACHERSIDE
    currentInstallation.deviceProfile = @"teacher_pro";
    if (APP.currentUser.authority == TeacherAuthoritySuperManager) {
        [currentInstallation addUniqueObject:@"SuperManager" forKey:@"channels"];
    }
#else
    currentInstallation.deviceProfile = @"student_pro";
    Clazz *clazz = APP.currentUser.clazz;
    [currentInstallation addUniqueObject:[NSString stringWithFormat:@"class_%@", @(clazz.classId)] forKey:@"channels"];
#endif
    //    [currentInstallation addObject:[NSString stringWithFormat:@"%@", @(APP.currentUser.userId)] forKey:@"userId"];
    [currentInstallation setObject:[NSString stringWithFormat:@"%@", @(APP.currentUser.userId)] forKey:@"userId"];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
    }];
}

- (void)removeRemoteNotification
{
    AVInstallation *currentInstallation = [AVInstallation defaultInstallation];

#if MANAGERSIDE
    currentInstallation.deviceProfile = @"manager_pro";
    
    if (APP.currentUser.authority == TeacherAuthoritySuperManager) {
        [currentInstallation removeObject:@"SuperManager" forKey:@"channels"];
    }
#elif TEACHERSIDE
    currentInstallation.deviceProfile = @"teacher_pro";
    
    if (APP.currentUser.authority == TeacherAuthoritySuperManager) {
        [currentInstallation removeObject:@"SuperManager" forKey:@"channels"];
    }
#else
    currentInstallation.deviceProfile = @"student_pro";
    Clazz *clazz = APP.currentUser.clazz;
    [currentInstallation removeObject:[NSString stringWithFormat:@"class_%@", @(clazz.classId)] forKey:@"channels"];
#endif
    //    [currentInstallation removeObject:[NSString stringWithFormat:@"%@", @(APP.currentUser.userId)] forKey:@"userId"];
    [currentInstallation removeObjectForKey:@"userId"];
    
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
    }];
}

@end


