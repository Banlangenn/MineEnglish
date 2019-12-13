//
//  TrialClasssRequest.m
//  MinnieStudent
//
//  Created by yebw on 2018/4/14.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import "TrialClasssRequest.h"

#pragma mark - 2.5.1    获取班级列表（学生端，教师端，ipad端）
@implementation TrialClasssRequest

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/class/classes", ServerProjectName];
}

- (id)requestArgument {
    return @{@"trial":@(1), @"finished":@(0), @"simple":@(1)};
}

@end


#pragma mark - 2.5.8    试听课报名（学生端）
@interface EnrollTrialClassRequest()

@property (nonatomic, assign) NSInteger classId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *grade;
@property (nonatomic, assign) NSInteger gender;

@end

@implementation EnrollTrialClassRequest

- (instancetype)initWithName:(NSString *)name
                       grade:(NSString *)grade
                      gender:(NSInteger)gender {
    self = [super init];
    if (self != nil) {
        _name = name;
        _grade = grade;
        _gender = gender;
    }
    
    return self;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/class/enroll", ServerProjectName];
}

- (id)requestArgument {
    return @{@"nickname":self.name,
             @"grade":self.grade,
             @"gender":@(self.gender)};
}

@end

