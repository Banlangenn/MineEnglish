//
//  Homework.h
//  X5
//
//  Created by yebw on 2017/9/17.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "ParentFileInfo.h"
#import <Mantle/Mantle.h>
#import <UIKit/UIKit.h>
#import "Teacher.h"
#import "HomeworkItem.h"
#import "HomeworkAnswerItem.h"

// 教师创建的作业
@interface Homework : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSInteger homeworkId; // 作业id
@property (nonatomic, strong) Teacher *createTeacher; // 创建老师

@property (nonatomic, strong) NSString *title; // 标题
@property (nonatomic, strong) NSArray <HomeworkItem *>* items; // 作业内容项

@property (nonatomic, strong) NSArray <HomeworkItem *>* otherItem; // 跟读材料

@property (nonatomic, strong) NSArray <HomeworkAnswerItem *>* answerItems; // 作业内容项

@property (nonatomic, assign) long long createTime; // 创建的时间

@property (nonatomic, strong) NSArray <NSString *> *tags; // 标签

@property (nonatomic, assign) NSInteger style; //提交时间：1/2/3/4天

@property (nonatomic, assign) NSInteger level; //作业难度，1-5星

@property (nonatomic, assign) NSInteger category; //作业类型：普通1、附件2、初始化0

@property (nonatomic, assign) NSInteger limitTimes; //作业限制时长，单位秒

@property (nonatomic, strong) NSString * formTag;  //作业类型标签: 拼读，指读，默写，订正等等

@property (nonatomic, strong) NSString * teremark;  //批改备注 长度限制28
// 新增
@property (nonatomic, strong) HomeworkFileDto *fileInfos; //文件位置信息

@property (nonatomic, strong) NSString *typeName; //任务类型：通知、跟读、单词记忆、普通任务、考试统计

@property (nonatomic, assign) NSInteger examType; // 任务类型为成绩统计：1:周测；2:正式考试


@property (nonatomic, assign) NSInteger imageCount;   // 要求提交图片数量
@property (nonatomic, assign) NSInteger videoCount;     // 要求提交视频数量

@property (nonatomic, assign) NSInteger currentImageCount; // 当前提交图片数量
@property (nonatomic, assign) NSInteger currentVideoCount; // 当前提交视频数量


// UI
@property (nonatomic, assign) CGFloat cellHeight;

- (NSDictionary *)dictionaryForUpload;

- (Homework *)newHomework;

@end

