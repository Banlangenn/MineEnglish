//
//  SettingsViewController.m
//  X5
//
//  Created by yebw on 2017/8/27.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "SettingsViewController.h"
#import "ResetPasswordViewController.h"
#import "SettingTableViewCell.h"
#import <SDWebImage/SDImageCache.h>
#import "AuthService.h"
#import "UIColor+HEX.h"
#import "Application.h"
#import "TIP.h"
#import "Utils.h"
#import "LoginViewController.h"
#import "IMManager.h"
#import "PortraitNavigationController.h"
#import "AppDelegate.h"
@interface SettingsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton *logoutButton;
@property (nonatomic, weak) IBOutlet UITableView *settingsTableView;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.logoutButton.layer.cornerRadius = 12.f;
    self.logoutButton.layer.masksToBounds = YES;
    self.logoutButton.layer.borderWidth = 0.5;
    self.logoutButton.layer.borderColor = [UIColor colorWithHex:0xFF4858].CGColor;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

#pragma mark - IBAction

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)logoutButtonPressed:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认退出当前用户？"
                                                                             message:@"退出应用将无法接收到新的作业和通知！"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"退出"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self doLogout];
                                                          }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Private Methods

- (void)doLogout {
    [AuthService logoutWithCallback:^(Result *result, NSError *error) {
        //新增 by shidongdong
        AppDelegate * app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [app removeRemoteNotification];
        Application.sharedInstance.currentUser = nil;
        [[IMManager sharedManager] logout];
        [APP clearData];
        NSString *nibName = nil;
#if TEACHERSIDE
        nibName = @"LoginViewController_Teacher";
#else
        nibName = @"LoginViewController_Student";
#endif
        LoginViewController *loginVC = [[LoginViewController alloc] initWithNibName:nibName bundle:nil];
        
        PortraitNavigationController *loginNC = [[PortraitNavigationController alloc] initWithRootViewController:loginVC];
        self.view.window.rootViewController = loginNC;
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SettingTableViewCellId];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SettingTableViewCell class]) owner:nil options:nil] lastObject];
    }
    
    if (indexPath.row == 0) {
        cell.itemLabel.text = @"修改密码";
        cell.detailLabel.hidden = YES;
        cell.actionLabel.hidden = YES;
        cell.iconImageView.hidden = NO;
        cell.iconImageView.image = [UIImage imageNamed:@"label_ic_into"];
    } else if (indexPath.row == 1) {
        cell.itemLabel.text = @"清除缓存";
        cell.detailLabel.hidden = NO;
        
        NSUInteger size = [[SDImageCache sharedImageCache] getSize];
        
        cell.detailLabel.text = [Utils formatedSizeString:(long long)(size)];
        cell.actionLabel.hidden = YES;
        cell.iconImageView.hidden = YES;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.row == 0) {
        ResetPasswordViewController *resetPasswordVC = [[ResetPasswordViewController alloc] initWithNibName:[[ResetPasswordViewController class] description] bundle:nil];
        [self.navigationController pushViewController:resetPasswordVC animated:YES];
    } else if (indexPath.row == 1) {
        [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
        
        [self.settingsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];

        [TIP showText:@"缓存已清理" inView:self.view];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return SettingTableViewCellHeight;
}

@end

