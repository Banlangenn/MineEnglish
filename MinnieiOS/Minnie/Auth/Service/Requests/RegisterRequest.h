//
//  RegisterRequest.h
// X5
//
//  Created by yebw on 2017/8/23.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "BaseRequest.h"
#import "Result.h"

@interface RegisterRequest : BaseRequest

- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber
                           password:(NSString *)password
                               code:(NSString *)code;

@end
