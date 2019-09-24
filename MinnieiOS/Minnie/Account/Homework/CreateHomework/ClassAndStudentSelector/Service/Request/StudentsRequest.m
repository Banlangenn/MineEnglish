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



#pragma mark - 2.3.9    学生状态修改（教师端）
@interface StudentsChangeStatusRequest ()

@property (nonatomic,assign) NSInteger inClass;
@property (nonatomic,strong) NSArray *studentIds;


@end

@implementation StudentsChangeStatusRequest

- (instancetype)initWithInCalss:(NSInteger)inClass
                     studentIds:(NSArray *)studentIds{
    
    self = [super init];
    if (self != nil) {
        self.inClass = inClass;
        self.studentIds = studentIds;
    }
    return self;
}

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodPOST;
}

- (NSString *)requestUrl {
    
    return [NSString stringWithFormat:@"%@/user/changeClassStatus", ServerProjectName];
}

- (id)requestArgument {

    return @{@"inClass":@(self.inClass),
             @"studentIds":self.studentIds};
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

#pragma mark - 2.13.3    转发问题任务（ipad管理端）
@interface StudentTroubleTaskRequest ()

@property (nonatomic,assign) NSInteger hometaskId;
@property (nonatomic,assign) NSInteger homeworkId;
@property (nonatomic,assign) NSInteger userId;
@property (nonatomic,assign) NSInteger teacherId;
@property (nonatomic,copy) NSString *content;

@end

@implementation StudentTroubleTaskRequest

- (instancetype)initWithHometaskId:(NSInteger)hometaskId
                        homeworkId:(NSInteger)homeworkId
                            userId:(NSInteger)userId
                         teacherId:(NSInteger)teacherId
                           content:(NSString *)content;
{
    self = [super init];
    if (self) {
        self.hometaskId = hometaskId;
        self.homeworkId = homeworkId;
        self.userId = userId;
        self.teacherId = teacherId;
        self.content = content;
    }
    return self;
}

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodPOST;
}

- (NSString *)requestUrl {
    
    return [NSString stringWithFormat:@"%@/teaching/createTroubletask", ServerProjectName];
}


- (id)requestArgument{
    
    return @{@"hometaskId":@(self.hometaskId),
             @"homeworkId":@(self.homeworkId),
             @"userId":@(self.userId),
             @"teacherId":@(self.teacherId),
             @"content":self.content
             };
}
@end

#pragma mark - 2.13.4    问题任务（ipad管理端）
@implementation StudentTroubleTaskListRequest

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    
    return [NSString stringWithFormat:@"%@/teaching/troubletasks", ServerProjectName];
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
