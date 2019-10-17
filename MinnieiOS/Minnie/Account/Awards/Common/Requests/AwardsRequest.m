//
//  AwardsRequest.m
//  X5
//
//  Created by yebw on 2017/10/19.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "AwardsRequest.h"

#pragma mark - 2.7.1    获取奖品列表（学生端，教师端）
@implementation AwardsRequest

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/award/awards", ServerProjectName];
}

@end


#pragma mark - 2.7.2    新建/编辑奖品（教师端）
@interface AddAwardRequest()

@property (nonatomic, strong) NSDictionary *infos;

@end

@implementation AddAwardRequest

- (instancetype)initWithInfos:(NSDictionary *)infos {
    self = [super init];
    if (self != nil) {
        _infos = infos;
    }
    
    return self;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/award/create", ServerProjectName];
}

- (id)requestArgument {
    return self.infos;
}

@end



#pragma mark - 2.7.3    学生请求兑换奖品（学生端）
@interface ExchangeAwardRequest()

@property (nonatomic, assign) NSUInteger awardId;

@end

@implementation ExchangeAwardRequest

- (instancetype)initWithId:(NSUInteger)awardId {
    self = [super init];
    if (self != nil) {
        self.awardId = awardId;
    }
    
    return self;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/award/exchange", ServerProjectName];
}

- (id)requestArgument {
    return @{@"id":@(self.awardId), @"count":@(1)};
}

@end



#pragma mark - 2.7.4    兑换礼物记录列表（学生端，教师端）
@interface ExchangeRequestsRequest()

@property (nonatomic, assign) BOOL exchangeState;
@property (nonatomic, copy) NSString *nextUrl;

@end

@implementation ExchangeRequestsRequest

- (instancetype)initWithExchangeState:(NSInteger)state {
    self = [super init];
    if (self != nil) {
        _exchangeState = state;
    }
    
    return self;
}

- (instancetype)initWithNextUrl:(NSString *)nextUrl {
    self = [super init];
    if (self != nil) {
        _nextUrl = nextUrl;
    }
    
    return self;
}

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    if (self.nextUrl != nil) {
        return self.nextUrl;
    }
    
    return [NSString stringWithFormat:@"%@/award/exchangeRequestRecords", ServerProjectName];
}

- (id)requestArgument {
    if (self.nextUrl != nil) {
        return nil;
    }
    
    return @{@"state":@(self.exchangeState?1:0)};
}

@end

#pragma mark - 2.7.4    兑换礼物记录列表（学生端）
@implementation ExchangeRecordsStudentRequest

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/award/exchangeRequestRecords", ServerProjectName];
}

@end


#pragma mark - 2.7.5    教师给学生兑换礼物（教师端）
@interface GiveAwardRequest()

@property (nonatomic, assign) NSUInteger awardRequestId;

@end

@implementation GiveAwardRequest

- (instancetype)initWithId:(NSUInteger)awardRequestId {
    self = [super init];
    if (self != nil) {
        self.awardRequestId = awardRequestId;
    }
    
    return self;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/award/giveAward", ServerProjectName];
}

- (id)requestArgument {
    return @{@"id":@(self.awardRequestId)};
}

@end


#pragma mark -
@implementation UnexchangedRequestCountRequest

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/award/unexchangedOrdersCount", ServerProjectName];
}

@end


#pragma mark - 2.15.1    获取礼品兑换列表（ipad管理端）
@interface ExchangeAwardListRequest()

@property (nonatomic, assign) NSUInteger state;
@property (nonatomic, copy) NSString * nextUrl;

@end

@implementation ExchangeAwardListRequest

- (instancetype)initWithState:(NSUInteger)state nextUrl:(NSString *)nextUrl{
    
    self = [super init];
    if (self != nil) {
        
        self.state = state;
        self.nextUrl = nextUrl;
    }
    return self;
    
}
- (id)requestArgument {
    return @{@"state":@(self.state)};
}

- (YTKRequestMethod)requestMethod{
    
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
  
    if (self.nextUrl.length > 0) {

        return [NSString stringWithFormat:@"%@%@", ServerProjectName,self.nextUrl];
    } else {

        return [NSString stringWithFormat:@"%@/award/exchangeAwardList", ServerProjectName];
    }
}

@end
