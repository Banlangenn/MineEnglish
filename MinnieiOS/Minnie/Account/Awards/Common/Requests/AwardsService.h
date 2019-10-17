//
//  AwardsService.h
//  Minnie
//
//  Created by songzhen on 2019/8/22.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "Award.h"
#import "Result.h"
#import "BaseRequest.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AwardsService : NSObject

#pragma mark - 2.7.1    获取奖品列表（学生端，教师端）
+ (BaseRequest *)requestAwardsWithCallback:(RequestCallback)callback;


#pragma mark - 2.7.5    教师给学生兑换礼物（教师端）
+ (BaseRequest *)giveAwardWithId:(NSUInteger)requestId callback:(RequestCallback)callback;


#pragma mark - 2.7.2    新建/编辑奖品（教师端）
+ (BaseRequest *)addAward:(NSDictionary *)awardInfo callback:(RequestCallback)callback;


#pragma mark - 2.7.3    学生请求兑换奖品（学生端）
+ (BaseRequest *)exchangeAwardWithId:(NSUInteger)award callback:(RequestCallback)callback;


#pragma mark - 2.7.4    兑换礼物记录列表（学生端，教师端）
+ (BaseRequest *)requestExchangeRequestsWithState:(BOOL)exchanged
                                         callback:(RequestCallback)callback;

+ (BaseRequest *)requestExchangeRequestsWithMoreUrl:(NSString *)moreUrl
                                           callback:(RequestCallback)callback;

// 学生端
+ (BaseRequest *)requestExchangeRecordsWithCallback:(RequestCallback)callback;


#pragma mark - 2.7.6    获取未兑换礼物
+ (BaseRequest *)requestUnexchangedRequestCountWithCallback:(RequestCallback)callback;



#pragma mark - 2.15.1    获取礼品兑换列表（ipad管理端）
// 获取礼品兑换列表(管理端)  state 0表示未兑换，1表示已兑换
+ (BaseRequest *)requestexchangeAwardByClassWithState:(NSInteger)state
                                              nextUrl:(NSString *_Nullable)nextUrl
                                             callback:(RequestCallback)callback;




@end

NS_ASSUME_NONNULL_END
