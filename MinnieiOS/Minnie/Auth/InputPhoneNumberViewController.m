//
//  RegisterViewController.m
// X5
//
//  Created by yebw on 2017/8/23.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "InputPhoneNumberViewController.h"
#import "FindPasswordViewController.h"
#import "AuthService.h"

@interface InputPhoneNumberViewController ()

@property (nonatomic, weak) IBOutlet UITextField *phoneNumberTextField;
@property (nonatomic, weak) IBOutlet UITextField *codeTextField;

@property (nonatomic, weak) IBOutlet UILabel *phoneNumberStateLabel;
@property (nonatomic, weak) IBOutlet UILabel *codeStateLabel;

@property (nonatomic, weak) IBOutlet UIButton *sendCodeButton;
@property (nonatomic, weak) IBOutlet UIButton *nextButton;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation InputPhoneNumberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.actionType == InputPhoneNumberActionFindPassword) {
        self.customTitleLabel.text = @"找回密码";
    }
    
    [self.phoneNumberTextField addTarget:self action:@selector(phoneNumberTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.codeTextField addTarget:self action:@selector(codeTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.phoneNumberStateLabel.hidden = YES;
    self.codeStateLabel.hidden = YES;
    
    self.sendCodeButton.layer.cornerRadius = 6.f;
    self.sendCodeButton.layer.masksToBounds = YES;
    
    [self.sendCodeButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0xCE/255.f blue:0 alpha:1.f]] forState:UIControlStateNormal];
    [self.sendCodeButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0xCE/255.f blue:0 alpha:.8f]] forState:UIControlStateHighlighted];
    [self.sendCodeButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0xDD/255.f green:0xDD/255.f blue:0xDD/255.f alpha:1.f]] forState:UIControlStateDisabled];
    
    self.nextButton.layer.cornerRadius = 6.f;
    self.nextButton.layer.masksToBounds = YES;
    
    self.nextButton.backgroundColor = nil;
    [self.nextButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:1.f]] forState:UIControlStateNormal];
    [self.nextButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:.8f]] forState:UIControlStateHighlighted];
    [self.nextButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0xDD/255.f green:0xDD/255.f blue:0xDD/255.f alpha:1.f]] forState:UIControlStateDisabled];
    
    self.nextButton.enabled = NO;
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
                                         //                                         if (error != nil) {
                                         //                                             [HUD showErrorWithMessage:@"验证码请求失败"];
                                         //                                         } else {
                                         self.nextButton.enabled = YES;
                                         [self startTiming];
                                         //                                         }
                                     }];
}

- (IBAction)nextButtonPressed:(id)sender {
    NSString *phoneNumber = [self.phoneNumberTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *code = [self.codeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (phoneNumber.length == 0 || ![Utils checkTelNumber:phoneNumber]) {
        self.phoneNumberStateLabel.hidden = NO;
        self.phoneNumberStateLabel.text = @"请输入正确的手机号码";
        
        return;
    } else if (code.length == 0) {
        self.codeStateLabel.hidden = NO;
        self.codeStateLabel.text = @"请输入验证码";
        
        return;
    }
    
    if (self.actionType == InputPhoneNumberActionFindPassword) {
        FindPasswordViewController *vc = [[FindPasswordViewController alloc] initWithNibName:NSStringFromClass([FindPasswordViewController class]) bundle:nil];
        vc.phoneNumber = phoneNumber;
        vc.code = code;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (IBAction)hideKeyboard {
    [self.phoneNumberTextField resignFirstResponder];
    [self.codeTextField resignFirstResponder];
}

#pragma mark - Private Methods

- (void)phoneNumberTextFieldDidChange:(UITextField *)textField {
    self.phoneNumberStateLabel.hidden = YES;
}

- (void)codeTextFieldDidChange:(UITextField *)textField {
    self.codeStateLabel.hidden = YES;
}

- (void)startTiming {
    self.sendCodeButton.enabled = NO;
    
    __block NSUInteger secondsLeft = 60;
    __weak InputPhoneNumberViewController *weakSelf = self;
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
