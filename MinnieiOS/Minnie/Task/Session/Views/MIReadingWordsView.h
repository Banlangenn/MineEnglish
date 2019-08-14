//
//  MIReadingWordsView.h
//  Minnie
//
//  Created by songzhen on 2019/6/10.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HomeworkItem.h"

typedef void(^MIReadingWordsFinish)(void);

typedef void(^MIReadingWordsSeek)(CGFloat rate);

typedef void(^MIReadingWordsProgress)(NSInteger index);

NS_ASSUME_NONNULL_BEGIN

@interface MIReadingWordsView : UIView

@property (nonatomic,strong) HomeworkItem *wordsItem;
@property (nonatomic,copy) MIReadingWordsFinish readingWordsCallBack;

@property (nonatomic,copy) MIReadingWordsSeek readingWordsSeekCallBack;

@property (nonatomic,copy) MIReadingWordsProgress readingWordsProgressCallBack;

- (void)startPlayWords;
- (void)stopPlayWords;

- (void)invalidateTimer;

@end

NS_ASSUME_NONNULL_END
