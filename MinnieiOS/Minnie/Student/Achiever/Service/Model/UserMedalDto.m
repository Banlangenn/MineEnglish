//
//  UserMedalDto.m
//  Minnie
//
//  Created by 栋栋 施 on 2018/11/6.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import "UserMedalDto.h"

@implementation UserMedalDetail

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
    return @{@"firstFlag":@"firstFlag",
             @"sencondFlag":@"sencondFlag",
             @"thirdFlag":@"thirdFlag",
             @"medalType":@"medalType",
             @"medalId":@"id"
             };
}
@end

@implementation UserMedalPics

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"firstPicB":@"firstPicB",
             @"firstPicD":@"firstPicD",
             @"secondPicB":@"secondPicB",
             @"secondPicD":@"secondPicD",
             @"thirdPicB":@"thirdPicB",
             @"thirdPicD":@"thirdPicD",
             @"medalType":@"medalType",
             @"medalDesc":@"medalDesc"
             };
}
@end


@implementation MedalFlag

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"metalFlag":@"metalFlag",
             };
}

@end


@implementation UserMedalDto

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"medalDetails":@"medalDetails",
             @"medalPics":@"medalPics"
             };
}


+ (NSValueTransformer *)medalDetailsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[UserMedalDetail class]];
}

+ (NSValueTransformer *)medalPicsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[UserMedalPics class]];
}

@end
