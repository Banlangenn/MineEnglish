//
//  EntranceClassView.h
//  MinnieManager
//
//  Created by songzhen on 2019/12/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^InviteCodeCallback) (NSString *inviteCode);

@interface EntranceClassView : UIView

+ (void)showInSuperView:(UIView *)superView
               callback:(InviteCodeCallback)callback;

+ (void)hideAnimated:(BOOL)animated;


@end

NS_ASSUME_NONNULL_END
