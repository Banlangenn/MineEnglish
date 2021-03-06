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

+ (BaseRequest *)searchHomeworkWithKeyword:(NSString *)key callback:(RequestCallback)callback {
    SearchHomeworksRequest *request = [[SearchHomeworksRequest alloc] initWithKeyword:key];
    
    request.objectKey = @"list";
    request.objectClassName = @"Homework";
    
    request.callback = callback;
    
    [request start];
    
    return request;
}

+ (BaseRequest *)searchHomeworkWithNextUrl:(NSString *)nextUrl callback:(RequestCallback)callback {
    SearchHomeworksRequest *request = [[SearchHomeworksRequest alloc] initWithNextUrl:nextUrl];
    
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

@end



