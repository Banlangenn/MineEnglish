//
//  NoticeMessageDetailViewController.h
//  X5
//
//  Created by yebw on 2017/9/19.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "BaseViewController.h"

// 通知消息的详情页面
@interface NoticeMessageDetailViewController : BaseViewController

@property (nonatomic, assign) NSUInteger messageId;

@property (nonatomic, copy) void (^deleteCallBack) (void);

@end
