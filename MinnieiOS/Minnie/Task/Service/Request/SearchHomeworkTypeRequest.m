//
//  SearchHomeworkTypeRequest.m
//  Minnie
//
//  Created by 栋栋 施 on 2018/11/19.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import "SearchHomeworkTypeRequest.h"

@interface SearchHomeworkTypeRequest()

@property(nonatomic,assign)NSInteger type;      //1:任务；2人
@property(nonatomic,assign)NSInteger finished;  //0：待批改；1已完成；2未提交
@property (nonatomic, copy) NSString *nextUrl;
@end

@implementation SearchHomeworkTypeRequest

- (instancetype)initWithHomeworkSessionForType:(NSInteger)type withFinishState:(NSInteger)state
{
    self = [super init];
    if (self != nil) {
        _type = type;
        _finished = state;
    }
    return self;
}

- (instancetype)initWithNextUrl:(NSString *)nextUrl
{
    self = [super init];
    if (self != nil) {
        _nextUrl = nextUrl;
    }
    
    return self;
}

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodGET;
}

- (NSString *)requestUrl {
    if (self.nextUrl.length > 0) {
        return self.nextUrl;
    }
    
    return [NSString stringWithFormat:@"%@/homeworkTask/getHomeworkByType", ServerProjectName];
}

- (id)requestArgument {
    if (self.nextUrl.length > 0) {
        return nil;
    }
    
    return @{@"type":@(self.type),@"finished":@(self.finished)};
}

@end