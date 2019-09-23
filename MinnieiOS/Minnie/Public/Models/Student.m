//
//  Student.m
//  X5
//
//  Created by yebw on 2018/4/6.
//  Copyright © 2018年 mfox. All rights reserved.
//

#import "Student.h"
#import "Clazz.h"

@implementation Student

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"userId":@"id",   // 用户id
             @"username":@"username", // 用户名
             @"nickname":@"nickname", // 昵称
             @"phoneNumber":@"phoneNumber", // 电话号码
             @"gender":@"gender", //  性别
             @"avatarUrl":@"avatarUrl", // 头像地址
             @"token":@"token", // token
             @"grade":@"grade", // 年级
             @"starCount":@"starCount", // 星星数
             @"circleUpdate":@"circleUpdate", // 朋友圈更新
             @"homeworks":@"homeworks", // 作业情况数组
             @"clazz":@"class", // 所在班级信息，可能没有
             @"enrollState":@"enrollState", // 报名状态
             @"warnCount":@"warnCount",
             @"stuLabel":@"stuLabel",
             @"stuRemark":@"stuRemark"
             };
}

+ (NSValueTransformer *)clazzTeacherJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[Clazz class]];
}

@end


@implementation StudentZeroTask

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
    return @{@"avatar":@"avatar",
             @"userId":@"userId",
             @"nickName":@"nickName",
             @"hometaskId":@"hometaskId",
             @"title":@"title",
             @"createTeacher":@"createTeacher",
             @"content":@"content",
             };
}

@end


@implementation StudentsByName

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"userId":@"userId",
             @"nickname":@"nickName",
             @"avatarUrl":@"avatar",
             @"className":@"className"
             };
}
@end


@implementation StudentByClass

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"userId":@"userId",
             @"nickname":@"nickName",
             @"avatarUrl":@"avatar",
             @"username":@"username",
             @"phoneNumber":@"phoneNumber",
             @"gender":@"gender",
             @"token":@"token"
             };
}
@end

@implementation StudentsByClass

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"classId":@"classId",
             @"className":@"className",
             @"students":@"students",
             };
}

+ (NSValueTransformer *)studentsJSONTransformer {
    
    return [MTLJSONAdapter arrayTransformerWithModelClass:[StudentByClass class]];
}

@end



@implementation StudentDetail

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"isOnline":@"isOnline",
             @"uncorrectHomeworksCount":@"uncorrectHomeworksCount",
             @"testAvgScore":@"testAvgScore",
             @"medalCount":@"medalCount",
             @"likeCount":@"likeCount",
             @"starCount":@"starCount",
             @"giftCount":@"giftCount",
             @"allHomeworksCount":@"allHomeworksCount",
             @"commitHomeworksCount":@"commitHomeworksCount",
             @"avgScore":@"avgScore",
             @"excellentHomeworksCount":@"excellentHomeworksCount",
             @"overdueHomeworksCount":@"overdueHomeworksCount",
             @"shareCount":@"shareCount",
             @"homeworks":@"homeworks"
             };
}

@end
