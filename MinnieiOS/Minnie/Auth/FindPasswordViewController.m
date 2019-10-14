//
//  FindPasswordViewController.m
// X5
//
//  Created by yebw on 2017/8/23.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "FindPasswordViewController.h"
#import "AuthService.h"

@interface FindPasswordViewController ()

@property (nonatomic, weak) IBOutlet UITextField *password1TextField;
@property (nonatomic, weak) IBOutlet UITextField *password2TextField;

@property (nonatomic, weak) IBOutlet UILabel *password1StateLabel;
@property (nonatomic, weak) IBOutlet UILabel *password2StateLabel;

@property (nonatomic, weak) IBOutlet UIButton *passwordVisibleButton;

@property (nonatomic, weak) IBOutlet UIButton *confirmButton;

@end

@implementation FindPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.password1TextField addTarget:self action:@selector(password1TextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.password2TextField addTarget:self action:@selector(password2TextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.password1StateLabel.hidden = YES;
    self.password2StateLabel.hidden = YES;
    
    self.confirmButton.layer.cornerRadius = 6.f;
    self.confirmButton.layer.masksToBounds = YES;
    
    self.confirmButton.backgroundColor = nil;
    [self.confirmButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:1.f]] forState:UIControlStateNormal];
    [self.confirmButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:.8f]] forState:UIControlStateHighlighted];
    [self.confirmButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0xDD/255.f green:0xDD/255.f blue:0xDD/255.f alpha:1.f]] forState:UIControlStateDisabled];
}


- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)confirmButtonPressed:(id)sender {
    NSString *password1 = [self.password1TextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password2 = [self.password2TextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (password1.length == 0) {
        self.password1StateLabel.hidden = NO;
        self.password1StateLabel.text = @"请输入密码";
        
        return;
    } else if (![Utils checkPassword:password1]) {
        self.password1StateLabel.hidden = NO;
        self.password1StateLabel.text = @"密码格式不正确，请输入4-8位数字或字母";
        
        return;
    } else if (password2.length == 0) {
        self.password1StateLabel.hidden = YES;
        self.password2StateLabel.hidden = NO;
        self.password2StateLabel.text = @"请再次输入密码";
        
        return;
    } else if (![Utils checkPassword:password2]) {
        self.password1StateLabel.hidden = YES;
        self.password2StateLabel.hidden = NO;
        self.password2StateLabel.text = @"密码格式不正确，请输入4-8位数字或字母";
        
        return;
    } else if (![password1 isEqualToString:password2]) {
        self.password1StateLabel.hidden = YES;
        self.password2StateLabel.hidden = NO;
        self.password2StateLabel.text = @"两次输入密码不一致";
        
        return;
    }
    
    [AuthService findPasswordWithPhoneNumber:self.phoneNumber
                                    password:password1
                                        code:self.code
                                    callback:^(Result *result, NSError *error) {
                                        if (error == nil) {
                                            [HUD showErrorWithMessage:@"密码设置成功"];
                                            [self.navigationController popToRootViewControllerAnimated:YES];
                                        } else {
                                            
                                            if (error.code == 105 || error.code == 106) {
                                                NSString *message = error.userInfo[@"NSLocalizedDescription"];
                                                [HUD showErrorWithMessage:message];
                                            } else {
                                                [HUD showErrorWithMessage:@"密码修改失败"];
                                            }
                                        }
                                    }];
}

- (IBAction)showPasswordButtonPressed:(id)sender {
    self.password1TextField.secureTextEntry = !self.password1TextField.isSecureTextEntry;
    
    // 下面三句莫名其妙的代码是为了解决切换时候光标定位不对的问题
    NSString *originalText = self.password1TextField.text;
    self.password1TextField.text = nil;
    self.password1TextField.text = originalText;
    
    if (self.password1TextField.isSecureTextEntry) {
        [self.passwordVisibleButton setImage:[UIImage imageNamed:@"label_eye_display"] forState:UIControlStateNormal];
    } else {
        [self.passwordVisibleButton setImage:[UIImage imageNamed:@"label_ic_eye_hide"] forState:UIControlStateNormal];
    }
}

- (IBAction)hideKeyboard {
    [self.password1TextField resignFirstResponder];
    [self.password2TextField resignFirstResponder];
}

#pragma mark - Private Methods

- (void)password1TextFieldDidChange:(UITextField *)textField {
    self.password1StateLabel.hidden = YES;
}

- (void)password2TextFieldDidChange:(UITextField *)textField {
    self.password2StateLabel.hidden = YES;
}

@end

