//
//  Clazz.h
//  X5
//
//  Created by yebw on 2017/9/17.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import <Mantle/Mantle.h>
#import "User.h"
#import "Teacher.h"

// 班级
@interface Clazz : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSUInteger classId;  // 班级id
@property (nonatomic, copy) NSString *name; // 班级名称
@property (nonatomic, copy) NSString *startTime; // 上课时间字符串
@property (nonatomic, copy) NSString *endTime; // 下课时间字符串
// 1 2 3 春季夏季和秋季
@property (nonatomic, assign) NSInteger trial; //
@property (nonatomic, copy) NSString *location; // 位置
@property (nonatomic, strong) Teacher *teacher; // 教师
//@property (nonatomic, assign) NSUInteger maxStudentsCount; // 上课人数规模
@property (nonatomic, assign) NSUInteger studentsCount; // 上课人数
@property (nonatomic, assign) NSUInteger homeworksCount; // 作业数
@property (nonatomic, assign) NSUInteger circleCount; // 朋友圈数量
@property (nonatomic, assign) NSUInteger uncorrectedHomeworksCount; // 未批改的学生作业数
@property (nonatomic, assign) NSInteger isFinished;

@property (nonatomic, strong) NSArray<NSNumber *> *dates; // 上课的时间, 单位毫秒
@property (nonatomic, strong) NSArray<User *> *students; // 学生

@property (nonatomic, readonly) long long nextClassTime; // 下一次上课的时间

@property (nonatomic, assign) NSInteger commitedHomeworksCount;  //已提交的作业数量
@property (nonatomic, assign) NSInteger classLevel;//班级等级0-7

@property (nonatomic, copy) NSString *pinyinName;

@property (nonatomic, assign) BOOL canLookClass;
@property (nonatomic, assign) BOOL canLookStudent;

- (NSDictionary *)dictionaryForUpload;

@end

