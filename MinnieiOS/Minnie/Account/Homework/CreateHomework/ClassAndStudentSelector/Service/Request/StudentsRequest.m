//
//  StudentsRequest.m
//  X5Teacher
//
//  Created by yebw on 2018/1/7.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "StudentsRequest.h"

@interface StudentsRequest()

@property(nonatomic, assign) BOOL finished;
//0表示未入学；1表示已加入到班级；-1表示待处理
@property(nonatomic, assign) NSInteger inClass;
@property(nonatomic, assign) BOOL needsClassState;
@property(nonatomic, copy) NSString *nextUrl;

@end

@implementation StudentsRequest

- (instancetype)initWithFinishState:(BOOL)finished {
    self = [super init];
    if (self != nil) {
        _finished = finished;
        _needsClassState = NO;
    }
    
    return self;
}

- (instancetype)initWithClassState:(NSInteger)inClass {
    self = [super init];
    if (self != nil) {
        _finished = 0;
        _inClass = inClass;
        _needsClassState = YES;
    }

    return self;
}

- (instancetype)initWithNextUrl:(NSString *)nextUrl {
    self = [super init];
    if (self != nil) {
        _nextUrl = nextUrl;
    }
    
    return self;
}

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    if (self.nextUrl.length > 0) {
        return self.nextUrl;
    }

    return [NSString stringWithFormat:@"%@/students", ServerProjectName];
}

- (id)requestArgument {
    if (self.nextUrl.length > 0) {
        return nil;
    }

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"finished"] = self.finished?@(1):@(0);
    
    if (self.needsClassState) {
        dict[@"inClass"] = @(self.inClass);
    }

    return dict;
}

@end


@implementation StudentsByTeacherRequest

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    
    return [NSString stringWithFormat:@"%@/teaching/students", ServerProjectName];
}

@end



@implementation StudentsByClassRequest

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    
    return [NSString stringWithFormat:@"%@/teaching/studentsByClass", ServerProjectName];
}

@end


@implementation StudentZeroTaskRequest


- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    
    return [NSString stringWithFormat:@"%@/teaching/zerotasks", ServerProjectName];
}


@end




@interface StudentDetailTaskRequest ()

@property (nonatomic,assign) NSInteger studentId;

@end


@implementation StudentDetailTaskRequest

- (instancetype)initWithStudentId:(NSInteger)studentId{
    
    self = [super init];
    if (self != nil) {
        _studentId = studentId;
    }
    return self;
}

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    
    return [NSString stringWithFormat:@"%@/teaching/studentDetail", ServerProjectName];
}

- (id)requestArgument{
    
    return @{@"studentId":@(self.studentId)};
}


@end
