//
//  HomeworkService.h
//  X5
//
//  Created by yebw on 2017/12/14.
//  Copyright © 2017年 mfox. All rights reserved.
// 作业管理相关接口

#import <Foundation/Foundation.h>
#import "Homework.h"
#import "Teacher.h"
#import "User.h"
#import "Result.h"
#import "BaseRequest.h"

@interface HomeworkService : NSObject

// 创建作业
+ (BaseRequest *)createHomework:(Homework *)homework
                       callback:(RequestCallback)callback;

+ (BaseRequest *)deleteHomeworks:(NSArray <NSNumber *> *)homeworkIds
                        callback:(RequestCallback)callback;

// 作业管理 获取作业列表
+ (BaseRequest *)requestHomeworksWithCallback:(RequestCallback)callback;

+ (BaseRequest *)requestHomeworksWithNextUrl:(NSString *)nextUrl
                                    callback:(RequestCallback)callback;

// 搜索作业
+ (BaseRequest *)searchHomeworkWithKeyword:(NSArray<NSString *> *)key
                                     fieldId:(NSInteger)fieldId
                                  callback:(RequestCallback)callback;

+ (BaseRequest *)searchHomeworkWithNextUrl:(NSString *)nextUrl
                               withKeyword:(NSArray<NSString *> *)key
                                   fieldId:(NSInteger)fieldId
                                  callback:(RequestCallback)callback;

+ (BaseRequest *)sendHomeworkIds:(NSArray <NSNumber *> *)homeworkIds
                        classIds:(NSArray <NSNumber *> *)classIds
                      studentIds:(NSArray <NSNumber *> *)studentIds
                       teacherId:(NSInteger)teacherId
                            date:(NSDate *)date
                        callback:(RequestCallback)callback;

//作业发送记录
+ (BaseRequest *)requestSendHomeworkHistoryWithCallback:(RequestCallback)callback;

+ (BaseRequest *)requestSendHomeworkHistoryWithNextUrl:(NSString *)nextUrl callback:(RequestCallback)callback;

//增加警告
+ (BaseRequest *)sendWarnForStudent:(NSInteger)studentId callback:(RequestCallback)callback;


#pragma mark - 2.3.2    获取作业详情
+ (BaseRequest *)requestHomeworkDetailWithId:(NSInteger)homeworkId
                                    callback:(RequestCallback)callback;

@end
