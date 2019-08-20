//
//  AccountManageTableViewCell.m
//  X5Teacher
//
//  Created by yebw on 2017/12/16.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "AccountManageTableViewCell.h"
#import "UIColor+HEX.h"

NSString * const AccountManageTableViewCellId = @"AccountManageTableViewCellId";
CGFloat const AccountManageTableViewCellHeight = 212.f;

@interface AccountManageTableViewCell()

@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *homeworkManageViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *teacherManageViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *classManageViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *studentManageViewHeightConstraint;

@end

@implementation AccountManageTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.containerView.layer.cornerRadius = 12.f;
    self.containerView.layer.shadowOpacity = 0.4;// 阴影透明度
    self.containerView.layer.shadowColor = [UIColor colorWithHex:0xEEEEEE].CGColor;
    self.containerView.layer.shadowRadius = 3;
    self.containerView.layer.shadowOffset = CGSizeMake(2, 4);
}

//- (void)setup {
//    NSInteger lastIndex = -1;
//    self.homeworkManageViewHeightConstraint.constant = APP.currentUser.canManageHomeworks?50.f:0;
//    lastIndex = APP.currentUser.canManageHomeworks?0:lastIndex;
//
//    self.teacherManageViewHeightConstraint.constant = APP.currentUser.authority==TeacherAuthoritySuperManager?50.f:0;
//    lastIndex = (APP.currentUser.authority==TeacherAuthoritySuperManager)?1:lastIndex;
//
//    self.classManageViewHeightConstraint.constant = APP.currentUser.canManageClasses?50.f:0;
//    lastIndex = (APP.currentUser.canManageClasses)?2:lastIndex;
//
//    self.studentManageViewHeightConstraint.constant = APP.currentUser.canManageStudents?50.f:0;
//    lastIndex = (APP.currentUser.canManageStudents)?3:lastIndex;
//
//    for (NSInteger index=0; index<4; index++) {
//        UIView *v = [self.contentView viewWithTag:10+index];
//        [v setHidden:NO];
//    }
//    NSLog(@"lastIndex:: %lu",lastIndex);
//
//    NSInteger tag = lastIndex+10;
//    UIView *v = [self.contentView viewWithTag:tag];
//    [v setHidden:YES];
//}

- (void)setup{
    
    TeacherAuthority author = APP.currentUser.authority;
    if (author == TeacherAuthoritySuperManager ||
        author == TeacherAuthorityManager) {
        
        self.homeworkManageViewHeightConstraint.constant = APP.currentUser.canManageHomeworks?50.f:0;
        self.teacherManageViewHeightConstraint.constant = APP.currentUser.canManageTeachers?50.f:0;
        self.classManageViewHeightConstraint.constant = APP.currentUser.canManageCampus?50.f:0;
//        self.studentManageViewHeightConstraint.constant = APP.currentUser.canManageStudents?50.f:0;
        
        self.studentManageViewHeightConstraint.constant = 50.f;
        // 作业管理
        UIView *vHomework = [self.contentView viewWithTag:10];
        [vHomework setHidden:!APP.currentUser.canManageHomeworks];
        
        // 教师管理
        BOOL showTeacher = APP.currentUser.canManageTeachers;
        UIView *vTeacher = [self.contentView viewWithTag:11];
        [vTeacher setHidden:!showTeacher];
        
        // 校区管理
        UIView *vClass = [self.contentView viewWithTag:12];
        [vClass setHidden:!APP.currentUser.canManageCampus];
        
        // 学生信息查看
        UIView *vStudents = [self.contentView viewWithTag:13];
        [vStudents setHidden:NO];
    } else {// 普通教师
        
        self.homeworkManageViewHeightConstraint.constant = 0;
        self.teacherManageViewHeightConstraint.constant = 0;
        // 学员管理默认打开，班级管理权限不打开
        self.classManageViewHeightConstraint.constant = APP.currentUser.canManageClasses?50.f:0;
        self.studentManageViewHeightConstraint.constant = 50.f;
        
        UIView *vHomework = [self.contentView viewWithTag:10];
        [vHomework setHidden:YES];
    
        UIView *vTeacher = [self.contentView viewWithTag:11];
        [vTeacher setHidden:YES];
        
        UIView *vClass = [self.contentView viewWithTag:12];
        [vClass setHidden:YES];
        
        UIView *vStudents = [self.contentView viewWithTag:13];
        [vStudents setHidden:NO];
    }
}

- (IBAction)homeworkManageButtonPressed:(id)sender {
    if (self.homeworkManageCallback != nil) {
        self.homeworkManageCallback();
    }
}

- (IBAction)teacherManageButtonPressed:(id)sender {
    if (self.teacherManageCallback != nil) {
        self.teacherManageCallback();
    }
}

- (IBAction)classManageButtonPressed:(id)sender {
    if (self.classManageCallback != nil) {
        self.classManageCallback();
    }
}

- (IBAction)studentManageButtonPressed:(id)sender {
    if (self.studentManageCallback != nil) {
        self.studentManageCallback();
    }
}

@end


