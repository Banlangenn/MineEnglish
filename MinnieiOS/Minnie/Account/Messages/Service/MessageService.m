//
//  MessageService.m
//  X5
//
//  Created by yebw on 2017/12/5.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "MessageService.h"
#import "NoticeMessagesRequest.h"
#import "NoticeMessageRequest.h"
#import "CommentMessagesRequest.h"
#import "AddNoticeMessageRequest.h"
#import "MessageUpdateCountRequest.h"

@implementation MessageService

// 删除消息
+ (BaseRequest *)requestDeleteMessagesWithId:(NSInteger)msgId
                                    callback:(RequestCallback)callback{
    
    DeleteMessagesRequest *request= [[DeleteMessagesRequest alloc] initWithMessageId:msgId];
    request.callback = callback;
    [request start];
    
    return request;
}

+ (BaseRequest *)requestNoticeMessagesWithCallback:(RequestCallback)callback {
    NoticeMessagesRequest *request= [[NoticeMessagesRequest alloc] init];
    request.callback = callback;
    
    request.objectKey = @"list";
    request.objectClassName = @"NoticeMessage";
    
    [request start];
    
    return request;
}

// 加载更多通知消息
+ (BaseRequest *)requestNoticeMessagesWithNextUrl:(NSString *)nextUrl
                                         callback:(RequestCallback)callback {
    NoticeMessagesRequest *request= [[NoticeMessagesRequest alloc] initWithNextUrl:nextUrl];
    request.callback = callback;
    
    request.objectKey = @"list";
    request.objectClassName = @"NoticeMessage";
    
    [request start];
    
    return request;
}

// 加载通知消息
+ (BaseRequest *)requestCommentMessagesWithCallback:(RequestCallback)callback {
    CommentMessagesRequest *request= [[CommentMessagesRequest alloc] init];
    request.callback = callback;
    
    request.objectKey = @"list";
    request.objectClassName = @"Comment";
    
    [request start];
    
    return request;
}
// 加载更多通知消息
+ (BaseRequest *)requestCommentMessagesWithNextUrl:(NSString *)nextUrl
                                          callback:(RequestCallback)callback {
    CommentMessagesRequest *request= [[CommentMessagesRequest alloc] initWithNextUrl:nextUrl];
    request.callback = callback;
    
    request.objectKey = @"list";
    request.objectClassName = @"CommentMessage";
    
    [request start];
    
    return request;
}

+ (BaseRequest *)requestNoticeMessageWithId:(NSUInteger)messageId
                                   callback:(RequestCallback)callback {
    NoticeMessageRequest *request = [[NoticeMessageRequest alloc] initWithMessageId:messageId];
    request.callback = callback;
    
    request.objectClassName = @"NoticeMessage";
    
    [request start];

    return request;
}

+ (BaseRequest *)sendNoticeMessage:(NoticeMessage *)message
                            callback:(RequestCallback)callback {
    AddNoticeMessageRequest *request = [[AddNoticeMessageRequest alloc] initWithNoticeMessage:message];
    
    request.callback = callback;
    request.objectClassName = @"NoticeMessage";

    [request start];
    
    return request;
}

+ (BaseRequest *)requestUpdateCountWithCallback:(RequestCallback)callback {
    MessageUpdateCountRequest *request = [[MessageUpdateCountRequest alloc] init];
    request.callback = callback;
    
    [request start];
    
    return request;
}

@end
