//
//  NoticeMessageRequest.h
//  X5
//
//  Created by yebw on 2017/12/5.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "BaseRequest.h"

@interface NoticeMessageRequest : BaseRequest

- (instancetype)initWithMessageId:(NSUInteger)messageId;

@end
