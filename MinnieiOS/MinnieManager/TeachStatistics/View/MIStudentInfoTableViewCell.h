//
//  MIStudentInfoTableViewCell.h
//  MinnieManager
//
//  Created by songzhen on 2019/12/9.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MIStudentInfoTableViewCellId;


@interface MIStudentInfoTableViewCell : UITableViewCell

- (void)setupStudentInfo:(Student *)student;

@end

NS_ASSUME_NONNULL_END
