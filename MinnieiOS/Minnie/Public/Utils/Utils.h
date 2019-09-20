//
//  Utils.h
//  X5
//
//  Created by yebw on 2017/9/9.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Utils : NSObject

#pragma window

+ (UIWindow *)topmostWindow;

#pragma 颜色

+ (UIImage *)imageWithColor:(UIColor *)color;

#pragma 正则匹配手机号
+ (BOOL)checkTelNumber:(NSString *)telNumber;

#pragma 正则匹配用户密码4-8位数字和字母组合

+ (BOOL)checkPassword:(NSString *)password;

+ (NSString *)formatedSizeString:(long long)size;

+ (NSString *)formatedDateString:(long long)microSecond;

+ (NSString *)formatedDayDateString:(long long)microSecond;

+ (NSString *)dateFormatterTime:(long long)microSecond;

+ (NSString *)montAndDateTime:(long long)microSecond;

#pragma mark - qiniu

+ (NSString *)qiniuHost;

#pragma mark - ViewController的view以弹窗的形式添加到rootVC
+ (UIView *)viewOfVCAddToWindowWithVC:(UIViewController *)vc width:(CGFloat)width;

@end
