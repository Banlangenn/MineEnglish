//
//  UIView+ViewDesc.m
//  AVPlayerViewControllerTest
//
//  Created by tanzhiwu on 2018/12/29.
//  Copyright © 2018 tanzhiwu. All rights reserved.
//

#import "UIView+ViewDesc.h"

@implementation UIView (ViewDesc)

- (UIView *)findViewByClassName:(NSString *)className
{
    UIView *view;
    if ([NSStringFromClass(self.class) isEqualToString:className]) {
        return self;
    } else {
        for (UIView *child in self.subviews) {
            view = [child findViewByClassName:className];
            if (view != nil) break;
        }
    }
    return view;
}

@end
