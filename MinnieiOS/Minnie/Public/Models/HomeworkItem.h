//
//  HomeworkItem.h
//  X5Teacher
//
//  Created by yebw on 2018/1/28.
//  Copyright © 2018年 netease. All rights reserved.
//
#import "WordInfo.h"
#import <Mantle/Mantle.h>
#import <UIKit/UIKit.h>

extern NSString * const HomeworkItemTypeText;
extern NSString * const HomeworkItemTypeVideo;
extern NSString * const HomeworkItemTypeAudio;
extern NSString * const HomeworkItemTypeImage;
extern NSString * const HomeworkItemTypeWord;

@interface HomeworkItem : MTLModel<MTLJSONSerializing>

// 作业材料类型，分text，image，video ，audio,word
@property (nonatomic, copy) NSString *type;
// 文字内容，type为text时候有效
@property (nonatomic, copy) NSString *text;

@property (nonatomic, copy) NSString * audioUrl;
@property (nonatomic, copy) NSString * audioCoverUrl;

// 语音链接，type为video时候有效
@property (nonatomic, copy) NSString *videoUrl;
@property (nonatomic, copy) NSString *videoCoverUrl;
// 图片链接，type为image时候有效
@property (nonatomic, copy) NSString *imageUrl;
// 图片宽度像素，type为image时候有效
@property (nonatomic, assign) NSInteger imageWidth;
// 图片高度像素，type为image的时候有效
@property (nonatomic, assign) NSInteger imageHeight;
// 时长，秒
@property (nonatomic, assign) NSInteger itemTime;
// 单词，所有放在一起
@property (nonatomic, strong) NSArray<WordInfo> *words;
// 背景音乐地址
@property (nonatomic, copy) NSString *bgmusicUrl;
// 播放间隔时间（毫秒）
@property (nonatomic, assign) NSInteger playtime;

// 单词是否随机   0 顺序 1随机
@property (nonatomic, assign) NSInteger isRandom;
// 随机单词数组（本地使用）
@property (nonatomic, strong) NSArray<WordInfo> *randomWords;
// 提交作业时播放间隔时间（毫秒）
@property (nonatomic, assign) NSInteger commitPlaytime;

@end

