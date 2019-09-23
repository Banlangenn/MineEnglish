//
//  StudentsService.h
//  X5Teacher
//
//  Created by yebw on 2018/2/4.
//  Copyright © 2018年 netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseRequest.h"
#import "Result.h"

@interface StudentService : NSObject

#pragma mark - 2.3.7    获取所有学生列表（教师端）
// 获取学生列表
+ (BaseRequest *)requestStudentsWithFinishState:(BOOL)finished
                                       callback:(RequestCallback)callback;

+ (BaseRequest *)requestStudentsWithClassState:(NSInteger)inClass
                                      callback:(RequestCallback)callback;

+ (BaseRequest *)requestStudentsWithNextUrl:(NSString *)nextUrl
                                   callback:(RequestCallback)callback;

+ (BaseRequest *)requestStudentWithPhoneNumber:(NSString *)phoneNumber
                                      callback:(RequestCallback)callback;

#pragma mark - 2.13.4    学生列表（ipad管理端）(当前老师可见的所有学生)
+ (BaseRequest *)requestStudentsByTeacherCallback:(RequestCallback)callback;


// 按班级返回学生列表（ipad管理端）
+ (BaseRequest *)requestStudentLisByClasstWithCallback:(RequestCallback)callback;


#pragma mark -  2.13.2    0分动态（ipad管理端）
+ (BaseRequest *)requestStudentZeroTaskCallback:(RequestCallback)callback;

#pragma mark - 2.13.3    转发问题任务（ipad管理端）
+ (BaseRequest *)requestTroubleTaskWithHomeaskId:(NSInteger)hometaskId
                                      homeworkId:(NSInteger)homeworkId
                                          userId:(NSInteger)userId
                                       teacherId:(NSInteger)teacherId
                                         content:(NSString *)content
                                        callback:(RequestCallback)callback;

#pragma mark - 2.13.4    问题任务（ipad管理端）
+ (BaseRequest *)requestTroubleTaskListWithCallback:(RequestCallback)callback;


//学生详情（ipad管理端）
+ (BaseRequest *)requestStudentDetailTaskWithStuId:(NSInteger)stuId
                                          callback:(RequestCallback)callback;

@end


