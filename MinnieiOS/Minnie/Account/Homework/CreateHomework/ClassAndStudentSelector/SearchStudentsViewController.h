//
//  SearchStudentsViewController.h
//  Minnie
//
//  Created by songzhen on 2019/12/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SearchStudentsViewController : BaseViewController

@property (nonatomic, strong) NSArray *students;

// 选择结果
@property (nonatomic, copy) void (^addCallBack) (NSArray *array);

@property (nonatomic,copy) void (^updateStudentStateCallBack) (void);


// 显示态点击
@property (nonatomic,copy) void (^clickCallBack) (NSInteger userId);


// selector: yes选择状态 no 显示状态
// inClass:（0未入学，1已入学，-1待处理）
// showClassName:是否显示班级
- (void)setDataWithSelectState:(BOOL)selector
                       inClass:(NSInteger)inClass
                 showClassName:(BOOL)show;
@end

NS_ASSUME_NONNULL_END
