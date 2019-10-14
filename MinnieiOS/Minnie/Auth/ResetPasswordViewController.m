//
//  ResetPasswordViewController.m
//  X5
//
//  Created by yebw on 2017/8/27.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "ResetPasswordViewController.h"
#import "AuthService.h"
#import "LoginViewController.h"
#import "IMManager.h"
#import "PortraitNavigationController.h"
#import "AppDelegate.h"
#import "AppDelegate+ConfigureUI.h"
@interface ResetPasswordViewController ()

@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UITextField *password1TextField;
@property (nonatomic, weak) IBOutlet UITextField *password2TextField;

@property (nonatomic, weak) IBOutlet UILabel *passwordStateLabel;
@property (nonatomic, weak) IBOutlet UILabel *password1StateLabel;
@property (nonatomic, weak) IBOutlet UILabel *password2StateLabel;

@property (nonatomic, weak) IBOutlet UIButton *passwordVisibleButton;
@property (nonatomic, weak) IBOutlet UIButton *password1VisibleButton;

@property (nonatomic, weak) IBOutlet UIButton *confirmButton;

@end

@implementation ResetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.password1TextField addTarget:self action:@selector(password1TextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.password2TextField addTarget:self action:@selector(password2TextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.passwordStateLabel.hidden = YES;
    self.password1StateLabel.hidden = YES;
    self.password2StateLabel.hidden = YES;
    
    self.confirmButton.layer.cornerRadius = 6.f;
    self.confirmButton.layer.masksToBounds = YES;
    
    self.confirmButton.backgroundColor = nil;
    [self.confirmButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:1.f]] forState:UIControlStateNormal];
    [self.confirmButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:.8f]] forState:UIControlStateHighlighted];
    [self.confirmButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0xDD/255.f green:0xDD/255.f blue:0xDD/255.f alpha:1.f]] forState:UIControlStateDisabled];
}

- (void)dealloc {
}

- (IBAction)backButtonPressed:(id)sender {
 
    if (self.closeViewCallBack) {
        self.closeViewCallBack();
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)confirmButtonPressed:(id)sender {
    NSString *password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password1 = [self.password1TextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password2 = [self.password2TextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (password.length == 0) {
        self.passwordStateLabel.hidden = NO;
        self.passwordStateLabel.text = @"请输入密码";
        
        return;
    } else if (![Utils checkPassword:password]) {
        self.passwordStateLabel.hidden = NO;
        self.passwordStateLabel.text = @"密码格式不正确，请输入4-8位数字或字母";
        
        return;
    } else if (password1.length == 0) {
        self.passwordStateLabel.hidden = YES;
        self.password1StateLabel.hidden = NO;
        self.password1StateLabel.text = @"请输入新密码";
        
        return;
    } else if (![Utils checkPassword:password1]) {
        self.passwordStateLabel.hidden = YES;
        self.password1StateLabel.hidden = NO;
        self.password1StateLabel.text = @"密码格式不正确，请输入4-8位数字或字母";
        
        return;
    } else if (password2.length == 0) {
        self.passwordStateLabel.hidden = YES;
        self.password1StateLabel.hidden = YES;
        self.password2StateLabel.hidden = NO;
        self.password2StateLabel.text = @"请再次输入新密码";
        
        return;
    } else if (![Utils checkPassword:password2]) {
        self.passwordStateLabel.hidden = YES;
        self.password1StateLabel.hidden = YES;
        self.password2StateLabel.hidden = NO;
        self.password2StateLabel.text = @"密码格式不正确，请输入4-8位数字或字母";
        
        return;
    } else if (![password1 isEqualToString:password2]) {
        self.passwordStateLabel.hidden = YES;
        self.password1StateLabel.hidden = YES;
        self.password2StateLabel.hidden = NO;
        self.password2StateLabel.text = @"两次输入新密码不一致";
        
        return;
    }
    
    [HUD showProgressWithMessage:@"正在修改密码"];
    [AuthService resetPasswordWithPassword:password
                               newPassword:password1
                               phoneNumber:self.phoneNumber
                                  callback:^(Result *result, NSError *error) {
                                      if (error != nil) {
                                          [HUD showErrorWithMessage:@"密码修改失败"];
                                      } else {
                                          [HUD showWithMessage:@"密码修改成功"];

                                          if ([self.phoneNumber isEqualToString:APP.currentUser.phoneNumber]) {
                                              
                                              AppDelegate * app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                              [app logout];
                                          } else {
                                              // 修改其他老师
                                              if (self.closeViewCallBack) {
                                                  self.closeViewCallBack();
                                              }
                                              [self.navigationController popViewControllerAnimated:YES];
                                          }
                                      }
                                  }];
}

- (IBAction)showPasswordButtonPressed:(id)sender {
    self.passwordTextField.secureTextEntry = !self.passwordTextField.isSecureTextEntry;
    
    // 下面三句莫名其妙的代码是为了解决切换时候光标定位不对的问题
    NSString *originalText = self.passwordTextField.text;
    self.passwordTextField.text = nil;
    self.passwordTextField.text = originalText;
    
    if (self.passwordTextField.isSecureTextEntry) {
        [self.passwordVisibleButton setImage:[UIImage imageNamed:@"label_eye_display"] forState:UIControlStateNormal];
    } else {
        [self.passwordVisibleButton setImage:[UIImage imageNamed:@"label_ic_eye_hide"] forState:UIControlStateNormal];
    }
}

- (IBAction)showPassword1ButtonPressed:(id)sender {
    self.password1TextField.secureTextEntry = !self.password1TextField.isSecureTextEntry;
    
    // 下面三句莫名其妙的代码是为了解决切换时候光标定位不对的问题
    NSString *originalText = self.password1TextField.text;
    self.password1TextField.text = nil;
    self.password1TextField.text = originalText;
    
    if (self.password1TextField.isSecureTextEntry) {
        [self.password1VisibleButton setImage:[UIImage imageNamed:@"label_eye_display"] forState:UIControlStateNormal];
    } else {
        [self.password1VisibleButton setImage:[UIImage imageNamed:@"label_ic_eye_hide"] forState:UIControlStateNormal];
    }
}

- (IBAction)hideKeyboard {
    [self.passwordTextField resignFirstResponder];
    [self.password1TextField resignFirstResponder];
    [self.password2TextField resignFirstResponder];
}

#pragma mark - Private Methods

- (void)passwordTextFieldDidChange:(UITextField *)textField {
    self.passwordStateLabel.hidden = YES;
}

- (void)password1TextFieldDidChange:(UITextField *)textField {
    self.password1StateLabel.hidden = YES;
}

- (void)password2TextFieldDidChange:(UITextField *)textField {
    self.password2StateLabel.hidden = YES;
}

@end

