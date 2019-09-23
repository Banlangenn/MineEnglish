//
//  EditContentViewController.h
//  MinnieStudent
//
//  Created by songzhen on 2019/5/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "BaseViewController.h"

typedef NS_ENUM(NSInteger,EditContentType) {
    
    EditContentType_StuRemark,          // 学生编辑备注
    EditContentType_QuestionHomework    // 转发问题作业
};

NS_ASSUME_NONNULL_BEGIN

@interface EditContentViewController : BaseViewController

@property (nonatomic, assign) NSInteger userId;

- (void)setupWithHometaskId:(NSInteger)hometaskId
                 homeworkId:(NSInteger)homeworkId
                     userId:(NSInteger)userId
                  teacherId:(NSInteger)teacherId;

- (void)setupEditContentType:(EditContentType)editType
                   placeholder:(NSString *)placeholder
                     content:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
