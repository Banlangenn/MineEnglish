//
//  AwardsRequest.h
//  X5
//
//  Created by yebw on 2017/10/19.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "BaseRequest.h"
#pragma mark - 2.7.1    获取奖品列表（学生端，教师端）
@interface AwardsRequest : BaseRequest

@end


#pragma mark - 2.7.2    新建/编辑奖品（教师端）
@interface AddAwardRequest : BaseRequest

- (instancetype)initWithInfos:(NSDictionary *)infos;

@end



#pragma mark - 2.7.3    学生请求兑换奖品（学生端）
@interface ExchangeAwardRequest : BaseRequest

- (instancetype)initWithId:(NSUInteger)awardId;

@end



#pragma mark - 2.7.4    兑换礼物记录列表（教师端）
@interface ExchangeRequestsRequest : BaseRequest

- (instancetype)initWithExchangeState:(NSInteger)state;

- (instancetype)initWithNextUrl:(NSString *)nextUrl;

@end


#pragma mark - 2.7.4    兑换礼物记录列表（学生端）
@interface ExchangeRecordsStudentRequest : BaseRequest

@end



#pragma mark - 2.7.5    教师给学生兑换礼物（教师端）
@interface GiveAwardRequest : BaseRequest

- (instancetype)initWithId:(NSUInteger)awardRequestId;

@end


#pragma mark -
@interface UnexchangedRequestCountRequest : BaseRequest

@end


#pragma mark - 2.15.1    获取礼品兑换列表（ipad管理端）
@interface ExchangeAwardListRequest : BaseRequest

- (instancetype)initWithState:(NSUInteger)state nextUrl:(NSString *)nextUrl;

@end


