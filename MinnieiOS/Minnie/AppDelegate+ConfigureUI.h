//
//  AppDelegate+ConfigureUI.h
//  Minnie
//
//  Created by songzhen on 2019/7/18.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "AppDelegate.h"
#import "PushManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate (ConfigureUI)<UITabBarControllerDelegate>

// 进入首页
- (void)toHome;
// 登录成功
- (void)loginDidSuccess:(NSNotification *)notification;
// 强制登出
- (void)clientDidKickOut:(NSNotification *)notification;
// 处理推送消息
- (void)handleNotiForPushType:(PushManagerType)type;
// 更新用户信息
- (void)refreshUserInfo:(NSNotification *)notification;
// 更新上下线状态  times:在线时长
- (void)refreshOnlineState:(BOOL)online;
// 更新上下线状态  times:在线时长
- (void)refreshOnlineState:(BOOL)online
                  needWait:(BOOL)needWait;

// 退出登陆
- (void)logout;


- (void)setupIfly;
- (void)destroyIfly;


@end

NS_ASSUME_NONNULL_END
