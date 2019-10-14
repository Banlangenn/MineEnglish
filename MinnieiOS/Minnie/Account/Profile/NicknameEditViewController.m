//
//  NicknameEditViewController.m
//  X5
//
//  Created by yebw on 2017/9/13.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "NicknameEditViewController.h"
#import "UIColor+HEX.h"
#import "ProfileService.h"

@interface NicknameEditViewController ()<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UITextField *nicknameTextField;


@end

@implementation NicknameEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.nicknameTextField.text = APP.currentUser.nickname;
    [self.nicknameTextField addTarget:self action:@selector(changeText:) forControlEvents:UIControlEventEditingChanged];
    self.contentView.layer.cornerRadius = 12.f;
    self.contentView.layer.shadowOpacity = 0.4;// 阴影透明度
    self.contentView.layer.shadowColor = [UIColor colorWithHex:0xEEEEEE].CGColor;
    self.contentView.layer.shadowRadius = 3;
    self.contentView.layer.shadowOffset = CGSizeMake(2, 4);
}

- (void)changeText:(UITextField *)textField{
    
    NSString * str = textField.text;
    if (str.length > 10) {
        self.nicknameTextField.text = [str substringToIndex:10];
    }
}
- (void)backButtonPressed:(id)sender {
  
    NSString *name = [self.nicknameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // 未修改
    if ([name isEqualToString:APP.currentUser.nickname]) {
        
        [super backButtonPressed:sender];
        return;
    }
    
    if (name.length > 0 && name.length <= 10) {
        [self updateNickname:name];
    } else {
        [HUD showErrorWithMessage:@"昵称长度1-10个字符"];
    }
}

- (void)dealloc {
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.nicknameTextField becomeFirstResponder];
}

- (IBAction)hideKeyboard:(id)sender {
    [self.nicknameTextField resignFirstResponder];
}

#pragma mark - Update
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  
    NSString *name = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (name.length < 1 || name.length > 10) {
        [HUD showErrorWithMessage:@"昵称长度1-10个字符"];
    } else {
        [self updateNickname:name];
    }
    
    return NO;
}

- (void)updateNickname:(NSString *)name {
   
    [HUD showProgressWithMessage:@"正在修改昵称..."];
    [ProfileService updateNickname:name
                          callback:^(Result *result, NSError *error) {
                              if (error != nil) {
                                  [HUD showErrorWithMessage:@"昵称修改失败"];
                              } else {
                                  [HUD showWithMessage:@"昵称修改成功"];
                                  
#if TEACHERSIDE
                                  Teacher *teacher = APP.currentUser;
                                  teacher.nickname = name;
                                  APP.currentUser = teacher;
#else
                                  Student *student = APP.currentUser;
                                  student.nickname = name;
                                  APP.currentUser = student;
#endif
                                  
                                  [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfProfileUpdated object:nil];
                              }
                              [super backButtonPressed:nil];
                          }];
}

@end
