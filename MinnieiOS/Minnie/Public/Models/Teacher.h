//
//  Teacher.h
//  X5Teacher
//
//  Created by yebw on 2017/12/29.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "User.h"

typedef NS_ENUM(NSInteger, TeacherAuthority) {
    TeacherAuthoritySuperManager = 1, // 超级管理员
    TeacherAuthorityManager = 2, // 管理员
    TeacherAuthorityTeacher = 3, // 普通教师
};


typedef NS_ENUM(NSInteger, TeacherType) {
    TeacherTypeTeacher = 1, // 教师
    TeacherTypeAssistant = 2, // 助教
};



@interface Teacher : User<MTLJSONSerializing>

@property (nonatomic, assign) TeacherType type; // 类型：教师，助教
@property (nonatomic, assign) TeacherAuthority authority; // 权限：超级管理员，管理员，普通教师

// 权限相关

@property (nonatomic, assign) BOOL canManageHomeworkTask; //实时任务
@property (nonatomic, strong) NSArray *canLookTaskTeachers; // 实时任务查看

// 管理端：教师新建和设置按钮是否可见     教师端：我的-教师管理是否可见
@property (nonatomic, assign) BOOL canManageTeachers; //教师管理（新建/编辑/删除）
// 管理端:实时任务教师列表中的教师是否可见
@property (nonatomic, strong) NSArray *canLookTeachers; // 教师查看
// 管理端：任务管理模块的可见性 教师端：作业管理可见性
@property (nonatomic, assign) BOOL canManageHomeworks; // 管理作业
// 管理端：该开关控制该管理员账号下的作业文件夹可用范围
@property (nonatomic, strong) NSArray *canLookHomeworks; // 作业查看
// 管理端：活动管理模块
@property (nonatomic, assign) BOOL canManageActivity; //活动管理
// 管理端：校区管理模块
@property (nonatomic, assign) BOOL canManageCampus; //校区管理（新建/编辑/删除） (班级管理)
// 教师端：中间tab班级模块 控制班级列表中班级可见性
@property (nonatomic, strong) NSArray *canLookClasses; // 班级信息查看
// 管理端：学员管理可见性  教师端：
@property (nonatomic, assign) BOOL canManageStudents; // 管理学生
// 管理端：该权限控制该账号在学员管理模块中，可见的学生账号范围   教师端：我的->学员管理   该账号为班级任课教师时，该班级的所有学员默认可见。
@property (nonatomic, strong) NSArray *canLookStudents; // 学生信息查看
@property (nonatomic, assign) BOOL canManagePresents; // 礼物管理

// 弃用
@property (nonatomic, assign) BOOL canManageClasses; // 管理班级
// 弃用
@property (nonatomic, assign) BOOL canCreateRewards; // 新建礼品
// 管理端：礼物管理 模块可见性         教师端：星兑换
@property (nonatomic, assign) BOOL canExchangeRewards; // 兑换礼品
// 教师端：创建消息
@property (nonatomic, assign) BOOL canCreateNoticeMessage; // 创建通知消息


@property (nonatomic, copy) NSString *stuRemark;
@property (nonatomic, assign) NSInteger stuLabel;


@property (nonatomic, readonly) NSString *typeDescription;
@property (nonatomic, readonly) NSString *authorityDescription;


@property (nonatomic, assign) BOOL lookTasks;
@property (nonatomic, assign) BOOL lookTeachers; 

@end


@interface OnClass : MTLModel<MTLJSONSerializing>
//班级id
@property (nonatomic, assign) NSInteger classId;
//班级名称
@property (nonatomic, copy) NSString *name;
//学生数
@property (nonatomic, assign) NSInteger studentCount;

@end

@interface OnHomework : MTLModel<MTLJSONSerializing>
//作业id
@property (nonatomic, assign) NSInteger homeworkId;
//作业标题
@property (nonatomic, copy) NSString *title;
//平均得分
@property (nonatomic, assign) CGFloat avgScore;
//作业难度1-5星
@property (nonatomic, assign) NSInteger level;

@end


@interface TeacherDetail : MTLModel<MTLJSONSerializing>

//是否在线：1在线；0不在线
@property (nonatomic, assign) NSInteger isOnline;
//在线时长：今天、本周、本月
@property (nonatomic, strong) NSArray *onlineDetail;
//未提交的作业数量
@property (nonatomic, assign) NSInteger uncommitedHomeworksCount;
//待批改的作业数量
@property (nonatomic, assign) NSInteger uncorrectedHomeworksCount;
//已批改作业：今日、本周、本月
@property (nonatomic, strong) NSArray *correctedHomeworksDetail;
//上课班级信息
@property (nonatomic, strong) NSArray<OnClass*> *onClassList;
//任务评分统计
@property (nonatomic, strong) NSArray<OnHomework*> *onHomeworkList;

@end
