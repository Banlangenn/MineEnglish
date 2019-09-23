//
//  StudentsService.m
//  X5Teacher
//
//  Created by yebw on 2018/2/4.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "StudentService.h"
#import "StudentsRequest.h"
#import "StudentRequest.h"

@implementation StudentService

+ (BaseRequest *)requestStudentsWithFinishState:(BOOL)finished
                                       callback:(RequestCallback)callback {
    StudentsRequest *request = [[StudentsRequest alloc] initWithFinishState:finished];
    
    request.objectKey = @"list";
    request.objectClassName = @"User";
    request.callback = callback;
    [request start];
    
    return request;
}

+ (BaseRequest *)requestStudentsWithClassState:(NSInteger)inClass
                                      callback:(RequestCallback)callback {
    StudentsRequest *request = [[StudentsRequest alloc] initWithClassState:inClass];
    
    request.objectKey = @"list";
    request.objectClassName = @"User";
    request.callback = callback;
    [request start];
    
    return request;
}


+ (BaseRequest *)requestStudentsWithNextUrl:(NSString *)nextUrl
                                   callback:(RequestCallback)callback {
    StudentsRequest *request = [[StudentsRequest alloc] initWithNextUrl:nextUrl];
    
    request.objectKey = @"list";
    request.objectClassName = @"User";
    request.callback = callback;
    [request start];
    
    return request;
}

+ (BaseRequest *)requestStudentWithPhoneNumber:(NSString *)phoneNumber
                                      callback:(RequestCallback)callback {
    StudentRequest *request = [[StudentRequest alloc] initWithPhoneNumber:phoneNumber];
    
    request.objectClassName = @"Student";
    request.callback = callback;
    [request start];
    
    return request;
}


#pragma mark - 2.13.4    学生列表（ipad管理端）(当前老师可见的所有学生)
+ (BaseRequest *)requestStudentsByTeacherCallback:(RequestCallback)callback{
    
    StudentsByTeacherRequest *request = [[StudentsByTeacherRequest alloc] init];
    request.objectKey = @"list";
    request.objectClassName = @"StudentsByName";
    request.callback = callback;
    [request start];
    
    return request;
}

+ (BaseRequest *)requestStudentLisByClasstWithCallback:(RequestCallback)callback{
    
    StudentsByClassRequest *request = [[StudentsByClassRequest alloc] init];
    request.objectKey = @"list";
    request.objectClassName = @"StudentsByClass";
    request.callback = callback;
    [request start];
    
    return request;
}


+ (BaseRequest *)requestStudentZeroTaskCallback:(RequestCallback)callback{
   
    StudentZeroTaskRequest *request = [[StudentZeroTaskRequest alloc] init];
    request.objectKey = @"list";
    request.objectClassName = @"StudentZeroTask";
    request.callback = callback;
    [request start];
    
    return request;
}


+ (BaseRequest *)requestStudentDetailTaskWithStuId:(NSInteger)stuId
                                          callback:(RequestCallback)callback{
    
    StudentDetailTaskRequest *request = [[StudentDetailTaskRequest alloc] initWithStudentId:stuId];
    request.objectClassName = @"StudentDetail";
    request.callback = callback;
    [request start];
    
    return request;
}
@end


