//
//  UserMedalDto.h
//  Minnie
//
//  Created by 栋栋 施 on 2018/11/6.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface UserMedalDetail : MTLModel<MTLJSONSerializing>

@property(nonatomic, assign)NSInteger firstFlag;
@property(nonatomic, assign)NSInteger sencondFlag;
@property(nonatomic, assign)NSInteger thirdFlag;
@property(nonatomic, strong)NSString * medalType;
@property(nonatomic, assign)NSInteger medalId;
@end

@interface UserMedalPics : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong)NSString * firstPicB;
@property(nonatomic, strong)NSString * firstPicD;
@property(nonatomic, strong)NSString * secondPicB;
@property(nonatomic, strong)NSString * secondPicD;
@property(nonatomic, strong)NSString * thirdPicB;
@property(nonatomic, strong)NSString * thirdPicD;
@property(nonatomic, strong)NSString * medalType;
@property(nonatomic, strong)NSString * medalDesc;
@end

@interface MedalFlag : MTLModel<MTLJSONSerializing>

@property(nonatomic,assign)NSInteger metalFlag;

@end

@interface UserMedalDto : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong)NSArray<UserMedalDetail *> * medalDetails;
@property(nonatomic, strong)NSArray<UserMedalPics *> * medalPics;

@end
