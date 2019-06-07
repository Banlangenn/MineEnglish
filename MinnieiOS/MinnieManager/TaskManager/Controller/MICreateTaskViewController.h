//
//  MICreateTaskViewController.h
//  MinnieManager
//
//  Created by songzhen on 2019/6/3.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "Homework.h"
#import <UIKit/UIKit.h>
#import "ActivityInfo.h"
#import "MICreateHomeworkTaskView.h"

typedef void(^CreateTaskCallBack)(BOOL isDelete);

NS_ASSUME_NONNULL_BEGIN

@interface MICreateTaskViewController : UIViewController

@property (nonatomic, copy) CreateTaskCallBack callBack;

// 活动
- (void)setupCreateActivity:(ActivityInfo *_Nullable)activity;

// 作业
- (void)setupCreateHomework:(Homework *_Nullable)homework
            currentFileInfo:(FileInfo *)currentFileInfo
                   taskType:(MIHomeworkTaskType)taskType;



@end

NS_ASSUME_NONNULL_END
