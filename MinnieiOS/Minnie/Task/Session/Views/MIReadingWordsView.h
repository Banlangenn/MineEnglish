//
//  MIReadingWordsView.h
//  Minnie
//
//  Created by songzhen on 2019/6/10.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HomeworkItem.h"



NS_ASSUME_NONNULL_BEGIN

@interface MIReadingWordsView : UIView

@property (nonatomic,strong) HomeworkItem *wordsItem;

@property (nonatomic,copy) void(^sliderValueChangedCallback)(BOOL sliding, CGFloat value);

//
//@property (nonatomic,copy) void(^readingWordsProgressCallBack)(NSInteger index);

//- (void)startPlayWords;
//- (void)stopPlayWords;

- (void)showWordsWithIndex:(NSInteger)index;


@end

NS_ASSUME_NONNULL_END
