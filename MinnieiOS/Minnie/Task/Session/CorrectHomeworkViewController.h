//
//  CorrectHomeworkViewController.h
//  X5Teacher
//
//  Created by yebw on 2018/2/6.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "BaseViewController.h"
#import "HomeworkSession.h"

@interface CorrectHomeworkViewController : BaseViewController

@property (nonatomic, strong) HomeworkSession *homeworkSession;

@property (nonatomic, copy) NSString *shareVedioUrl;

@end
