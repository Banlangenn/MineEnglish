//
//  HomeworkItem.m
//  X5Teacher
//
//  Created by yebw on 2018/1/28.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "HomeworkItem.h"

NSString * const HomeworkItemTypeText = @"text";
NSString * const HomeworkItemTypeVideo = @"video";
NSString * const HomeworkItemTypeAudio = @"audio";
NSString * const HomeworkItemTypeImage = @"image";
NSString * const HomeworkItemTypeWord = @"word";

@interface HomeworkItem()
@end

@implementation HomeworkItem

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"type":@"type",
             @"text":@"text",
             @"audioUrl":@"audioUrl",
             @"audioCoverUrl":@"audioCoverUrl",
             @"videoUrl":@"videoUrl",
             @"videoCoverUrl":@"videoCoverUrl",
             @"imageUrl":@"imageUrl",
             @"imageWidth":@"imageWidth",
             @"imageHeight":@"imageHeight",
             @"itemTime":@"itemTime",
             @"words":@"words",
             @"bgmusicUrl":@"bgmusicUrl",
             @"playtime":@"playtime",
             @"playMode":@"playMode"
             };
}

+ (NSValueTransformer *)wordsJSONTransformer {
    
    return [MTLJSONAdapter arrayTransformerWithModelClass:[WordInfo class]];
}


@end

