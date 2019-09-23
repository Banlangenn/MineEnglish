//
//  StudentsRequest.h
//  X5Teacher
//
//  Created by yebw on 2018/1/24.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "BaseRequest.h"

@interface StudentsRequest : BaseRequest

// finish表示毕业的
- (instancetype)initWithFinishState:(BOOL)finished;

- (instancetype)initWithClassState:(NSInteger)inClass;

- (instancetype)initWithNextUrl:(NSString *)nextUrl;

@end


@interface StudentsByTeacherRequest : BaseRequest

@end



@interface StudentsByClassRequest : BaseRequest

@end

#pragma mark - 2.13.2    0分动态（ipad管理端）
@interface StudentZeroTaskRequest : BaseRequest

@end

#pragma mark - 2.13.3    转发问题任务（ipad管理端）
@interface StudentTroubleTaskRequest : BaseRequest

- (instancetype)initWithHometaskId:(NSInteger)hometaskId
                        homeworkId:(NSInteger)homeworkId
                            userId:(NSInteger)userId
                         teacherId:(NSInteger)teacherId
                           content:(NSString *)content;

@end

#pragma mark - 2.13.4    问题任务（ipad管理端）
@interface StudentTroubleTaskListRequest : BaseRequest
@end


@interface StudentDetailTaskRequest : BaseRequest

- (instancetype)initWithStudentId:(NSInteger)studentId;

@end
