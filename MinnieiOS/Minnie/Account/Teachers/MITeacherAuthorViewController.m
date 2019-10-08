//
//  MITeacherAuthorViewController.m
//  Minnie
//
//  Created by songzhen on 2019/8/13.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "AuthService.h"
#import "TeacherService.h"
#import "ManagerServce.h"
#import "ClassService.h"
#import "DeleteTeacherAlertView.h"
#import "MITeacherAuthorTableViewCell.h"
#import "MITeacherAuthorViewController.h"
#import "MIAuthorPreviewViewController.h"
#import "ResetPasswordViewController.h"




@interface MITeacherAuthorViewController ()<
UITableViewDelegate,
UITableViewDataSource>

@property (strong, nonatomic) NSArray *dataArray;

@property (weak, nonatomic) IBOutlet UITableView *tableview;

/**
    操作员         操作对象
 0: 管理员->       普通老师
 1: 超级管理员->    普通老师
 2: 超级管理员->    超级管理员
    超级管理员->    管理员
 
 */
@property (assign, nonatomic) NSInteger authorType;

@property (strong, nonatomic) Teacher *tempTeacher;


// 可查看教师列表 超级管理员：默认可查看全部教师  管理员:默认不可查看
@property (strong, nonatomic) NSMutableArray *lookTasks;
@property (strong, nonatomic) NSMutableArray *lookTeachers;
@property (strong, nonatomic) NSMutableArray *lookHomeworks;
@property (strong, nonatomic) NSMutableArray *lookClasses;
@property (strong, nonatomic) NSMutableArray *lookStudents;

@end

@implementation MITeacherAuthorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.authorType = self.teacher.authority;
    
    self.tempTeacher = [[Teacher alloc] init];
    self.tempTeacher.userId = self.teacher.userId;
    self.tempTeacher.nickname = self.teacher.nickname;
    self.tempTeacher.phoneNumber = self.teacher.phoneNumber;
    self.tempTeacher.type = self.teacher.type;
    self.tempTeacher.authority = self.teacher.authority;
    
    
    [self resetAutohrState];
    
    self.dataArray = [self getDataArray];
    [self.tableview reloadData];
    self.tableview.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    
    [self requestAllTeacherList];
    [self requestAllParentFileList];
    [self requestAllClasses];
}

- (NSInteger)authorType{
    
    if (APP.currentUser.authority == TeacherAuthoritySuperManager) {
        
        if (self.tempTeacher.authority == TeacherAuthorityManager ||
            self.tempTeacher.authority == TeacherAuthoritySuperManager
            ) {
            return 2;
        } else {
            return 1;
        }
    }
    return 0;
}
- (NSArray *)getDataArray{
    
    NSArray *array;
    if (self.authorType == 0) {
        /**
         type:  0 输入 text:内容文本
         1 展开
         2 switch state:
         3 查看
         4 删除
         */
        array = @[@[@{@"title":@"姓名",
                      @"authorType":@(MIAuthorManagerNameType),
                      @"type":@(0)},
                    @{@"title":@"手机号码",
                      @"authorType":@(MIAuthorManagerPhoneNumType),
                      @"type":@(0)},
                    @{@"title":@"教师类型",
                      @"authorType":@(MIAuthorManagerTeacherType),
                      @"type":@(1)},
                    ],
                  @[@{@"title":@"班级信息查看",
                      @"authorType":@(MIAuthorManagerClassPreviewType),
                      @"type":@(3)},
                    @{@"title":@"学生信息查看",
                      @"authorType":@(MIAuthorManagerStudentPreviewType),
                      @"type":@(3)}
                    ],
                  @[@{@"title":@"修改密码",
                      @"authorType":@(MIAuthorManagerPasswordType),
                      @"type":@(3)}
                    ]
                  ];
    } else if (self.authorType == 1) {
       
        array = @[@[@{@"title":@"姓名",
                      @"authorType":@(MIAuthorManagerNameType),
                      @"type":@(0)},
                    @{@"title":@"手机号码",
                      @"authorType":@(MIAuthorManagerPhoneNumType),
                      @"type":@(0)},
                    @{@"title":@"教师类型",
                      @"authorType":@(MIAuthorManagerTeacherType),
                      @"type":@(1)},
                    @{@"title":@"权限设置",
                      @"authorType":@(MIAuthorManagerAuthorType),
                      @"type":@(1)},
                    ],
                  @[@{@"title":@"班级信息查看",
                      @"authorType":@(MIAuthorManagerClassPreviewType),
                      @"type":@(3)},
                    @{@"title":@"学生信息查看",
                      @"authorType":@(MIAuthorManagerStudentPreviewType),
                      @"type":@(3)}
                    ],
                  @[@{@"title":@"修改密码",
                      @"authorType":@(MIAuthorManagerPasswordType),
                      @"type":@(3)}
                    ]
                  ];
    } else {
        
        array = @[@[@{@"title":@"姓名",
                      @"authorType":@(MIAuthorManagerNameType),
                      @"type":@(0)},
                    @{@"title":@"手机号码",
                      @"authorType":@(MIAuthorManagerPhoneNumType),
                      @"type":@(0)},
                    @{@"title":@"教师类型",
                      @"authorType":@(MIAuthorManagerTeacherType),
                      @"type":@(1)},
                    @{@"title":@"权限设置",
                      @"authorType":@(MIAuthorManagerAuthorType),
                      @"type":@(1)},
                    ],
                  @[@{@"title":@"实时任务",
                      @"authorType":@(MIAuthorManagerRealTimeTaskType),
                      @"type":@(2)},
                    @{@"title":@"实时任务查看",
                      @"authorType":@(MIAuthorManagerRealTimeTaskPreviewType),
                      @"type":@(3)},
                    @{@"title":@"教师管理（新建/编辑/删除）",
                      @"authorType":@(MIAuthorManagerTeacherEditType),
                      @"type":@(2)},
                    @{@"title":@"教师查看",
                      @"authorType":@(MIAuthorManagerTeacherPreviewType),
                      @"type":@(3)},
                    @{@"title":@"作业库管理",
                      @"authorType":@(MIAuthorManagerHomeworkType),
                      @"type":@(2)},
                    @{@"title":@"作业查看",
                      @"authorType":@(MIAuthorManagerHomeworkPreviewType),
                      @"type":@(3)},
                    @{@"title":@"活动管理",
                      @"authorType":@(MIAuthorManagerActivityType),
                      @"type":@(2)},
                    ],
                  @[@{@"title":@"校区管理（新建/编辑/删除）",
                      @"authorType":@(MIAuthorManagerCampusType),
                      @"type":@(2)},
                    @{@"title":@"班级信息查看",
                      @"authorType":@(MIAuthorManagerClassPreviewType),
                      @"type":@(3)},
                    @{@"title":@"学生管理（编辑/删除)",
                      @"authorType":@(MIAuthorManagerStudentManagerType),
                      @"type":@(2)},
                    @{@"title":@"学生信息查看",
                      @"authorType":@(MIAuthorManagerStudentPreviewType),
                      @"type":@(3)}
                    ],
                  @[@{@"title":@"礼品管理",
                      @"authorType":@(MIAuthorManagerGiftsType),
                      @"type":@(2)},
                    @{@"title":@"礼品兑换",
                      @"authorType":@(MIAuthorManagerGiftsExchangeType),
                      @"type":@(2)}
                    ],
                  @[@{@"title":@"创建消息",
                      @"authorType":@(MIAuthorManagerMessageType),
                      @"type":@(2)}
                    ],
                  @[@{@"title":@"修改密码",
                      @"authorType":@(MIAuthorManagerPasswordType),
                      @"type":@(3)}
                    ]
                  ];
    }
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:array];
    if (self.authorType > 0 && self.tempTeacher.userId != 0) {
        
        NSArray *delete = @[@{@"title":@"删除",
                              @"authorType":@(MIAuthorManagerDeleteType),
                              @"type":@(4)}
                            ];
       
        [tempArray addObject:delete];
    }
    [self resetAutohrState];
    return tempArray;
}

- (IBAction)backAction:(id)sender {
    
#if MANAGERSIDE
    if (self.closeViewCallBack) {
        self.closeViewCallBack();
    }
#else
    [self.navigationController popViewControllerAnimated:YES];
#endif
    
}
- (IBAction)saveAction:(id)sender {

    NSMutableDictionary *changedInfos = [NSMutableDictionary dictionary];
    
    // 校验信息合法性
    NSString *errorTip = nil;
    do {
        NSString *nickname = [self.tempTeacher.nickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (nickname.length < 2 || nickname.length > 10) {
            errorTip = @"姓名格式不正确";
            break;
        }
        
        NSString *phoneNumber = [self.tempTeacher.phoneNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (phoneNumber.length != 11) {
            errorTip = @"手机号格式不正确";
            break;
        }
        
        
        if (self.teacher == nil || ![self.teacher.nickname isEqualToString:nickname]) {
            changedInfos[@"nickname"] = nickname;
        }
        
        if (self.teacher == nil || ![self.teacher.phoneNumber isEqualToString:phoneNumber]) {
            changedInfos[@"phoneNumber"] = phoneNumber;
            
            if (self.teacher == nil) {
                changedInfos[@"username"] = phoneNumber;
            }
        }
        
        if (self.teacher == nil || (self.teacher.type != self.tempTeacher.type)) {
          
            changedInfos[@"type"] = @(self.tempTeacher.type);
        }
        
        if (self.teacher == nil || self.teacher.authority != self.tempTeacher.authority) {
            
            changedInfos[@"authority"] = @(self.tempTeacher.authority);
        }
        changedInfos[@"nickname"] = nickname;
        changedInfos[@"phoneNumber"] = phoneNumber;
        changedInfos[@"type"] = @(self.tempTeacher.type);
        changedInfos[@"authority"] = @(self.tempTeacher.authority);
        
        changedInfos[@"canManageHomeworkTask"] = @(self.tempTeacher.canManageHomeworkTask);
        changedInfos[@"canLookTaskTeachers"] = self.tempTeacher.canLookTaskTeachers;
        changedInfos[@"canManageTeachers"] = @(self.tempTeacher.canManageTeachers);
        changedInfos[@"canLookTeachers"] = self.tempTeacher.canLookTeachers;
        changedInfos[@"canManageHomeworks"] = @(self.tempTeacher.canManageHomeworks);
        changedInfos[@"canLookHomeworks"] = self.tempTeacher.canLookHomeworks;
        changedInfos[@"canManageActivity"] = @(self.tempTeacher.canManageActivity);
        
        changedInfos[@"canManageCampus"] = @(self.tempTeacher.canManageCampus);
        changedInfos[@"canLookClasses"] = self.tempTeacher.canLookClasses;
        changedInfos[@"canManageStudents"] = @(self.tempTeacher.canManageStudents);
        changedInfos[@"canLookStudents"] = self.tempTeacher.canLookStudents;
        
        
        changedInfos[@"canManagePresents"] = @(self.tempTeacher.canManagePresents);
        changedInfos[@"canExchangeRewards"] = @(self.tempTeacher.canExchangeRewards);
        
        changedInfos[@"canCreateNoticeMessage"] = @(self.tempTeacher.canCreateNoticeMessage);
        
    } while(NO);
    
    if (errorTip.length > 0) {
        
#if MANAGERSIDE
        [TIP showText:errorTip inView:self.view];
#else
        [TIP showText:errorTip inView:self.navigationController.view];
#endif
        return;
    }
    
    if (self.teacher != nil && changedInfos.count == 0) {
#if MANAGERSIDE
        [TIP showText:@"没有信息修改" inView:self.view];
#else
        [TIP showText:@"没有信息修改" inView:self.navigationController.view];
#endif
        return;
    }
    
    if (self.teacher != nil) {
        [HUD showProgressWithMessage:@"正在更新"];
        changedInfos[@"id"] = @(self.teacher.userId);
        WeakifySelf;
        [TeacherService updateTeacherWithInfos:changedInfos
                                      callback:^(Result *result, NSError *error) {
                                          if (error != nil) {
                                              [HUD showErrorWithMessage:@"更新失败"];
                                          } else {
                                              [HUD showWithMessage:@"更新成功"];
                                              [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfUpdateTeacher
                                                                                                  object:nil];
#if MANAGERSIDE
                                              if (weakSelf.editSuccessCallBack) {
                                                  weakSelf.editSuccessCallBack(NO,weakSelf.tempTeacher);
                                              }
#else
                                              [weakSelf.navigationController popViewControllerAnimated:YES];
#endif
                                              
#if TEACHERSIDE | MANAGERSIDE
                                              if (self.teacher.userId == APP.currentUser.userId) {
                                                  self.teacher.token = APP.currentUser.token;
                                                  APP.currentUser = self.teacher;
                                                  
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfProfileUpdated object:nil];
                                              }
#endif
                                          }
                                      }];
    } else {
        WeakifySelf;
        [HUD showProgressWithMessage:@"正在创建"];
        [TeacherService createTeacherWithInfos:changedInfos
                                      callback:^(Result *result, NSError *error) {
                                          if (error != nil) {
                                              [HUD showErrorWithMessage:@"创建失败"];
                                          } else {
                                              [HUD showWithMessage:@"创建成功"];
                                              [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfAddTeacher
                                                                                                  object:nil];
#if MANAGERSIDE
                                              if (weakSelf.editSuccessCallBack) {
                                                  weakSelf.editSuccessCallBack(NO,weakSelf.tempTeacher);
                                              }
#else
                                              [weakSelf.navigationController popViewControllerAnimated:YES];
#endif
                                          }
                                      }];
    }
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.dataArray.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSArray *tempArr = self.dataArray[section];
    return tempArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return MITeacherAuthorTableViewCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.01;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MITeacherAuthorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITeacherAuthorTableViewCellId];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MITeacherAuthorTableViewCell class]) owner:nil options:nil] lastObject];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSArray *tempArr = self.dataArray[indexPath.section];
    NSDictionary *tempDic = tempArr[indexPath.row];
    NSNumber *type = tempDic[@"type"];
    NSNumber *authorType = tempDic[@"authorType"];
    
    NSString *text;
    BOOL switchState = NO;
    
    if (authorType.integerValue == MIAuthorManagerNameType) {
        
        text = self.tempTeacher.nickname;
    } else if (authorType.integerValue == MIAuthorManagerPhoneNumType) {
        text = self.tempTeacher.phoneNumber;
    } else if (authorType.integerValue == MIAuthorManagerTeacherType) {
        text = self.tempTeacher.typeDescription;
    } else if (authorType.integerValue == MIAuthorManagerAuthorType) {
        text = self.tempTeacher.authorityDescription;
    } else if (authorType.integerValue == MIAuthorManagerRealTimeTaskType) {
        switchState = self.tempTeacher.canManageHomeworkTask;
    } else if (authorType.integerValue == MIAuthorManagerTeacherEditType) {
         switchState = self.tempTeacher.canManageTeachers;
    } else if (authorType.integerValue == MIAuthorManagerHomeworkType) {
         switchState = self.tempTeacher.canManageHomeworks;
    } else if (authorType.integerValue == MIAuthorManagerActivityType) {
         switchState = self.tempTeacher.canManageActivity;
    } else if (authorType.integerValue == MIAuthorManagerCampusType) {
         switchState = self.tempTeacher.canManageCampus;
    } else if (authorType.integerValue == MIAuthorManagerStudentManagerType) {
         switchState = self.tempTeacher.canManageStudents;
    } else if (authorType.integerValue == MIAuthorManagerGiftsType) {
         switchState = self.tempTeacher.canManagePresents;
    } else if (authorType.integerValue == MIAuthorManagerGiftsExchangeType) {
         switchState = self.tempTeacher.canExchangeRewards;
    } else if (authorType.integerValue == MIAuthorManagerMessageType) {
         switchState = self.tempTeacher.canCreateNoticeMessage;
    }
    [cell setAuthority:self.tempTeacher.authority];
    [cell setupTitle:tempDic[@"title"]
                text:text
               image:nil
          authorType:authorType.integerValue
                type:type.integerValue
               state:switchState];
    
    cell.authorBlock = ^(MIAuthorManagerType authorType) {
        
        if (authorType == MIAuthorManagerTeacherType) {
            
            [self selectTeacherType];
        } else if (authorType == MIAuthorManagerAuthorType) {
            [self setTeacherAuthorType];
        } else if (authorType == MIAuthorManagerRealTimeTaskPreviewType ||
                   authorType == MIAuthorManagerTeacherPreviewType ||
                   authorType == MIAuthorManagerHomeworkPreviewType ||
                   authorType == MIAuthorManagerClassPreviewType ||
                   authorType == MIAuthorManagerStudentPreviewType) {
            
            [self toAuthorPreview:authorType];
        } else if (authorType == MIAuthorManagerPasswordType) {
            
            [self toShowResetPassword];
        }
    };
    cell.stateBlock = ^(MIAuthorManagerType authorType, BOOL state) {
        if (authorType == MIAuthorManagerRealTimeTaskType) {
            self.tempTeacher.canManageHomeworkTask = state;
        } else if (authorType == MIAuthorManagerTeacherEditType) {
            self.tempTeacher.canManageTeachers = state;
        } else if (authorType == MIAuthorManagerHomeworkType) {
            
            self.tempTeacher.canManageHomeworks = state;
        } else if (authorType == MIAuthorManagerActivityType) {
           
            self.tempTeacher.canManageActivity = state;
        } else if (authorType == MIAuthorManagerCampusType) {
            
            self.tempTeacher.canManageCampus = state;
        } else if (authorType == MIAuthorManagerStudentManagerType) {
            
            self.tempTeacher.canManageStudents = state;
        } else if (authorType == MIAuthorManagerGiftsType) {
            
            self.tempTeacher.canCreateRewards = state;
        } else if (authorType == MIAuthorManagerGiftsExchangeType) {
            
            self.tempTeacher.canExchangeRewards = state;
        } else if (authorType == MIAuthorManagerMessageType) {
            self.tempTeacher.canCreateNoticeMessage = state;
        }
    };
    
    cell.inputBlock = ^(MIAuthorManagerType authorType, NSString * _Nonnull text) {
      
        if (authorType == MIAuthorManagerNameType) {
            
            self.tempTeacher.nickname = text;
        } else if (authorType == MIAuthorManagerPhoneNumType) {
            
            self.tempTeacher.phoneNumber = text;
        }
    };
 
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *tempArr = self.dataArray[indexPath.section];
    NSDictionary *tempDic = tempArr[indexPath.row];
    NSInteger authorType = ((NSNumber *)tempDic[@"authorType"]).integerValue;
    
    if (authorType == MIAuthorManagerRealTimeTaskPreviewType ||
        authorType == MIAuthorManagerTeacherPreviewType ||
        authorType == MIAuthorManagerHomeworkPreviewType ||
        authorType == MIAuthorManagerClassPreviewType ||
        authorType == MIAuthorManagerStudentPreviewType) {
        
        [self toAuthorPreview:authorType];
    } else if (authorType == MIAuthorManagerPasswordType) {
        
        [self toShowResetPassword];
    } else if (authorType == MIAuthorManagerDeleteType) {
        
        [self deleteTeacher];
    }
}

#pragma mark - 修改密码
- (void)toShowResetPassword{
  
    ResetPasswordViewController *resetPasswordVC = [[ResetPasswordViewController alloc] initWithNibName:[[ResetPasswordViewController class] description] bundle:nil];
    resetPasswordVC.phoneNumber = self.teacher.phoneNumber;
#if MANAGERSIDE
    UIView *bgView = [Utils viewOfVCAddToWindowWithVC:resetPasswordVC width:375.0];
    resetPasswordVC.closeViewCallBack = ^{
        if (bgView.superview) {
            [bgView removeFromSuperview];
        }
    };
#else
    [self.navigationController pushViewController:resetPasswordVC animated:YES];
#endif
    
}
#pragma mark - 查看权限列表
- (void)toAuthorPreview:(MIAuthorManagerType)authorType{
    
    MIAuthorPreviewViewController *authorPreviewVC = [[MIAuthorPreviewViewController alloc] initWithNibName:NSStringFromClass([MIAuthorPreviewViewController class]) bundle:nil];
    authorPreviewVC.authorManagerType = authorType;
    authorPreviewVC.selectAuthority = self.tempTeacher.authority;
   
    if (authorType == MIAuthorManagerRealTimeTaskPreviewType) {// 实时任务查看
        
        authorPreviewVC.authorArray = self.tempTeacher.canLookTaskTeachers;
    } else if (authorType == MIAuthorManagerTeacherPreviewType) {// 教师任务查看
        
        authorPreviewVC.authorArray = self.tempTeacher.canLookTeachers;
    } else if (authorType == MIAuthorManagerHomeworkPreviewType) {//作业查看
        
        authorPreviewVC.authorArray = self.tempTeacher.canLookHomeworks;
    } else if (authorType == MIAuthorManagerClassPreviewType) {//班级信息查看
        
        authorPreviewVC.authorArray = self.tempTeacher.canLookClasses;
    } else if (authorType == MIAuthorManagerStudentPreviewType) {//学生信息查看
        authorPreviewVC.authorArray = self.tempTeacher.canLookStudents;
    }
    
    authorPreviewVC.editCallBack = ^(NSArray * _Nonnull authorArray) {
      
        if (authorType == MIAuthorManagerRealTimeTaskPreviewType) {// 实时任务查看
            
            self.tempTeacher.canLookTaskTeachers = authorArray;
        } else if (authorType == MIAuthorManagerTeacherPreviewType) {// 教师任务查看
          
            self.tempTeacher.canLookTeachers = authorArray;
        } else if (authorType == MIAuthorManagerHomeworkPreviewType) {//作业查看
            
            self.tempTeacher.canLookHomeworks = authorArray;
        } else if (authorType == MIAuthorManagerClassPreviewType) {//班级信息查看
            
            self.tempTeacher.canLookClasses = authorArray;
        } else if (authorType == MIAuthorManagerStudentPreviewType) {//学生信息查看
            
            self.tempTeacher.canLookStudents = authorArray;
        }
    };
    
    //    authorPreviewVC.cancelCallBack = ^{
    //        if (bgView.superview) {
    //            [bgView removeFromSuperview];
    //        }
    //    };
    //    authorPreviewVC.successCallBack = ^{
    //        if (bgView.superview) {
    //            [bgView removeFromSuperview];
    //        }
    //    };
    
#if MANAGERSIDE
    UIView *bgview = [Utils viewOfVCAddToWindowWithVC:authorPreviewVC width:375.0];
    authorPreviewVC.closeViewCallBack = ^{
        if (bgview.superview) {
            [bgview removeFromSuperview];
        }
    };
#else
        [self.navigationController pushViewController:authorPreviewVC animated:YES];
#endif

}

- (void)selectTeacherType{
    // 适配ipad版本
    UIAlertControllerStyle alertStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        alertStyle = UIAlertControllerStyleActionSheet;
    } else {
        alertStyle = UIAlertControllerStyleAlert;
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"选择教师类型"
                                                                     message:nil
                                                              preferredStyle:alertStyle];
    UIAlertAction *teacherAction = [UIAlertAction actionWithTitle:@"教师"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              self.tempTeacher.type = TeacherTypeTeacher;
                                                              [self.tableview reloadData];
                                                          }];
    
    UIAlertAction *assistantAction = [UIAlertAction actionWithTitle:@"助教"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
                                                                self.tempTeacher.type = TeacherTypeAssistant;
                                                                [self.tableview reloadData];
                                                            }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    [alertVC addAction:teacherAction];
    [alertVC addAction:assistantAction];
    [alertVC addAction:cancelAction];
    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
#if MANAGERSIDE
    
    [self.view.window.rootViewController presentViewController:alertVC
                                                      animated:YES
                                                    completion:nil];
#else
    
    [self.navigationController presentViewController:alertVC
                                            animated:YES
                                          completion:nil];
    
#endif
}

- (void)setTeacherAuthorType{
    
    // 适配ipad版本
    UIAlertControllerStyle alertStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        alertStyle = UIAlertControllerStyleActionSheet;
    } else {
        alertStyle = UIAlertControllerStyleAlert;
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"选择教师权限"
                                                                     message:nil
                                                              preferredStyle:alertStyle];
    UIAlertAction *superManagerAction = [UIAlertAction actionWithTitle:@"超级管理员"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
                                                                   
                                                                   if (self.tempTeacher.authority == TeacherAuthoritySuperManager) {
                                                                       return ;
                                                                   }
                                                                   self.tempTeacher.authority = TeacherAuthoritySuperManager;
                                                                   self.dataArray = [self getDataArray];
                                                                   [self.tableview reloadData];
                                                               }];
    
    UIAlertAction *managerAction = [UIAlertAction actionWithTitle:@"管理员"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                            
                                                              if (self.tempTeacher.authority == TeacherAuthorityManager) {
                                                                  return ;
                                                              }
                                                              self.tempTeacher.authority = TeacherAuthorityManager;;
                                                              self.dataArray = [self getDataArray];
                                                              [self.tableview reloadData];
                                                          }];
    
    UIAlertAction *teacherAction = [UIAlertAction actionWithTitle:@"普通教师"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              
                                                              if (self.tempTeacher.authority == TeacherAuthorityTeacher) {
                                                                  return ;
                                                              }
                                                              self.tempTeacher.authority = TeacherAuthorityTeacher;;
                                                              self.dataArray = [self getDataArray];
                                                              [self.tableview reloadData];
                                                          }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    [alertVC addAction:superManagerAction];
    [alertVC addAction:managerAction];
    [alertVC addAction:teacherAction];
    [alertVC addAction:cancelAction];
    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    
#if MANAGERSIDE
    
    [self.view.window.rootViewController presentViewController:alertVC
                                                      animated:YES
                                                    completion:nil];
#else
    
    [self.navigationController presentViewController:alertVC
                                            animated:YES
                                          completion:nil];
#endif
    
}

- (void)deleteTeacher{
    
    User *currentUser = [Application sharedInstance].currentUser;
    currentUser.phoneNumber = @"18667186875";
    
    UIView *parentView = self.navigationController.view;
#if MANAGERSIDE
    parentView = self.view;
#endif
    WeakifySelf;
    [DeleteTeacherAlertView showDeleteTeacherAlertView:parentView
                                               teacher:self.teacher
                                      sendCodeCallback:^{
                                          [AuthService askForSMSCodeWithPhoneNumber:currentUser.phoneNumber
                                                                           callback:^(Result *result, NSError *error) {
                                                                           }];
                                      }
                                       confirmCallback:^(NSString *code) {
                                           [AuthService verifySMSCodeWithPhoneNumber:currentUser.phoneNumber
                                                                                code:code
                                                                            callback:^(Result *result, NSError *error) {
                                                                                if (error != nil) {
                                                                                    [HUD showErrorWithMessage:@"验证码错误"];
                                                                                    
                                                                                    return;
                                                                                }
                                                                                
                                                                                [weakSelf doDelete];
                                                                            }];
                                       }];
}

- (void)doDelete {
    [HUD showProgressWithMessage:@"正在删除"];
    WeakifySelf;
    [TeacherService deleteTeacherWithId:self.teacher.userId
                               callback:^(Result *result, NSError *error) {
                                   if (error != nil) {
                                       [HUD showErrorWithMessage:@"删除失败"];
                                   } else {
                                       [HUD showWithMessage:@"已删除"];
                                       
                                       [DeleteTeacherAlertView hideAnimated:YES];
                                       
                                       [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfDeleteTeacher
                                                                                           object:nil];
#if MANAGERSIDE
                                       if (weakSelf.editSuccessCallBack) {
                                           weakSelf.editSuccessCallBack(YES, weakSelf.tempTeacher);
                                       }
#else
                                       [weakSelf.navigationController popViewControllerAnimated:YES];
#endif
                                   }
                               }];
}

- (void)resetAutohrState {
    
    // 未修改权限
    if (self.tempTeacher.authority == self.teacher.authority) {
        
        if (self.teacher.authority == TeacherAuthoritySuperManager) {
            
            self.tempTeacher.canManageHomeworkTask = YES;
            self.tempTeacher.canLookTaskTeachers = self.lookTasks;
            self.tempTeacher.canManageTeachers = YES;
            self.tempTeacher.canLookTeachers = self.lookTeachers;
            self.tempTeacher.canManageHomeworks = YES;
            
            self.tempTeacher.canLookHomeworks = self.lookHomeworks;
            self.tempTeacher.canManageActivity = YES;
            
            self.tempTeacher.canManageCampus = YES;
            
            self.tempTeacher.canLookClasses = self.lookClasses;
            self.tempTeacher.canLookStudents = self.lookStudents;
            self.tempTeacher.canManageStudents = YES;
            
            self.tempTeacher.canManagePresents = YES;
            self.tempTeacher.canExchangeRewards = YES;
            self.tempTeacher.canCreateNoticeMessage = YES;
        } else {
            
            self.tempTeacher.canManageHomeworkTask = self.teacher.canManageHomeworkTask;
            self.tempTeacher.canLookTaskTeachers = self.teacher.canLookTaskTeachers;
            self.tempTeacher.canManageTeachers = self.teacher.canManageTeachers;
            self.tempTeacher.canLookTeachers = self.teacher.canLookTeachers;
            self.tempTeacher.canManageHomeworks = self.teacher.canManageHomeworks;
            self.tempTeacher.canLookHomeworks = self.teacher.canLookHomeworks;
            self.tempTeacher.canManageActivity = self.teacher.canManageActivity;
            
            self.tempTeacher.canManageCampus = self.teacher.canManageCampus;
            self.tempTeacher.canLookClasses = self.teacher.canLookClasses;
            self.tempTeacher.canManageStudents = self.teacher.canManageStudents;
            self.tempTeacher.canLookStudents = self.teacher.canLookStudents;
            
            self.tempTeacher.canManagePresents = self.teacher.canManagePresents;
            self.tempTeacher.canExchangeRewards = self.teacher.canExchangeRewards;
            self.tempTeacher.canCreateNoticeMessage = self.teacher.canCreateNoticeMessage;
        }
    } else if (self.tempTeacher.authority == TeacherAuthoritySuperManager) {
      
        self.tempTeacher.canManageHomeworkTask = YES;
        self.tempTeacher.canLookTaskTeachers = self.lookTasks;
        self.tempTeacher.canManageTeachers = YES;
        self.tempTeacher.canLookTeachers = self.lookTeachers;
        self.tempTeacher.canManageHomeworks = YES;
       
        self.tempTeacher.canLookHomeworks = self.lookHomeworks;
        self.tempTeacher.canManageActivity = YES;
        
        self.tempTeacher.canManageCampus = YES;
    
        self.tempTeacher.canLookClasses = self.lookClasses;
        self.tempTeacher.canLookStudents = self.lookStudents;
        self.tempTeacher.canManageStudents = YES;
        
        self.tempTeacher.canManagePresents = YES;
        self.tempTeacher.canExchangeRewards = YES;
        self.tempTeacher.canCreateNoticeMessage = YES;
    } else if (self.tempTeacher.authority == TeacherAuthorityManager) {
        
        self.tempTeacher.canManageHomeworkTask = self.teacher.canManageHomeworkTask;
        self.tempTeacher.canLookTaskTeachers = @[];
        self.tempTeacher.canManageTeachers = self.teacher.canManageTeachers;
        self.tempTeacher.canLookTeachers = @[];
        self.tempTeacher.canManageHomeworks = self.teacher.canManageHomeworks;
        self.tempTeacher.canLookHomeworks = self.teacher.canLookHomeworks;
        self.tempTeacher.canManageActivity = self.teacher.canManageActivity;
        
        self.tempTeacher.canManageCampus = self.teacher.canManageCampus;
        self.tempTeacher.canLookClasses = self.teacher.canLookClasses;
        self.tempTeacher.canManageStudents = self.teacher.canManageStudents;
        self.tempTeacher.canLookStudents = self.teacher.canLookStudents;
        
        self.tempTeacher.canManagePresents = self.teacher.canManagePresents;
        self.tempTeacher.canExchangeRewards = self.teacher.canExchangeRewards;
        self.tempTeacher.canCreateNoticeMessage = self.teacher.canCreateNoticeMessage;
    } else {
        self.tempTeacher.canManageHomeworkTask = NO;
        self.tempTeacher.canLookTaskTeachers = @[];
        self.tempTeacher.canManageTeachers = NO;
        self.tempTeacher.canLookTeachers = @[];
        self.tempTeacher.canManageHomeworks = NO;
        self.tempTeacher.canLookHomeworks =  self.teacher.canLookHomeworks;
        self.tempTeacher.canManageActivity = NO;
        
        self.tempTeacher.canManageCampus = NO;
        self.tempTeacher.canLookClasses =  @[];
        self.tempTeacher.canManageStudents = NO;
        self.tempTeacher.canLookStudents =  @[];
        
        self.tempTeacher.canManagePresents = NO;
        self.tempTeacher.canExchangeRewards = NO;
        self.tempTeacher.canCreateNoticeMessage = NO;
    }
}

- (void)requestAllTeacherList{
    
    [TeacherService getAllTeacherWithCallback:^(Result *result, NSError *error) {
        
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *array = (NSArray *)(dict[@"list"]);
        if (!self.lookTeachers) {
            self.lookTeachers = [NSMutableArray array];
        } else {
            [self.lookTeachers removeAllObjects];
        }
        if (!self.lookTasks) {
            self.lookTasks = [NSMutableArray array];
        } else {
            [self.lookTasks removeAllObjects];
        }
        for (Teacher *teacher in array) {
            [self.lookTasks addObject:@(teacher.userId)];
            [self.lookTeachers addObject:@(teacher.userId)];
        }
        [self resetAutohrState];
    }];
}


- (void)requestAllParentFileList{
    
    [ManagerServce requestAllParentFileListWithCallback:^(Result *result, NSError *error) {
        
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *array = (NSArray *)(dict[@"list"]);
        
        if (!self.lookHomeworks) {
            self.lookHomeworks = [NSMutableArray array];
        } else {
            [self.lookHomeworks removeAllObjects];
        }
        for (FileInfo *file in array) {
            [self.lookHomeworks addObject:@(file.fileId)];
        }
        [self resetAutohrState];
    }];
}

- (void)requestAllClasses{
  
    [ClassService requestAllClassesWithCallback:^(Result *result, NSError *error) {
        
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *array = (NSArray *)(dict[@"list"]);
       
        if (!self.lookClasses) {
            self.lookClasses = [NSMutableArray array];
        } else {
            [self.lookClasses removeAllObjects];
        }
        if (!self.lookStudents) {
            self.lookStudents = [NSMutableArray array];
        } else {
            [self.lookStudents removeAllObjects];
        }
        for (Clazz *clazz in array) {
            [self.lookClasses addObject:@(clazz.classId)];
            [self.lookStudents addObject:@(clazz.classId)];
        }
        [self resetAutohrState];
    }];
}

@end
