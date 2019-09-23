//
//  BaseRequest.m
// X5
//
//  Created by yebw on 2017/8/23.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "BaseRequest.h"
#import "Error.h"
#import "Result.h"
#import <Mantle/Mantle.h>
#import "Constants.h"

static NSString *accessToken = nil;

@implementation BaseRequest

- (YTKRequestSerializerType)requestSerializerType {
    return YTKRequestSerializerTypeJSON;
}

- (YTKResponseSerializerType)responseSerializerType {
    return YTKResponseSerializerTypeJSON;
}

- (YTKRequestMethod)requestMethod {
    if (USING_MOCK_DATA) {
        return YTKRequestMethodGET;
    }
    
    return YTKRequestMethodPOST;
}

- (NSTimeInterval)requestTimeoutInterval {
    return 15.f;
}

+ (void)setToken:(NSString *)token {
    NSLog(@"token:::: \n%@",token);
    accessToken = token;
}

- (BOOL)authorizationHeaderRequired {
    return YES;
}

- (Result *)parseResponse:(NSError **)error {
    Result *result = nil;
    NSError *err = nil;
    
    do {
        err = [Error errorWithResponseObject:self.responseObject];
        if (err != nil) {
            *error = err;
            break;
        }
        
        NSDictionary *dict = (NSDictionary *)(self.responseObject);
        NSObject *userInfo = dict[@"data"];
        
        result = [self parseResponseUserInfo:userInfo error:&err];
        if (result != nil || err != nil) {
            *error = err;
            break;
        }

        if (self.objectClassName.length > 0) {
            Class objectClass = NSClassFromString(self.objectClassName);
            if ([objectClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
                if ([userInfo isKindOfClass:[NSArray class]]) {
                    NSArray *items = [MTLJSONAdapter modelsOfClass:[objectClass class]
                                                     fromJSONArray:(NSArray *)(userInfo)
                                                             error:nil];
                    
                    result = [[Result alloc] init];
                    result.userInfo = items;
                } else if ([userInfo isKindOfClass:[NSDictionary class]]) {
                    NSObject *next = ((NSDictionary *)userInfo)[@"next"];
                    if (self.objectKey.length > 0) {
                        userInfo = ((NSDictionary *)userInfo)[self.objectKey];
                    }
                    
                    if ([userInfo isKindOfClass:[NSArray class]]) {
                        NSString *nextUrl = nil;
                        if ([next isKindOfClass:[NSString class]]) {
                            nextUrl = (NSString *)next;
                        }
                        
                        NSError *error1 = nil;
                        NSArray *items = [MTLJSONAdapter modelsOfClass:[objectClass class]
                                                         fromJSONArray:(NSArray *)(userInfo)
                                                                 error:&error1];
                        if (items == nil) {
                            items = @[];
                        }
                        
                        result = [[Result alloc] init];
                        if (nextUrl.length > 0) {
                            result.userInfo = @{@"list":items, @"next":nextUrl};
                        } else {
                            result.userInfo = @{@"list":items};
                        }
                    } else if ([userInfo isKindOfClass:[NSDictionary class]]) {
                        result = [[Result alloc] init];
                        result.userInfo = [MTLJSONAdapter modelOfClass:[objectClass class]
                                                    fromJSONDictionary:(NSDictionary *)(userInfo)
                                                                 error:error];
                    }
                }
            }
        } else {
            if (self.objectKey.length > 0) {
                if ([userInfo isKindOfClass:[NSDictionary class]]) {
                    NSObject *next = ((NSDictionary *)userInfo)[@"next"];
                    if (self.objectKey.length > 0) {
                        userInfo = ((NSDictionary *)userInfo)[self.objectKey];
                    }
                    
                    if ([userInfo isKindOfClass:[NSArray class]] && self.objectClassName.length==0) {
                        NSString *nextUrl = nil;
                        if ([next isKindOfClass:[NSString class]]) {
                            nextUrl = (NSString *)next;
                        }
                        
                        result = [[Result alloc] init];
                        if (nextUrl.length > 0) {
                            result.userInfo = @{@"list":((NSArray*)userInfo), @"next":nextUrl};
                        } else {
                            result.userInfo = ((NSArray*)userInfo);
                        }
                    }
                }
            } else {
                result = [[Result alloc] init];
                result.userInfo = userInfo;
            }
        }
    } while(NO);
    
    result.response = self.response;
    result.responseData = self.responseData;
    
    return result;
}

- (Result *)parseResponseUserInfo:(NSObject *)userInfo error:(NSError **)error {
    return nil;
}

- (void)requestCompletePreprocessor {
    if (self.responseData.length > 0) {
        NSString *dataStr = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableLeaves error:nil];
        NSLog(@"Request Success:  %@", dic);
        NSLog(@"Request: %@",self);
    }
    
    NSError *error = nil;
    Result *result = [self parseResponse:&error];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.callback != nil) {
            self.callback(result, error);
        }
        
        if (error.code == 107) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSString *errorText = [NSString stringWithFormat:@"认证错误，请重新登录, %@", self.requestUrl];
                NSLog(@"%@", errorText);
                [HUD showErrorWithMessage:@"该账号在其他设备登录"];
            });
            
            if (APP.currentUser != nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfAuthForbidden
                                                                    object:nil];
            }
        }
    });
}

- (void)requestFailedPreprocessor {
    if (self.responseData.length > 0) {
        NSLog(@"Request Failed: %@", [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.callback != nil) {
            self.callback(nil, self.error);
        }
    });
}

- (nullable NSDictionary<NSString *, NSString *> *)requestHeaderFieldValueDictionary {
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    
    headers[@"M-User-Agent"] = @"(com.minnie.teacher;1.0.0)(iOS;11.0)(abcedfg;iphone6;320*480)";
    
    if (self.token.length > 0 && !self.authorizationNotNeeded) {
        headers[@"Authorization"] = [NSString stringWithFormat:@"%@", self.token];
    }
    
    if (self.requestSerializerType == YTKRequestSerializerTypeJSON) {
        headers[@"Content-Type"] = @"application/json;charset=utf-8";
    } else {
        headers[@"Content-Type"] = @"application/x-www-form-urlencoded;charset=utf-8";
    }
    
    return headers;
}

- (NSString *)token {
    return accessToken;
}

- (NSString *)baseUrl {
    NSString *baseUrl = nil;
    
    if (USING_MOCK_DATA) {
        baseUrl = @"http://localhost";
        //        baseUrl = @"http://192.168.31.113";
        //        baseUrl = @"http://10.242.12.162";
    } else {
        
//        baseUrl = @"http://api.minniedu.com:8888";
        baseUrl = kConfigBaseUrl;
//        baseUrl = @"http://localhost:8090";
//        baseUrl = @"http://192.168.31.113:8090"; // pan
//        baseUrl = @"http://api.minniedu.com";
    }
    
    return baseUrl;
}

- (void)stop {
    self.callback = nil;
    [super stop];
}

@end




