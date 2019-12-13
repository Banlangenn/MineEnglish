//
//  TrialClassService.m
//  MinnieStudent
//
//  Created by yebw on 2018/4/14.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import "TrialClassService.h"
#import "TrialClasssRequest.h"

@implementation TrialClassService

+ (BaseRequest *)enrollWithName:(NSString *)name
                             grade:(NSString *)grade
                            gender:(NSInteger)gender
                          callback:(RequestCallback)callback {
    EnrollTrialClassRequest *request = [[EnrollTrialClassRequest alloc] initWithName:name grade:grade gender:gender];
    
    [request setCallback:callback];
    [request start];
    
    return request;
}

+ (BaseRequest *)requestTrialClassesWithCallback:(RequestCallback)callback {
    TrialClasssRequest *request = [[TrialClasssRequest alloc] init];
    
    [request setObjectKey:@"list"];
    [request setObjectClassName:@"Clazz"];
    [request setCallback:callback];
    [request start];
    
    return request;
}

@end
