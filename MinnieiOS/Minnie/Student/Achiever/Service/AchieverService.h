//
//  AchieverService.h
//  Minnie
//
//  Created by 栋栋 施 on 2018/11/6.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseRequest.h"
#import "Result.h"
#import "UserMedalDto.h"
@interface AchieverService : NSObject

//获取勋章小红点
+ (BaseRequest *)requestMedalNoticeFlagWithCallback:(RequestCallback)callback;

//更新勋章小红点
+ (BaseRequest *)updateMedalNoticeFlagWithCallback:(RequestCallback)callback;

//获取勋章详情
+ (BaseRequest *)requestMedalDetailWithCallback:(RequestCallback)callback;

//领取勋章
+ (BaseRequest *)updateMedalWithMedalData:(UserMedalDetail *)data atMedalIndex:(NSInteger)index callback:(RequestCallback)callback;

@end
