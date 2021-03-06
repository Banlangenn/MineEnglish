//
//  ViewController.m
// X5
//
//  Created by yebw on 2017/8/18.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "LoadViewController.h"
#import "User.h"
#import "BaseRequest.h"
#import "HomeworkManagerViewController.h"
#import "PublicService.h"
#import "AppDelegate.h"
#import "LoginViewController.h"
#import "PortraitNavigationController.h"

#import "TrialClassViewController.h"
#import <UserNotifications/UserNotifications.h>

#import "Application.h"
@interface LoadViewController ()



@end

@implementation LoadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [BaseRequest setToken:APP.currentUser.token];
    
    [[UITabBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UITabBar appearance] setTranslucent:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self registerForRemoteNotification];
    
    //检查更新
  //  [self checkAppVersion];
    
    if (APP.currentUser.token.length == 0 ||
        APP.currentUser.nickname.length==0 ||
        APP.currentUser.avatarUrl.length == 0) {
        NSString *nibName = nil;
#if TEACHERSIDE
        nibName = @"LoginViewController_Teacher";
#else
        nibName = @"LoginViewController_Student";
#endif
        LoginViewController *loginVC = [[LoginViewController alloc] initWithNibName:nibName bundle:nil];
        
        PortraitNavigationController *loginNC = [[PortraitNavigationController alloc] initWithRootViewController:loginVC];
        
        [self.view.window setRootViewController:loginNC];
    } else {
        NSInteger userId = APP.currentUser.userId;
        [PublicService requestUserInfoWithId:userId
                                    callback:^(Result *result, NSError *error) {
                                        BOOL shouldToHome = YES;
                                        if (error == nil) {
#if TEACHERSIDE
                                            Teacher *userInfo = (Teacher *)(result.userInfo);
#else
                                            Student *userInfo = (Student *)(result.userInfo);
                                            
                                            if (userInfo.clazz.classId==0 || userInfo.enrollState==1) { // 有班级信息
                                                shouldToHome = NO;
                                            }
#endif
                                            userInfo.token = APP.currentUser.token;
                                            APP.currentUser = userInfo;
                                        } else {
#if TEACHERSIDE
#else
                                            Student *userInfo = (Student *)(APP.currentUser);
                                            if (userInfo.clazz.classId==0 || userInfo.enrollState==1) { // 有班级信息
                                                shouldToHome = NO;
                                            }
#endif
                                        }
                                        
                                        if (shouldToHome) {
                                            AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                            [delegate toHome];
                                        } else {
#if TEACHERSIDE
#else
                                            TrialClassViewController *clzzVC = [[TrialClassViewController alloc] initWithNibName:NSStringFromClass([TrialClassViewController class]) bundle:nil];
                                            
                                            [self.view.window setRootViewController:clzzVC];
#endif
                                        }
                                    }];
    }
}



- (void)dealloc {
    NSLog(@"%s", __func__);
}



- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)registerForRemoteNotification {
    UNUserNotificationCenter *uncenter = [UNUserNotificationCenter currentNotificationCenter];
    [uncenter requestAuthorizationWithOptions:(UNAuthorizationOptionAlert+UNAuthorizationOptionBadge+UNAuthorizationOptionSound)
                            completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                                });
                                NSLog(@"%@" , granted ? @"授权成功" : @"授权失败");
                            }];
    
    [uncenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
            NSLog(@"未选择");
        } else if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
            NSLog(@"未授权");
        } else if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
            NSLog(@"已授权");
        }
    }];
}

@end

