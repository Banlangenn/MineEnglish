//
//  NoticeMessageRequest.m
//  X5
//
//  Created by yebw on 2017/12/5.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "NoticeMessagesRequest.h"

@interface NoticeMessagesRequest()

@property (nonatomic, copy) NSString *nextUrl;

@end

@implementation NoticeMessagesRequest

- (BaseRequest *)initWithNextUrl:(NSString *)nextUrl {
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
    if (self.nextUrl != nil) {
        return self.nextUrl;
    }
    return [NSString stringWithFormat:@"%@/message/noticeMessages", ServerProjectName];
}

@end



@interface DeleteMessagesRequest()

@property (nonatomic, assign) NSInteger messageId;

@end

@implementation DeleteMessagesRequest

- (instancetype)initWithMessageId:(NSInteger)messageId{
   
    self = [super init];
    if (self != nil) {
        _messageId = messageId;
    }
    return self;
}

- (YTKRequestMethod)requestMethod {
    return YTKRequestMethodPOST;
}

- (NSString *)requestUrl {
    return [NSString stringWithFormat:@"%@/message/delNoticeMessages", ServerProjectName];
}

- (id)requestArgument {
    return @{@"msgId":@(self.messageId)};
}

@end
