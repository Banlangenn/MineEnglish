//
//  LoginViewController.m
// X5
//
//  Created by yebw on 2017/8/23.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "LoginViewController.h"
#import "InputPhoneNumberViewController.h"
#import "AuthService.h"
#import "RegisterViewController.h"
#import "Result.h"
#import "Teacher.h"
#import "Student.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "FullfillProfileViewController.h"
#import "AppDelegate.h"
@interface LoginViewController ()<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *usernameTextField;
@property (nonatomic, weak) IBOutlet UILabel *usernameStateLabel;

@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UILabel *passwordStateLabel;

@property (nonatomic, weak) IBOutlet UIButton *loginButton;
@property (nonatomic, weak) IBOutlet UIButton *registerButton;
@property (nonatomic, weak) IBOutlet UIButton *passwordVisibleButton;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *centerYOffsetConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *loginButtonTopConstraint;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

      AVAudioSession* sharedSession = [AVAudioSession sharedInstance];
      [sharedSession requestRecordPermission:^(BOOL granted) {
      }];
    
    
    [self.navigationController setNavigationBarHidden:YES];
    
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    if (height >= 736) {
        self.centerYOffsetConstraint.constant = -35.f;
    } else if (height >= 667) {
        self.centerYOffsetConstraint.constant = -40.f;
    } else {
        self.centerYOffsetConstraint.constant = -55.f;
        self.loginButtonTopConstraint.constant = 20.f;
    }
    
    self.usernameTextField.text = [APP lastLoginUsename];
    
    [self.usernameTextField addTarget:self action:@selector(usernameTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordTextField addTarget:self action:@selector(passwordTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    self.usernameStateLabel.hidden = YES;
    self.passwordStateLabel.hidden = YES;
    
    self.loginButton.layer.cornerRadius = 6.f;
    self.loginButton.layer.masksToBounds = YES;
    
    self.loginButton.backgroundColor = nil;
    [self.loginButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:1.f]] forState:UIControlStateNormal];
    [self.loginButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:.8f]] forState:UIControlStateHighlighted];
    
    self.registerButton.layer.cornerRadius = 6.f;
    self.registerButton.layer.masksToBounds = YES;
    self.registerButton.layer.borderWidth = 0.5;
    self.registerButton.layer.borderColor = [UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:1.f].CGColor;
}

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - IBAction

- (IBAction)loginButtonPressed:(id)sender {
    NSString *username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (username.length == 0 ) {
#if TEACHERSIDE | MANAGERSIDE
#else
        if (![Utils checkTelNumber:username])
        {
            return;
        }
#endif
        self.usernameStateLabel.hidden = NO;
        self.usernameStateLabel.text = @"请输入正确的手机号码";
        
        return;
    } else if (password.length == 0) {
        self.usernameStateLabel.hidden = YES;
        self.passwordStateLabel.hidden = NO;
        self.passwordStateLabel.text = @"密码不能为空";
        
        return;
    } else if (![Utils checkPassword:password]) {
        self.usernameStateLabel.hidden = YES;
        self.passwordStateLabel.hidden = NO;
        self.passwordStateLabel.text = @"密码格式不正确，请输入4-8位数字或字母";
        
        return;
    }
    
    [HUD showProgressWithMessage:@"正在登录"];
    
    [AuthService loginWithPhoneNumber:username
                             password:password
                             callback:^(Result *result, NSError *error) {
                                 if (error == nil) {
                                     NSLog(@"%@", @"登录成功");
                                     
                                     [HUD hideAnimated:YES];

                                     [APP setLastLoginUsename:username];
                                     
                                     //新增 by shidongdong
                                     
                            
                                     if (result.userInfo != nil) {
                                         User *user = nil;
#if TEACHERSIDE | MANAGERSIDE
                                         Teacher *teacher = (Teacher *)(result.userInfo);
                                         [APP setCurrentUser:teacher];
                                         user = teacher;
#else
                                         Student *student = (Student *)(result.userInfo);
                                         [APP setCurrentUser:student];
                                         user = student;
#endif
                                         
                                         
                                         
                                         [BaseRequest setToken:APP.currentUser.token];
                                         
                                         if (user.avatarUrl == nil || user.nickname == nil) {
#if TEACHERSIDE | MANAGERSIDE
                                             FullfillProfileViewController *vc = [[FullfillProfileViewController alloc] initWithNibName:@"FullfillProfileViewController_Teacher" bundle:nil];
#else
                                             FullfillProfileViewController *vc = [[FullfillProfileViewController alloc] initWithNibName:@"FullfillProfileViewController_Student" bundle:nil];
#endif
                                             [self.navigationController pushViewController:vc animated:YES];
                                         } else {
                                             [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfLoginSuccess
                                                                                                 object:nil];
                                         }
                                         
                                         AppDelegate * app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                         [app openRemoteNotification];
                                         
                                     } else {
                                         [HUD showErrorWithMessage:@"登录失败"];
                                     }
                                 } else {
                                     if (error.code == 100) {
                                         
                                         [HUD showErrorWithMessage:@"登录失败, 用户名或密码错误"];
                                     } else if (error.code == 103) {
                                         [HUD showErrorWithMessage:@"帐号不存在"];
                                     } else if (error.code == 105 || error.code == 106) {
                                         NSString *message = error.userInfo[@"NSLocalizedDescription"];
                                         [HUD showErrorWithMessage:message];
                                     } else {
                                         [HUD showErrorWithMessage:@"登录失败"];
                                     }
                                 }
                             }];
}

- (IBAction)registerButtonPressed:(id)sender {
    RegisterViewController *vc = [[RegisterViewController alloc] initWithNibName:NSStringFromClass([RegisterViewController class]) bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)findPasswordButtonPressed:(id)sender {
    InputPhoneNumberViewController *vc = [[InputPhoneNumberViewController alloc] initWithNibName:NSStringFromClass([InputPhoneNumberViewController class]) bundle:nil];
    vc.actionType = InputPhoneNumberActionFindPassword;
    [self.navigationController pushViewController:vc animated:YES];
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

- (IBAction)hideKeyboard {
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
}

- (void)keyboardFrameWillChange:(NSNotification *)notification {
    NSValue *endValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect kbFrame = [endValue CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:nil];
    
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    CGFloat offset = 0;
    if (kbFrame.origin.y >= self.view.bounds.size.height) { // 键盘隐藏
    } else { // 键盘显示
        if (height >= 736) {
            offset = -80.f;
        } else if (height >= 667) {
            offset = -60.f;
        } else {
            offset = -20.f;
        }
    }
    
    if (height >= 736) {
        self.centerYOffsetConstraint.constant = -35.f + offset;
    } else if (height >= 667) {
        self.centerYOffsetConstraint.constant = -40.f + offset;
    } else {
        self.centerYOffsetConstraint.constant = -55.f + offset;
        self.loginButtonTopConstraint.constant = 20.f;
    }
    
    [UIView animateWithDuration:0.45f
                     animations:^{
                         [self.view layoutIfNeeded];
                     }];
}

#pragma mark - Private Methods

- (void)usernameTextFieldDidChange:(UITextField *)textField {
    self.usernameStateLabel.hidden = YES;
}

- (void)passwordTextFieldDidChange:(UITextField *)textField {
    self.passwordStateLabel.hidden = YES;
}

@end


