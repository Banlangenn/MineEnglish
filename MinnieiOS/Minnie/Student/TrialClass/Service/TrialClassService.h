//
//  TrialClassService.h
//  MinnieStudent
//
//  Created by yebw on 2018/4/14.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseRequest.h"
#import "Result.h"

@interface TrialClassService : NSObject

+ (BaseRequest *)enrollWithName:(NSString *)name
                          grade:(NSString *)grade
                         gender:(NSInteger)gender
                       callback:(RequestCallback)callback;

+ (BaseRequest *)requestTrialClassesWithCallback:(RequestCallback)callback;

@end

