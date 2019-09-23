//
//  Clazz.m
//  X5
//
//  Created by yebw on 2017/9/17.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "Clazz.h"

@implementation Clazz

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"classId":@"id",
             @"name":@"name",
             @"location":@"location",
             @"startTime":@"startTime",
             @"endTime":@"endTime",
             @"trial":@"trial",
//             @"maxStudentsCount":@"maxStudentsCount",
             @"studentsCount":@"studentsCount",
             @"circleCount":@"goodHomeworksCount",
             @"homeworksCount":@"commitedHomeworksCount",
             @"teacher":@"teacher",
             @"uncorrectedHomeworksCount":@"uncorrectedHomeworksCount",
             @"dates":@"schedule",
             @"students":@"students",
             @"isFinished":@"finished",
             @"classLevel":@"level",
             @"commitedHomeworksCount":@"commitedHomeworksCount"
             };
}

+ (NSValueTransformer *)studentsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[User class]];
}

+ (NSValueTransformer *)teacherJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[Teacher class]];
}

- (long long)nextClassTime {
    NSNumber *d = nil;
    for (NSNumber *date in self.dates) {
        if ([date longLongValue] > [[NSDate date] timeIntervalSince1970]*1000) {
            d = date;
            break;
        }
    }

    return [d longLongValue];
}

- (NSDictionary *)dictionaryForUpload {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (self.classId > 0) {
        dict[@"id"] = @(self.classId);
    }
    dict[@"name"] = self.name;
    dict[@"location"] = self.location;
    dict[@"startTime"] = self.startTime;
    dict[@"endTime"] = self.endTime;
    dict[@"trial"] = @(self.trial);
//    dict[@"maxStudentsCount"] = @(self.maxStudentsCount);
    dict[@"level"] = @(self.classLevel);
    dict[@"commitedHomeworksCount"] = @(self.commitedHomeworksCount);
    
    NSMutableDictionary *teacherDict = [NSMutableDictionary dictionary];
    teacherDict[@"id"] = @(self.teacher.userId);
    teacherDict[@"nickname"] = self.teacher.nickname;
    if (self.teacher.avatarUrl != nil) {
        teacherDict[@"avatarUrl"] = self.teacher.avatarUrl;
    }
    dict[@"teacher"] = teacherDict;
    dict[@"schedule"] = self.dates;
    dict[@"finished"] = self.isFinished?@(1):@(0);
    
    NSMutableArray *students = nil;
    for (User *student in self.students) {
        if (students == nil) {
            students = [NSMutableArray array];
            
            dict[@"students"] = students;
        }
    
        NSMutableDictionary *studentDict = [NSMutableDictionary dictionary];
        studentDict[@"id"] = @(student.userId);
        studentDict[@"nickname"] = student.nickname;
        if (self.teacher.avatarUrl != nil) {
            studentDict[@"avatarUrl"] = student.avatarUrl;
        }
        
        [students addObject:studentDict];
    }
    
    return dict;
}

@end

