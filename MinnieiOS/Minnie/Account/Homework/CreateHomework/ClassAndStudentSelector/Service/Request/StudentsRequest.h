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


@interface StudentZeroTaskRequest : BaseRequest

@end


@interface StudentDetailTaskRequest : BaseRequest

- (instancetype)initWithStudentId:(NSInteger)studentId;

@end
