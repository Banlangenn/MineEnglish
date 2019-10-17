//
//  AwardsService.m
//  Minnie
//
//  Created by songzhen on 2019/8/22.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "AwardsRequest.h"
#import "AwardsService.h"

@implementation AwardsService

+ (BaseRequest *)requestAwardsWithCallback:(RequestCallback)callback {
    AwardsRequest *request = [[AwardsRequest alloc] init];
    
    request.objectKey = @"list";
    request.objectClassName = @"Award";
    
    [request setCallback:callback];
    [request start];
    
    return request;
}


+ (BaseRequest *)addAward:(NSDictionary *)awardInfo
                 callback:(RequestCallback)callback {
    AddAwardRequest *request = [[AddAwardRequest alloc] initWithInfos:awardInfo];
    
    [request setCallback:callback];
    [request start];
    
    return request;
}


+ (BaseRequest *)exchangeAwardWithId:(NSUInteger)awardId callback:(RequestCallback)callback {
    ExchangeAwardRequest *request = [[ExchangeAwardRequest alloc] initWithId:awardId];
    
    [request setCallback:callback];
    [request start];
    
    return request;
}



+ (BaseRequest *)giveAwardWithId:(NSUInteger)requestId callback:(RequestCallback)callback {
    GiveAwardRequest *request = [[GiveAwardRequest alloc] initWithId:requestId];
    
    [request setCallback:callback];
    [request start];
    
    return request;
}

+ (BaseRequest *)requestExchangeRequestsWithState:(BOOL)exchanged
                                         callback:(RequestCallback)callback {
    ExchangeRequestsRequest *request = [[ExchangeRequestsRequest alloc] initWithExchangeState:(exchanged?1:0)];
    
    request.objectKey = @"list";
    request.objectClassName = @"ExchangeRecord";
    
    [request setCallback:callback];
    [request start];
    
    return request;
}

+ (BaseRequest *)requestExchangeRecordsWithCallback:(RequestCallback)callback {
   
    ExchangeRecordsStudentRequest *request = [[ExchangeRecordsStudentRequest alloc] init];
    
    request.objectKey = @"list";
    request.objectClassName = @"ExchangeRecord";
    
    [request setCallback:callback];
    [request start];
    
    return request;
}


+ (BaseRequest *)requestExchangeRequestsWithMoreUrl:(NSString *)moreUrl
                                           callback:(RequestCallback)callback {
    ExchangeRequestsRequest *request = [[ExchangeRequestsRequest alloc] initWithNextUrl:moreUrl];
    
    request.objectKey = @"list";
    request.objectClassName = @"ExchangeRecord";
    
    [request setCallback:callback];
    [request start];
    
    return request;
}

+ (BaseRequest *)requestUnexchangedRequestCountWithCallback:(RequestCallback)callback {
    UnexchangedRequestCountRequest *request = [[UnexchangedRequestCountRequest alloc] init];
    
    [request setCallback:callback];
    [request start];
    
    return request;
}


+ (BaseRequest *)requestexchangeAwardByClassWithState:(NSInteger)state
                                              nextUrl:(NSString *_Nullable)nextUrl
                                             callback:(RequestCallback)callback{
    ExchangeAwardListRequest *request = [[ExchangeAwardListRequest alloc] initWithState:state nextUrl:nextUrl];
    request.objectKey = @"list";
    request.objectClassName = @"ExchangeAwardListRecord";
    [request setCallback:callback];
    [request start];
    return request;
}


@end
