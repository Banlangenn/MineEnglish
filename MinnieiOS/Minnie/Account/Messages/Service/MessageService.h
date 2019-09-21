//
//  MessageService.h
//  X5
//
//  Created by yebw on 2017/12/5.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NoticeMessage.h"
#import "BaseRequest.h"
#import "Result.h"

@interface MessageService : NSObject


+ (BaseRequest *)requestDeleteMessagesWithId:(NSInteger)msgId
                                    callback:(RequestCallback)callback;
// 加载通知消息
+ (BaseRequest *)requestNoticeMessagesWithCallback:(RequestCallback)callback;

// 加载更多通知消息
+ (BaseRequest *)requestNoticeMessagesWithNextUrl:(NSString *)nextUrl
                                         callback:(RequestCallback)callback;

// 加载评论消息
+ (BaseRequest *)requestCommentMessagesWithCallback:(RequestCallback)callback;

// 加载更多评论消息
+ (BaseRequest *)requestCommentMessagesWithNextUrl:(NSString *)nextUrl
                                         callback:(RequestCallback)callback;

// 加载完整的通知消息
+ (BaseRequest *)requestNoticeMessageWithId:(NSUInteger)messageId
                                   callback:(RequestCallback)callback;

// 创建通知
+ (BaseRequest *)sendNoticeMessage:(NoticeMessage *)message
                            callback:(RequestCallback)callback;

// 获取消息未读数
+ (BaseRequest *)requestUpdateCountWithCallback:(RequestCallback)callback;

@end
