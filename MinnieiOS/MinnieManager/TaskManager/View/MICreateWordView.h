//
//  MICreateWordView.h
//  MinnieManager
//
//  Created by songzhen on 2019/6/6.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordInfo.h"

typedef void(^CreateWordViewCallBack) (WordInfo * _Nullable word);

NS_ASSUME_NONNULL_BEGIN

@interface MICreateWordView : UIView

@property (nonatomic,copy) CreateWordViewCallBack callback;

@property (nonatomic,strong) WordInfo *word;

// 已添加单词列表
@property (nonatomic,strong) NSArray *words;



@end

NS_ASSUME_NONNULL_END
