//
//  HomeworkService.m
//  X5
//
//  Created by yebw on 2017/12/14.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "HomeworkService.h"
#import "HomeworksRequest.h"
#import "CreateHomeworkRequest.h"
#import "SearchHomeworksRequest.h"
#import "DeleteHomeworksRequest.h"
#import "SendHomeworkRequest.h"
#import "SendHomeworkHistoryRequest.h"
#import "SendWarnRequest.h"
@implementation HomeworkService

+ (BaseRequest *)createHomework:(Homework *)homework callback:(RequestCallback)callback {
   
    CreateHomeworkRequest *request = [[CreateHomeworkRequest alloc] initWithHomework:homework];
    request.callback = callback;
    [request start];
    
    return request;
}

+ (BaseRequest *)deleteHomeworks:(NSArray <NSNumber *> *)homeworkIds
                        callback:(RequestCallback)callback {
    DeleteHomeworksRequest *request = [[DeleteHomeworksRequest alloc] initWithHomeworkIds:homeworkIds];
    
    request.callback = callback;
    
    [request start];
    return request;
}

+ (BaseRequest *)requestHomeworksWithCallback:(RequestCallback)callback {
    HomeworksRequest *request = [[HomeworksRequest alloc] init];
    
    request.objectKey = @"list";
    request.objectClassName = @"Homework";
    
    request.callback = callback;
    
    [request start];
    
    return request;
}

+ (BaseRequest *)requestHomeworksWithNextUrl:(NSString *)nextUrl
                                    callback:(RequestCallback)callback {
    HomeworksRequest *request = [[HomeworksRequest alloc] initWithNextUrl:nextUrl];
    
    request.objectKey = @"list";
    request.objectClassName = @"Homework";
    
    request.callback = callback;
    
    [request start];
    
    return request;
}

+ (BaseRequest *)searchHomeworkWithKeyword:(NSArray<NSString *> *)key
                                   fieldId:(NSInteger)fieldId
                                  callback:(RequestCallback)callback {
    SearchHomeworksRequest *request = [[SearchHomeworksRequest alloc] initWithKeyword:key fileId:fieldId];
    
    request.objectKey = @"list";
    request.objectClassName = @"Homework";
    
    request.callback = callback;
    
    [request start];
    
    return request;
}

+ (BaseRequest *)searchHomeworkWithNextUrl:(NSString *)nextUrl
                               withKeyword:(NSArray<NSString *> *)key
                                   fieldId:(NSInteger)fieldId
                                  callback:(RequestCallback)callback {
    SearchHomeworksRequest *request = [[SearchHomeworksRequest alloc] initWithNextUrl:nextUrl withKeyword:key fileId:fieldId];
    
    request.objectKey = @"list";
    request.objectClassName = @"Homework";
    
    request.callback = callback;
    
    [request start];
    
    return request;
}

+ (BaseRequest *)sendHomeworkIds:(NSArray <NSNumber *> *)homeworkIds
                        classIds:(NSArray <NSNumber *> *)classIds
                      studentIds:(NSArray <NSNumber *> *)studentIds
                       teacherId:(NSInteger)teacherId
                            date:(NSDate *)date
                        callback:(RequestCallback)callback {
    SendHomeworkRequest *request = [[SendHomeworkRequest alloc] initWithHomeworkIds:homeworkIds
                                                                           classIds:classIds
                                                                         studentIds:studentIds
                                                                          teacherId:teacherId date:date];
    
    request.callback = callback;
    
    [request start];
    
    return request;
}

+ (BaseRequest *)requestSendHomeworkHistoryWithCallback:(RequestCallback)callback
{
    SendHomeworkHistoryRequest * request = [[SendHomeworkHistoryRequest alloc] init];
    request.objectKey = @"list";
    request.objectClassName = @"HomeworkSendLog";
    request.callback = callback;
    [request start];
    return request;
}

+ (BaseRequest *)requestSendHomeworkHistoryWithNextUrl:(NSString *)nextUrl callback:(RequestCallback)callback
{
    SendHomeworkHistoryRequest * request = [[SendHomeworkHistoryRequest alloc] initWithNextUrl:nextUrl];
    request.objectKey = @"list";
    request.objectClassName = @"HomeworkSendLog";
    request.callback = callback;
    [request start];
    return request;
}

+ (BaseRequest *)sendWarnForStudent:(NSInteger)studentId callback:(RequestCallback)callback;
{
    SendWarnRequest *request = [[SendWarnRequest alloc] initWithStudent:studentId];
    request.callback = callback;
    [request start];
    return request;
}

#pragma mark - 2.3.2    获取作业详情
+ (BaseRequest *)requestHomeworkDetailWithId:(NSInteger)homeworkId
                                    callback:(RequestCallback)callback{
    
    HomeworkDetailRequest *request = [[HomeworkDetailRequest alloc] initWithHomeworkId:homeworkId];
    request.objectClassName = @"Homework";
    request.callback = callback;
    [request start];
    return request;
}

@end



