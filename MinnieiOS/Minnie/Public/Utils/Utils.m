//
//  Utils.m
//  X5
//
//  Created by yebw on 2017/9/9.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (UIWindow *)topmostWindow {
    UIWindow *window = nil;
    if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        window = [[UIApplication sharedApplication].delegate performSelector:@selector(window)];
    }
    
    return window;
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma 正则匹配手机号
+ (BOOL)checkTelNumber:(NSString *) telNumber
{
    NSString *pattern = @"^1+[34578]+\\d{9}";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    BOOL isMatch = [pred evaluateWithObject:telNumber];
    return isMatch;
}


#pragma 正则匹配用户密码4-8位数字和字母组合
+ (BOOL)checkPassword:(NSString *) password
{
    return password.length>=4 && password.length<=8;
}

+ (NSString *)formatedSizeString:(long long)size
{
    NSString *result = nil;
    if (size >= 1024*1024*1024) {
        long long s = (long long)round(size*100/(1024*1024*1024.f));
        if (s % 100 == 0) {
            result = [NSString stringWithFormat:@"%lldG", s/100];
        }
        else if (s % 10 == 0) {
            result = [NSString stringWithFormat:@"%.1fG", s/100.f];
        }
        else {
            result = [NSString stringWithFormat:@"%.2fG", s/100.f];
        }
    }
    else if (size >= 1024*1024) {
        long long s = (long long)round(size*100/(1024*1024.f));
        if (s % 100 == 0) {
            result = [NSString stringWithFormat:@"%lldM", s/100];
        }
        else if (s % 10 == 0) {
            result = [NSString stringWithFormat:@"%.1fM", s/100.f];
        }
        else {
            result = [NSString stringWithFormat:@"%.2fM", s/100.f];
        }
    }
    else if (size >= 1024) {
        long long s = (long long)round(size/1024.f);
        result = [NSString stringWithFormat:@"%lldK", s];
    }
    else {
        result = [NSString stringWithFormat:@"%lldB", size];
    }
    
    if (result == nil) {
        result = @"";
    }
    
    return result;
}

+ (NSString *)formatedDayDateString:(long long)microSecond
{
    //    TIKI;
    NSTimeInterval second = microSecond/1000;
    NSString *result = nil;
    NSDate *now = [NSDate date];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
    
    do {
        NSTimeInterval delta = [now timeIntervalSinceDate:date];
        if (delta < 60) { // 处理60s内的
            result = @"刚刚";
            break;
        }
        else if (delta < 3600) { // 处理1小时内的
            result = [NSString stringWithFormat:@"%.f分钟前", delta/60];
            break;
        }
        
        static NSDateFormatter *dateFormatter = nil;
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
        }
        
        // 如果是今天
        if ([Utils isSameDay:now withDate:date]) {
            result = @"今天";
            break;
        }
        
        NSDate *today = [Utils today];
        
        // 如果是昨天
        NSDate *yesterday = [NSDate dateWithTimeIntervalSince1970:[today timeIntervalSince1970]-24*3600];
        if ([Utils isSameDay:yesterday withDate:date]) {
            result = @"昨天";
            break;
        }
        
        // 如果是前天
        NSDate *dayBeforYesterday = [NSDate dateWithTimeIntervalSince1970:[today timeIntervalSince1970]-24*3600];
        if ([Utils isSameDay:dayBeforYesterday withDate:date]) {
            [dateFormatter setDateFormat:@"H:mm"];
            result = @"前天";
            break;
        }
        
        [dateFormatter setDateFormat:@"MM/dd"];
        result = [dateFormatter stringFromDate:date];
    } while(NO);
    
    //    TAKA(@"格式化时间");
    if (result == nil) {
        result = @"";
    }
    return result;
}

+ (NSString *)formatedDateString:(long long)microSecond
{
    //    TIKI;
    
    NSTimeInterval second = microSecond/1000;
    NSString *result = nil;
    NSDate *now = [NSDate date];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
    
    do {
        NSTimeInterval delta = [now timeIntervalSinceDate:date];
        if (delta < 60) { // 处理60s内的
            result = @"刚刚";
            break;
        }
        else if (delta < 3600) { // 处理1小时内的
            result = [NSString stringWithFormat:@"%.f分钟前", delta/60];
            break;
        }
        
        static NSDateFormatter *dateFormatter = nil;
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
        }
        
        // 如果是今天
        if ([Utils isSameDay:now withDate:date]) {
            [dateFormatter setDateFormat:@"H:mm"];
            result = [NSString stringWithFormat:@"今天 %@", [dateFormatter stringFromDate:date]];
            break;
        }
        
        NSDate *today = [Utils today];

        // 如果是昨天
        NSDate *yesterday = [NSDate dateWithTimeIntervalSince1970:[today timeIntervalSince1970]-24*3600];
        if ([Utils isSameDay:yesterday withDate:date]) {
            [dateFormatter setDateFormat:@"H:mm"];
            result = [NSString stringWithFormat:@"昨天 %@", [dateFormatter stringFromDate:date]];
            break;
        }
        
        // 如果是前天
        NSDate *dayBeforYesterday = [NSDate dateWithTimeIntervalSince1970:[today timeIntervalSince1970]-24*3600];
        if ([Utils isSameDay:dayBeforYesterday withDate:date]) {
            [dateFormatter setDateFormat:@"H:mm"];
            result = [NSString stringWithFormat:@"前天 %@", [dateFormatter stringFromDate:date]];
            break;
        }
        
        // 如果是今年
        if ([Utils isSameYear:now withDate:date]) {
            [dateFormatter setDateFormat:@"M月d号"];
            result = [dateFormatter stringFromDate:date];
            break;
        }

        [dateFormatter setDateFormat:@"yyyy年M月d号"];
        result = [dateFormatter stringFromDate:date];
    } while(NO);
    
    //    TAKA(@"格式化时间");
    
    if (result == nil) {
        result = @"";
    }
    
    return result;
}

+ (NSDate *)today
{
    NSDate *now = [NSDate date];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ) fromDate:now];
    
    [components setHour:-[components hour]];
    [components setMinute:-[components minute]];
    [components setSecond:-[components second]];
    NSDate *today = [cal dateByAddingComponents:components toDate:now options:0];
    
    return today;
}

+ (BOOL)isSameDay:(NSDate *)date withDate:(NSDate *)date1
{
    NSDateComponents *components1 = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitDay) fromDate:date];
    NSDateComponents *components2 = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitDay) fromDate:date1];
    
    BOOL result = ([components1 day]==[components2 day]
                   && [components1 month]==[components2 month]
                   && [components1 year]==[components2 year]);
    
    return result;
}

+ (BOOL)isSameYear:(NSDate *)date withDate:(NSDate *)date1
{
    NSDateComponents *components1 = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear) fromDate:date];
    NSDateComponents *components2 = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear) fromDate:date1];
    
    return [components1 year]==[components2 year];
}

+ (NSString *)dateFormatterTime:(long long)aTimeInterval
{
    double second = aTimeInterval/1000;
    
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    
    NSString *postDateString = nil;
    postDateString = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:second]];
    return postDateString;
}

+ (NSString *)montAndDateTime:(long long)microSecond {
    double second = microSecond/1000;
    
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"M月dd日"];
    }

    NSString *postDateString = nil;
    postDateString = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:second]];
    return postDateString;
}

+ (NSString *)qiniuHost {
    return @"res.zhengminyi.com";
}

+ (UIView *)viewOfVCAddToWindowWithVC:(UIViewController *)vc width:(CGFloat)width{
    
    CGRect bounds = [UIScreen mainScreen].bounds;
    UIViewController *rootVC = [Utils topmostWindow].rootViewController;
    UIView *bgView = [[UIView alloc] initWithFrame:bounds];
    bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [rootVC.view addSubview:bgView];
    [bgView addSubview:vc.view];
    [rootVC addChildViewController:vc];
    [vc didMoveToParentViewController:rootVC];
    vc.view.frame = CGRectMake((bounds.size.width - width)/2.0, 50, width, bounds.size.height - 100);
    vc.view.layer.cornerRadius = 10.f;
    vc.view.layer.masksToBounds = YES;
    return bgView;
}

+ (void)saveWordsTextWithKey:(NSString *)key value:(NSArray *)value{
    
    NSDictionary *tempDict = [[NSUserDefaults standardUserDefaults] valueForKey:kWordRecognizeText];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:tempDict];
    [dict setValue:value forKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kWordRecognizeText];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSDictionary *)getWordsText{

    NSDictionary *tempDict = [[NSUserDefaults standardUserDefaults] valueForKey:kWordRecognizeText];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return tempDict;
}

@end


