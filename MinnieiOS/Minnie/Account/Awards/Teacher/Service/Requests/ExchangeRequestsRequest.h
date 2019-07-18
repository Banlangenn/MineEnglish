//
//  ExchangeRequestsRequest.h
//  X5
//
//  Created by yebw on 2017/10/19.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "BaseRequest.h"

// 请求兑换记录
@interface ExchangeRequestsRequest : BaseRequest

- (instancetype)initWithExchangeState:(NSInteger)state;

- (instancetype)initWithNextUrl:(NSString *)nextUrl;

@end



@interface ExchangeAwardListRequest : BaseRequest

- (instancetype)initWithState:(NSUInteger)state;

@end

