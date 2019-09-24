//
//  SearchHomeworksRequest.h
//  X5Teacher
//
//  Created by yebw on 2018/2/4.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "BaseRequest.h"

#pragma mark - 2.3.3    多标签搜索作业（教师端）
@interface SearchHomeworksRequest : BaseRequest
// 二级目录id，如果所有为0
- (instancetype)initWithKeyword:(NSArray<NSString *> *)keyword fileId:(NSInteger)fileId;

- (instancetype)initWithNextUrl:(NSString *)nextUrl
                    withKeyword:(NSArray<NSString *> *)keyword
                         fileId:(NSInteger)fileId;

@end

#pragma mark - 2.3.2    获取作业详情
@interface HomeworkDetailRequest : BaseRequest

- (instancetype)initWithHomeworkId:(NSInteger)homeworkId;

@end

