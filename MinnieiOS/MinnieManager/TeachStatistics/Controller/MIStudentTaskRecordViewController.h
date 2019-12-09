//
//  MIStudentTaskRecordViewController.h
//  MinnieManager
//
//  Created by songzhen on 2019/12/9.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MIStudentTaskRecordViewController : UIViewController

@property (nonatomic, assign) NSInteger studentId;

- (void)updateStarRecordWithSutdentId:(NSInteger)studentId;

@end

NS_ASSUME_NONNULL_END
