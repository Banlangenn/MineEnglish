//
//  AchieverRequest.h
//  MinnieStudent
//
//  Created by songzhen on 2019/8/21.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "BaseRequest.h"
#import "UserMedalDto.h"

NS_ASSUME_NONNULL_BEGIN

@interface AchieverRequest : BaseRequest

@end


#pragma mark - 2.9.1    获取勋章通知小红点
@interface AchieverNoticeFlagRequest : BaseRequest
@end


#pragma mark - 2.9.2    更新勋章通知小红点
@interface AchieverUpdateFlagRequest : BaseRequest
@end


#pragma mark - 2.9.3    用户勋章详情
@interface AchieverMedalDetailRequest : BaseRequest
@end


#pragma mark - 2.9.4    更新用户勋章（领取勋章）
@interface AchieverUpdateMedalDetailRequest : BaseRequest

- (instancetype)initWithMedalData:(UserMedalDetail *)data atMedalIndex:(NSInteger)index;

@end


NS_ASSUME_NONNULL_END
