//
//  Student.h
//  X5
//
//  Created by yebw on 2018/4/6.
//  Copyright © 2018年 mfox. All rights reserved.
//

#import "User.h"
#import "Clazz.h"

@interface Student : User

@property (nonatomic, copy) NSString *grade; // 年级
@property (nonatomic, assign) NSUInteger starCount; // 剩余星星数
@property (nonatomic, assign) NSUInteger circleUpdate; // 朋友圈更新数
//[0, 1, 2, 3, 4, 5, 6]其中索引6表示未完成的个数，0表示0星个数，1表示1星个数，依次类推
@property (nonatomic, strong) NSArray *homeworks; // 作业完成情况
@property (nonatomic, strong) Clazz *clazz; // 班级

@property (nonatomic, assign) NSInteger enrollState; // 报名状态
@property (nonatomic, assign) NSInteger warnCount;  //警告次数

/*
 标注的图形
 0：无
 1：闪电图形
 2：云朵图形
 3：消息图形
*/
@property (nonatomic, assign) NSInteger stuLabel;
@property (nonatomic, copy) NSString *stuRemark;// 备注信息

@end


@interface StudentsByName : Student<MTLJSONSerializing>
//班级名称
@property (nonatomic, copy) NSString *className;

@end


@interface StudentByClass : Student<MTLJSONSerializing>
@end


@interface StudentsByClass : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSInteger classId;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, strong) NSArray<StudentByClass *> *students;

@property (nonatomic, copy) NSString *pinyinName;

@end



@interface StudentZeroTask : MTLModel<MTLJSONSerializing>

//用户头像地址
@property (nonatomic, copy) NSString *avatar;
//用户id
@property (nonatomic, assign) NSInteger userId;
//用户昵称
@property (nonatomic, copy) NSString *nickName;
//作业id
@property (nonatomic, assign) NSInteger hometaskId;
//作业标题
@property (nonatomic, copy) NSString *title;
//创建教师
@property (nonatomic, copy) NSString *createTeacher;
//教师评语
@property (nonatomic, copy) NSString *content;

@end


@interface StudentDetail : MTLModel<MTLJSONSerializing>

//是否在线：1在线；0不在线
@property (nonatomic, assign) NSInteger isOnline;
//待批改作业数量
@property (nonatomic, assign) NSInteger uncorrectHomeworksCount;
//考试统计
@property (nonatomic, assign) CGFloat testAvgScore;
//勋章数量
@property (nonatomic, assign) NSInteger medalCount;
//点赞数量
@property (nonatomic, assign) NSInteger likeCount;
//星星数量
@property (nonatomic, assign) NSInteger starCount;
//兑换礼品数量
@property (nonatomic, assign) NSInteger giftCount;
//本学期作业总数
@property (nonatomic, assign) NSInteger allHomeworksCount;
//本学期完成的作业总数
@property (nonatomic, assign) NSInteger commitHomeworksCount;
//任务平均得分
@property (nonatomic, assign) CGFloat avgScore;
//优秀作业数量
@property (nonatomic, assign) NSInteger excellentHomeworksCount;
//过期作业数量
@property (nonatomic, assign) NSInteger overdueHomeworksCount;
//被分享的次数
@property (nonatomic, assign) NSInteger shareCount;
//任务星级数 0-5
//[0, 1, 2, 3, 4, 5, 6]其中索引6表示未完成的个数
@property (nonatomic, strong) NSArray *homeworks;

@end
