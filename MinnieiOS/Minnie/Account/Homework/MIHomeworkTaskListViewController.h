//
//  MIHomeworkTaskListViewController.h
//  Minnie
//
//  Created by songzhen on 2019/6/8.
//  Copyright © 2019 minnieedu. All rights reserved.
//  教师端 作业列表

#import "ParentFileInfo.h"
#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MIHomeworkTaskListViewController : BaseViewController

@property (nonatomic, strong) FileInfo *currentFileInfo;

@property (nonatomic, assign) BOOL teacherSider;

@end

NS_ASSUME_NONNULL_END
