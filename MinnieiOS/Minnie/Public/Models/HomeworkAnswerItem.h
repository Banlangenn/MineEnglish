//
//  HomeworkAnswerItem.h
//  X5Teacher
//
//  Created by yebw on 2018/1/28.
//  Copyright © 2018年 netease. All rights reserved.
//

#import <Mantle/Mantle.h>
#import <UIKit/UIKit.h>

extern NSString * const HomeworkAnswerItemTypeVideo;
extern NSString * const HomeworkAnswerItemTypeImage;

@interface HomeworkAnswerItem : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *type;

@property (nonatomic, copy) NSString *videoUrl;
@property (nonatomic, copy) NSString *videoCoverUrl;

@property (nonatomic, copy) NSString * audioUrl;
@property (nonatomic, copy) NSString * audioCoverUrl;

@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, assign) NSInteger imageWidth;
@property (nonatomic, assign) NSInteger imageHeight;

@property (nonatomic, assign) NSInteger itemTime;

@end




