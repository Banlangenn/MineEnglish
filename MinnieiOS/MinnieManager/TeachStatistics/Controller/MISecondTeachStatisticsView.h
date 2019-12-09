//
//  MISecondTeachStatisticsView.h
//  MinnieManager
//
//  Created by songzhen on 2019/7/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MISecondTeachStatisticsViewDelegate <NSObject>

- (void)secondTeachStatisticsViewDidClicledWithStudent:(Student *_Nullable)student;

@end


NS_ASSUME_NONNULL_BEGIN

@interface MISecondTeachStatisticsView : UIView

@property (nonatomic,weak) id<MISecondTeachStatisticsViewDelegate> delegate;

- (void)updateStudentList;

@end

NS_ASSUME_NONNULL_END
