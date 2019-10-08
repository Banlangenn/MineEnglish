//
//  TeacherEditViewController.m
//  X5Teacher
//
//  Created by yebw on 2017/12/19.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "TeacherEditViewController.h"
#import "TeacherService.h"
#import "HUD.h"

#import "DeleteTeacherAlertView.h"
#import "AuthService.h"

@interface TeacherEditViewController ()

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) NSMutableDictionary *changedInfos;

@property (nonatomic, weak) IBOutlet UIButton *saveButton;

@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UITextField *phoneNumberTextField;
@property (nonatomic, weak) IBOutlet UITextField *typeTextField;
@property (nonatomic, weak) IBOutlet UITextField *authorityTextField;

@property (nonatomic, weak) IBOutlet UISwitch *homeworkManageSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *classManageSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *studentManageSwitch;

@property (nonatomic, weak) IBOutlet UISwitch *rewardCreateSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *rewardExchangeSwitch;

@property (nonatomic, weak) IBOutlet UISwitch *noticeCreateSwitch;

@property (nonatomic, weak) IBOutlet UIButton *deleteButton;

@end

@implementation TeacherEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.changedInfos == nil) {
        self.changedInfos = [NSMutableDictionary dictionary];
    }
    
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    if (self.teacher == nil) {
        self.customTitleLabel.text = @"新增教师";
        self.deleteButton.hidden = YES;
        [self.saveButton setTitle:@"确定" forState:UIControlStateNormal];
        
        self.typeTextField.text = @"教师";
        self.authorityTextField.text = @"普通教师";
        
        self.homeworkManageSwitch.on = NO;
        self.classManageSwitch.on = YES;
        self.studentManageSwitch.on = NO;

        self.rewardCreateSwitch.on = NO;
        self.rewardExchangeSwitch.on = YES;
        
        self.noticeCreateSwitch.on = NO;
    } else {
        self.customTitleLabel.text = @"教师信息";
        self.deleteButton.hidden = NO;
        [self.saveButton setTitle:@"保存" forState:UIControlStateNormal];
        
        self.nameTextField.text = self.teacher.nickname;
        self.phoneNumberTextField.text = self.teacher.phoneNumber;
        self.typeTextField.text = self.teacher.typeDescription;
        self.authorityTextField.text = self.teacher.authorityDescription;
        
        self.homeworkManageSwitch.on = self.teacher.canManageHomeworks;
        self.classManageSwitch.on = self.teacher.canManageClasses;
        self.studentManageSwitch.on = self.teacher.canManageStudents;
        
        self.rewardCreateSwitch.on = self.teacher.canCreateRewards;
        self.rewardExchangeSwitch.on = self.teacher.canExchangeRewards;

        self.noticeCreateSwitch.on = self.teacher.canCreateNoticeMessage;
    }
    
    if (APP.currentUser.authority != TeacherAuthoritySuperManager
        || APP.currentUser.userId == self.teacher.userId) {
        self.deleteButton.hidden = YES;
    }
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

#pragma mark - IBActions

// 教师类型
- (IBAction)typeButtonPressed:(id)sender {
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
                                                              self.typeTextField.text = @"教师";
                                                          }];
    
    UIAlertAction *assistantAction = [UIAlertAction actionWithTitle:@"助教"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
                                                                self.typeTextField.text = @"助教";
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

- (IBAction)authorityButtonPressed:(id)sender {
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
                                                                   if (![self.authorityTextField.text isEqualToString:@"超级管理员"]) {
                                                                       [self updateSwitchsAfterAuthorityChanged:TeacherAuthoritySuperManager];
                                                                   }
                                                                   
                                                                   self.authorityTextField.text = @"超级管理员";
                                                               }];
    
    UIAlertAction *managerAction = [UIAlertAction actionWithTitle:@"管理员"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              if (![self.authorityTextField.text isEqualToString:@"管理员"]) {
                                                                  [self updateSwitchsAfterAuthorityChanged:TeacherAuthorityManager];
                                                              }
                                                              
                                                              self.authorityTextField.text = @"管理员";
                                                          }];
    
    UIAlertAction *teacherAction = [UIAlertAction actionWithTitle:@"普通教师"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              if (![self.authorityTextField.text isEqualToString:@"普通教师"]) {
                                                                  [self updateSwitchsAfterAuthorityChanged:TeacherAuthorityTeacher];
                                                              }
                                                              
                                                              self.authorityTextField.text = @"普通教师";
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

- (IBAction)switchValueDidChange:(id)sender {
    UISwitch *swtch = (UISwitch *)sender;
    if (swtch == self.homeworkManageSwitch) {
        self.teacher.canManageHomeworks = swtch.on;
    } else if (swtch == self.classManageSwitch) {
        self.teacher.canManageClasses = swtch.on;
    } else if (swtch == self.studentManageSwitch) {
        self.teacher.canManageStudents = swtch.on;
    } else if (swtch == self.rewardCreateSwitch) {
        self.teacher.canCreateRewards = swtch.on;
    } else if (swtch == self.rewardExchangeSwitch) {
        self.teacher.canExchangeRewards = swtch.on;
    } else if (swtch == self.noticeCreateSwitch) {
        self.teacher.canCreateNoticeMessage = swtch.on;
    }
}

- (void)backButtonPressed:(id)sender{
#if MANAGERSIDE
    if (self.successCallBack) {
        self.successCallBack();
    }
#else
    [self.navigationController popViewControllerAnimated:YES];
#endif
}

- (IBAction)saveButtonPressed {
    if (APP.currentUser.authority != TeacherAuthoritySuperManager) {
        [HUD showErrorWithMessage:@"无操作权限"];
        
        return;
    }
    
    [self.nameTextField resignFirstResponder];
    [self.phoneNumberTextField resignFirstResponder];
    
    // 校验信息合法性
    NSString *errorTip = nil;
    do {
        NSString *nickname = [self.nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (nickname.length < 2 || nickname.length > 10) {
            errorTip = @"姓名格式不正确";
            break;
        }
        
        
        NSString *phoneNumber = [self.phoneNumberTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (phoneNumber.length != 11) {
            errorTip = @"手机号格式不正确";
            break;
        }
        
        
        if (self.teacher == nil || ![self.teacher.nickname isEqualToString:nickname]) {
            self.changedInfos[@"nickname"] = nickname;
        }
        
        if (self.teacher == nil || ![self.teacher.phoneNumber isEqualToString:phoneNumber]) {
            self.changedInfos[@"phoneNumber"] = phoneNumber;
            
            if (self.teacher == nil) {
                self.changedInfos[@"username"] = phoneNumber;
            }
        }
        
        if (self.teacher == nil || ![[self.teacher typeDescription] isEqualToString:self.typeTextField.text]) {
            TeacherType type;
            if ([self.typeTextField.text isEqualToString:@"教师"]) {
                type = TeacherTypeTeacher;
            } else {
                type = TeacherTypeAssistant;
            }
            
            self.changedInfos[@"type"] = @(type);
        }
        
        if (self.teacher == nil || ![[self.teacher authorityDescription] isEqualToString:self.authorityTextField.text]) {
            TeacherAuthority authority;
            if ([self.authorityTextField.text isEqualToString:@"超级管理员"]) {
                authority = TeacherAuthoritySuperManager;
            } else if ([self.authorityTextField.text isEqualToString:@"管理员"]) {
                authority = TeacherAuthorityManager;
            } else {
                authority = TeacherAuthorityTeacher;
            }
            
            self.changedInfos[@"authority"] = @(authority);
        }
        
        self.changedInfos[@"canManageHomeworks"] = self.homeworkManageSwitch.on?@(1):@(0);
        self.changedInfos[@"canManageClasses"] = self.classManageSwitch.on?@(1):@(0);
        self.changedInfos[@"canManageStudents"] = self.studentManageSwitch.on?@(1):@(0);
        self.changedInfos[@"canCreateRewards"] = self.rewardCreateSwitch.on?@(1):@(0);
        self.changedInfos[@"canExchangeRewards"] = self.rewardExchangeSwitch.on?@(1):@(0);
        self.changedInfos[@"canCreateNoticeMessage"] = self.noticeCreateSwitch.on?@(1):@(0);
    } while(NO);
    
    if (errorTip.length > 0) {
        
#if MANAGERSIDE
        [TIP showText:errorTip inView:self.view];
#else
        [TIP showText:errorTip inView:self.navigationController.view];
#endif
        return;
    }
    
    if (self.teacher != nil && self.changedInfos.count == 0) {
#if MANAGERSIDE
        [TIP showText:@"没有信息修改" inView:self.view];
#else
        [TIP showText:@"没有信息修改" inView:self.navigationController.view];
#endif
        return;
    }
    
    if (self.teacher != nil) {
        [HUD showProgressWithMessage:@"正在更新"];
        self.changedInfos[@"id"] = @(self.teacher.userId);
        WeakifySelf;
        [TeacherService updateTeacherWithInfos:self.changedInfos
                                      callback:^(Result *result, NSError *error) {
                                          if (error != nil) {
                                              [HUD showErrorWithMessage:@"更新失败"];
                                          } else {
                                              [HUD showWithMessage:@"更新成功"];
                                              [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfUpdateTeacher
                                                                                                  object:nil];
#if MANAGERSIDE
                                              if (weakSelf.successCallBack) {
                                                  weakSelf.successCallBack();
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
        [TeacherService createTeacherWithInfos:self.changedInfos
                                      callback:^(Result *result, NSError *error) {
                                          if (error != nil) {
                                              [HUD showErrorWithMessage:@"创建失败"];
                                          } else {
                                              [HUD showWithMessage:@"创建成功"];
                                              [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfAddTeacher
                                                                                                  object:nil];
#if MANAGERSIDE
                                              if (weakSelf.successCallBack) {
                                                  weakSelf.successCallBack();
                                              }
#else
                                              [weakSelf.navigationController popViewControllerAnimated:YES];
#endif
                                          }
                                      }];
    }
}

- (IBAction)deleteButtonPressed:(id)sender {
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

#pragma mark - Private Methods

- (void)updateSwitchsAfterAuthorityChanged:(TeacherAuthority)authourity {
    if (authourity == TeacherAuthoritySuperManager) {
        self.homeworkManageSwitch.on = YES;
        self.classManageSwitch.on = YES;
        self.studentManageSwitch.on = YES;
        self.rewardCreateSwitch.on = YES;
        self.rewardExchangeSwitch.on = YES;
        self.noticeCreateSwitch.on = YES;
    } else if (authourity == TeacherAuthorityManager) {
        self.homeworkManageSwitch.on = NO;
        self.classManageSwitch.on = NO;
        self.studentManageSwitch.on = NO;
        self.rewardCreateSwitch.on = NO;
        self.rewardExchangeSwitch.on = YES;
        self.noticeCreateSwitch.on = NO;
    } else {
        self.homeworkManageSwitch.on = NO;
        self.classManageSwitch.on = NO;
        self.studentManageSwitch.on = NO;
        self.rewardCreateSwitch.on = NO;
        self.rewardExchangeSwitch.on = NO;
        self.noticeCreateSwitch.on = NO;
    }
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
                                       if (weakSelf.successCallBack) {
                                           weakSelf.successCallBack();
                                       }
#else
                                       [weakSelf.navigationController popViewControllerAnimated:YES];
#endif
                                   }
                               }];
}

- (IBAction)hideKeyboard {
    [self.nameTextField resignFirstResponder];
    [self.phoneNumberTextField resignFirstResponder];
    [self.typeTextField resignFirstResponder];
    [self.authorityTextField resignFirstResponder];
}

@end

