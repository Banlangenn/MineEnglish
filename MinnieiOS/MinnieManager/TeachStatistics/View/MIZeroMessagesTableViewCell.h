//
//  MIZeroMessagesTableViewCell.h
//  MinnieManager
//
//  Created by songzhen on 2019/7/12.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MIZeroMessagesTableViewCellId;

@interface MIZeroMessagesTableViewCell : UITableViewCell

- (void)setupImage:(NSString *)image
              name:(NSString *)name
         taskTitle:(NSString *)title
           comment:(NSString *)comment
           teacher:(NSString *)teacher
             index:(NSInteger)index;

+ (CGFloat)cellHeightWithZeroMessage:(StudentZeroTask *)zeroData;


@end

NS_ASSUME_NONNULL_END
