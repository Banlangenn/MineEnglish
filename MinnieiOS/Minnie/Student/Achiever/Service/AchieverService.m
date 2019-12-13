//
//  AchieverService.m
//  Minnie
//
//  Created by 栋栋 施 on 2018/11/6.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import "AchieverRequest.h"
#import "AchieverService.h"

@implementation AchieverService

//获取勋章小红点
+ (BaseRequest *)requestMedalNoticeFlagWithCallback:(RequestCallback)callback
{
    AchieverNoticeFlagRequest * request = [[AchieverNoticeFlagRequest alloc] init];
    request.objectClassName = @"MedalFlag";
    [request setCallback:callback];
    [request start];
    return request;
}

//更新勋章小红点
+ (BaseRequest *)updateMedalNoticeFlagWithCallback:(RequestCallback)callback
{
    AchieverUpdateFlagRequest * request = [[AchieverUpdateFlagRequest alloc] init];
    [request setCallback:callback];
    [request start];
    return request;
}


//获取勋章详情
+ (BaseRequest *)requestMedalDetailWithCallback:(RequestCallback)callback
{
    AchieverMedalDetailRequest *request = [[AchieverMedalDetailRequest alloc] init];
//    [request setObjectKey:@"list"];
    [request setObjectClassName:@"UserMedalDto"];
    [request setCallback:callback];
    [request start];
    
    return request;
}

//领取勋章
+ (BaseRequest *)updateMedalWithMedalData:(UserMedalDetail *)data atMedalIndex:(NSInteger)index callback:(RequestCallback)callback
{
    AchieverUpdateMedalDetailRequest * request = [[AchieverUpdateMedalDetailRequest alloc] initWithMedalData:data atMedalIndex:index];
    [request setCallback:callback];
    [request start];
    return request;
}
@end
