//
//  AchieverRequest.m
//  MinnieStudent
//
//  Created by songzhen on 2019/8/21.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "AchieverRequest.h"

@implementation AchieverRequest

@end



#pragma mark - 2.9.1    获取勋章通知小红点
@implementation AchieverNoticeFlagRequest

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/medal/getMedalNoticeFlag", ServerProjectName];
}

@end


#pragma mark - 2.9.2    更新勋章通知小红点
@implementation AchieverUpdateFlagRequest

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/medal/updateMedalNoticeFlag", ServerProjectName];
}

@end


#pragma mark - 2.9.3    用户勋章详情
@implementation AchieverMedalDetailRequest

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/medal/getMedalDetail", ServerProjectName];
}

@end


#pragma mark - 2.9.4    更新用户勋章（领取勋章）
@interface AchieverUpdateMedalDetailRequest()

@property(nonatomic,strong)UserMedalDetail * mData;
@property(nonatomic,assign)NSInteger mIndex; //1 2 3代表铜银金
@end

@implementation AchieverUpdateMedalDetailRequest

- (instancetype)initWithMedalData:(UserMedalDetail *)data atMedalIndex:(NSInteger)index{
    self = [super init];
    if (self != nil) {
        self.mData = data;
        self.mIndex = index;
    }
    return self;
}

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodPOST;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/medal/updateMedalFlag", ServerProjectName];
}

- (id)requestArgument {
    return @{@"id":@(self.mData.medalId),
             @"firstFlag":@(self.mData.firstFlag),
             @"sencondFlag":@(self.mData.sencondFlag),
             @"thirdFlag":@(self.mData.thirdFlag),
             @"medalType":self.mData.medalType,
             @"changeFlag":@(self.mIndex)
             };
}

@end
