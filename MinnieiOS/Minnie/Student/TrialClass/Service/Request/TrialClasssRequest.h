//
//  TrialClasssRequest.h
//  MinnieStudent
//
//  Created by yebw on 2018/4/14.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import "BaseRequest.h"

#pragma mark - 2.5.1    获取班级列表（学生端，教师端，ipad端）
@interface TrialClasssRequest : BaseRequest

@end


#pragma mark - 2.5.8    试听课报名（学生端）
@interface EnrollTrialClassRequest : BaseRequest

- (instancetype)initWithName:(NSString *)name
                       grade:(NSString *)grade
                      gender:(NSInteger)gender;

@end
