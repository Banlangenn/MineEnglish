//
//  RegisterViewController.m
// X5
//
//  Created by yebw on 2017/8/23.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "RegisterViewController.h"
#import "FullfillProfileViewController.h"
#import "AuthService.h"
#import "HUD.h"
#import "Result.h"

@interface RegisterViewController ()

@property (nonatomic, weak) IBOutlet UITextField *phoneNumberTextField;
@property (nonatomic, weak) IBOutlet UITextField *codeTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;

@property (nonatomic, weak) IBOutlet UILabel *phoneNumberStateLabel;
@property (nonatomic, weak) IBOutlet UILabel *passwordStateLabel;
@property (nonatomic, weak) IBOutlet UILabel *codeStateLabel;

@property (nonatomic, weak) IBOutlet UIButton *passwordVisibleButton;
@property (nonatomic, weak) IBOutlet UIButton *sendCodeButton;
@property (nonatomic, weak) IBOutlet UIButton *registerButton;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.phoneNumberTextField addTarget:self action:@selector(phoneNumberTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordTextField addTarget:self action:@selector(passwordTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.codeTextField addTarget:self action:@selector(codeTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.phoneNumberStateLabel.hidden = YES;
    self.passwordStateLabel.hidden = YES;
    self.codeStateLabel.hidden = YES;
    
    self.sendCodeButton.layer.cornerRadius = 6.f;
    self.sendCodeButton.layer.masksToBounds = YES;
    
    [self.sendCodeButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0xCE/255.f blue:0 alpha:1.f]] forState:UIControlStateNormal];
    [self.sendCodeButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0xCE/255.f blue:0 alpha:.8f]] forState:UIControlStateHighlighted];
    [self.sendCodeButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0xDD/255.f green:0xDD/255.f blue:0xDD/255.f alpha:1.f]] forState:UIControlStateDisabled];
    
    self.registerButton.layer.cornerRadius = 6.f;
    self.registerButton.layer.masksToBounds = YES;
    
    self.registerButton.backgroundColor = nil;
    [self.registerButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:1.f]] forState:UIControlStateNormal];
    [self.registerButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:.8f]] forState:UIControlStateHighlighted];
    [self.registerButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0xDD/255.f green:0xDD/255.f blue:0xDD/255.f alpha:1.f]] forState:UIControlStateDisabled];
    
    self.registerButton.enabled = NO;
}

- (void)dealloc {
}

- (IBAction)backButtonPressed:(id)sender {
    [self.timer invalidate];
    self.timer = nil;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sendCodeButtonPressed:(id)sender {
    NSString *phoneNumber = [self.phoneNumberTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (phoneNumber.length == 0 || ![Utils checkTelNumber:phoneNumber]) {
        self.phoneNumberStateLabel.hidden = NO;
        self.phoneNumberStateLabel.text = @"请输入正确的手机号码";
        
        return;
    }
    
    //    [HUD showProgressWithMessage:@"正在请求验证码"];
    [AuthService askForSMSCodeWithPhoneNumber:phoneNumber
                                     callback:^(Result *result, NSError *error) {
                                         if (error != nil) {
                                             [HUD showErrorWithMessage:@"验证码请求失败"];
                                         } else {
                                             self.registerButton.enabled = YES;
                                             [self startTiming];
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

- (IBAction)registerButtonPressed:(id)sender {
    NSString *phoneNumber = [self.phoneNumberTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *code = [self.codeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (phoneNumber.length == 0 || ![Utils checkTelNumber:phoneNumber]) {
        self.phoneNumberStateLabel.hidden = NO;
        self.phoneNumberStateLabel.text = @"请输入正确的手机号码";
        
        return;
    } else if (password.length == 0) {
        self.phoneNumberStateLabel.hidden = YES;
        self.passwordStateLabel.hidden = NO;
        self.passwordStateLabel.text = @"请输入密码";
        
        return;
    } else if (![Utils checkPassword:password]) {
        self.phoneNumberStateLabel.hidden = YES;
        self.passwordStateLabel.hidden = NO;
        self.passwordStateLabel.text = @"密码格式不正确，请输入4-8位数字或字母";
        
        return;
    } else if (code.length == 0) {
        self.phoneNumberStateLabel.hidden = YES;
        self.passwordStateLabel.hidden = YES;
        self.codeStateLabel.hidden = NO;
        self.codeStateLabel.text = @"请输入验证码";
        
        return;
    }
    
    [AuthService registerWithPhoneNumber:phoneNumber
                                password:password
                                    code:code
                                callback:^(Result *result, NSError *error) {
                                    if (error == nil) {
                                        NSLog(@"注册成功");
                                        
                                        User *user = nil;
                                        NSString *nibName = nil;
#if TEACHERSIDE | MANAGERSIDE
                                        Teacher *teacher = (Teacher *)(result.userInfo);
                                        [APP setCurrentUser:teacher];
                                        user = teacher;
                                        
                                        nibName = @"FullfillProfileViewController_Teacher";
                                        
#else
                                        Student *student = (Student *)(result.userInfo);
                                        [APP setCurrentUser:student];
                                        user = student;
                                        
                                        nibName = @"FullfillProfileViewController_Student";
#endif
                                        
                                        [BaseRequest setToken:APP.currentUser.token];
                                        
                                        FullfillProfileViewController *fullfillProfileVC = [[FullfillProfileViewController alloc] initWithNibName:nibName bundle:nil];
                                        [self.navigationController pushViewController:fullfillProfileVC animated:YES];
                                    } else {
                                        if (error.code == 101) {
                                            [HUD showErrorWithMessage:@"该账号已注册，请直接登陆"];
                                        } else if (error.code == 102) {
                                            [HUD showErrorWithMessage:@"验证码错误"];
                                        } else if (error.code == 105) {
                                            [HUD showErrorWithMessage:@"该手机号已在教师端注册"];
                                        } else {
                                            [HUD showErrorWithMessage:@"注册失败"];
                                        }
                                    }
                                }];
}

- (IBAction)hideKeyboard {
    [self.phoneNumberTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.codeTextField resignFirstResponder];
}

#pragma mark - Private Methods

- (void)phoneNumberTextFieldDidChange:(UITextField *)textField {
    self.phoneNumberStateLabel.hidden = YES;
}

- (void)passwordTextFieldDidChange:(UITextField *)textField {
    self.passwordStateLabel.hidden = YES;
}

- (void)codeTextFieldDidChange:(UITextField *)textField {
    self.codeStateLabel.hidden = YES;
}

- (void)startTiming {
    self.sendCodeButton.enabled = NO;
    __block NSUInteger secondsLeft = 60;
    __weak RegisterViewController *weakSelf = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.f
                                                 repeats:YES
                                                   block:^(NSTimer * _Nonnull timer) {
                                                       if (secondsLeft == 0) {
                                                           [weakSelf.timer invalidate];
                                                           weakSelf.timer = nil;
                                                           weakSelf.sendCodeButton.enabled = YES;
                                                           [weakSelf.sendCodeButton setTitle:@"重新发送" forState:UIControlStateNormal];
                                                           
                                                           return;
                                                       }
                                                       
                                                       [weakSelf.sendCodeButton setTitle:[NSString stringWithFormat:@"重新发送 %zds", (secondsLeft--)] forState:UIControlStateNormal];
                                                   }];
}

@end

