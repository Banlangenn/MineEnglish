//
//  MIZeroMessagesViewController.h
//  MinnieManager
//
//  Created by songzhen on 2019/7/12.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,HomeworkMessageType) {
    
    HomeworkMessageType_ZeroMessages,       // 零分动态
    HomeworkMessageType_QuestionHomework    // 问题任务
};

NS_ASSUME_NONNULL_BEGIN

@interface MIZeroMessagesViewController : UIViewController

//@property (nonatomic,copy) void(^pushVCCallback) (UIViewController * _Nullable VC) ;

- (void)updateZeroMessages;

@end

NS_ASSUME_NONNULL_END
