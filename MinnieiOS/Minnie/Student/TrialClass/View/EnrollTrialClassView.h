//
//  EnrollTrialView.h
//  X5Teacher
//
//  Created by yebw on 2018/2/4.
//  Copyright © 2018年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>


#pragma mark - 报名
typedef void(^EnrollTrialViewConfirmCallback)(NSString *name,
                                              NSString *grade,
                                              NSInteger gender);

@interface EnrollTrialClassView : UIView

+ (void)showInSuperView:(UIView *)superView
               callback:(EnrollTrialViewConfirmCallback)callback;

+ (void)hideAnimated:(BOOL)animated;


@end

#pragma mark - 入学
typedef void (^InviteCodeCallback) (NSString *inviteCode);

@interface EntranceClassView : UIView

+ (void)showInSuperView:(UIView *)superView
               callback:(InviteCodeCallback)callback;

+ (void)hideAnimated:(BOOL)animated;


@end

