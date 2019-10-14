//
//  SettingsViewController.m
//  X5
//
//  Created by yebw on 2017/8/27.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "UIColor+HEX.h"
#import "Application.h"
#import "IMManager.h"
#import "AppDelegate.h"
#import "DownloadCacheVideo.h"
#import "LoginViewController.h"
#import "SettingTableViewCell.h"
#import "SettingsViewController.h"
#import "AppDelegate+ConfigureUI.h"
#import <SDWebImage/SDImageCache.h>
#import "ResetPasswordViewController.h"
#import "PortraitNavigationController.h"

@interface SettingsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton *logoutButton;
@property (nonatomic, weak) IBOutlet UITableView *settingsTableView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *rightLineView;

@property (assign,nonatomic) NSInteger currentIndex;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.backButton.hidden = self.hiddenBackBtn;
    self.logoutButton.layer.cornerRadius = 12.f;
    self.logoutButton.layer.masksToBounds = YES;
    self.logoutButton.layer.borderWidth = 0.5;
    self.logoutButton.layer.borderColor = [UIColor colorWithHex:0xFF4858].CGColor;
    
#if MANAGERSIDE
    self.currentIndex = -1;
    self.rightLineView.hidden = NO;
#else
    self.rightLineView.hidden = YES;
#endif
}

- (void)dealloc {
    
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

    alertController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Private Methods

- (void)doLogout {

    AppDelegate * app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [app logout];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SettingTableViewCellId];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SettingTableViewCell class]) owner:nil options:nil] lastObject];
    }
    
    [cell setupSelectedState:NO];
    if (indexPath.row == 0) {
        cell.itemLabel.text = @"修改密码";
        cell.detailLabel.hidden = YES;
        cell.actionLabel.hidden = YES;
        cell.iconImageView.hidden = NO;
        cell.iconImageView.image = [UIImage imageNamed:@"label_ic_into"];
#if MANAGERSIDE
        if (self.currentIndex == 0) {
            [cell setupSelectedState:YES];
        }
#endif
    } else if (indexPath.row == 1) {
        
        cell.itemLabel.text = @"视频播放选项";
        cell.detailLabel.hidden = NO;
        
        NSInteger playMode = [[Application sharedInstance] playMode];
        if (playMode == 1)// 在线播放
        {
            cell.detailLabel.text =  @"在线播放    ";
        }
        else
        {
            cell.detailLabel.text =  @"缓存播放    ";
        }
        
        cell.actionLabel.hidden = YES;
        cell.iconImageView.hidden = NO;
        
    }
    else if (indexPath.row == 2)
    {
        cell.itemLabel.text = @"清除缓存";
        cell.detailLabel.hidden = NO;
        
        NSUInteger imageSize = [[SDImageCache sharedImageCache] getSize];
        NSUInteger cacheSize = [DownloadCacheVideo sizeCachesDirectory].integerValue;
        cacheSize = 0;
        NSUInteger size = imageSize + cacheSize;
        
        cell.detailLabel.text = [Utils formatedSizeString:(long long)(size)];
        cell.actionLabel.hidden = YES;
        cell.iconImageView.hidden = YES;
    }
    else
    {
        cell.itemLabel.text = @"当前版本";
        cell.detailLabel.hidden = NO;
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        cell.detailLabel.text =  [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        cell.actionLabel.hidden = YES;
        cell.iconImageView.hidden = YES;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
#if MANAGERSIDE
    if (self.currentIndex == 0 && indexPath.row != 0) {
        
        if (self.popResetPasswordVCCallBack) {
            self.popResetPasswordVCCallBack();
        }
    }
    self.currentIndex = indexPath.row;
    [tableView reloadData];
#endif
    if (indexPath.row == 0) {
        
        ResetPasswordViewController *resetPasswordVC = [[ResetPasswordViewController alloc] initWithNibName:[[ResetPasswordViewController class] description] bundle:nil];
        resetPasswordVC.phoneNumber = APP.currentUser.phoneNumber;
#if MANAGERSIDE
        WeakifySelf;
        resetPasswordVC.closeViewCallBack = ^{
          
            weakSelf.currentIndex = -1;
            [tableView reloadData];
        };
        if (self.pushCallBack) {
            self.pushCallBack(resetPasswordVC);
        }
#else
    [self.navigationController pushViewController:resetPasswordVC animated:YES];
#endif
    }
    else if (indexPath.row == 1)
    {
        UIAlertController *alertVC;
        // 适配ipad版本
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            
            alertVC = [UIAlertController alertControllerWithTitle:nil
                                                          message:nil
                                                   preferredStyle:UIAlertControllerStyleActionSheet];
        } else {
            alertVC = [UIAlertController alertControllerWithTitle:nil
                                                          message:nil
                                                   preferredStyle:UIAlertControllerStyleAlert];
        }
        UIAlertAction * cacheAction = [UIAlertAction actionWithTitle:@"缓存播放"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               [Application sharedInstance].playMode = 0;
                                                               SettingTableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                                                               cell.detailLabel.text =  @"缓存播放    ";
                                                           }];
        UIAlertAction * noCacheAction = [UIAlertAction actionWithTitle:@"在线播放"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 [Application sharedInstance].playMode = 1;
                                                                 SettingTableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                                                                 cell.detailLabel.text =  @"在线播放    ";
                                                             }];
        
        
        UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction * _Nonnull action) {
                                                                   
                                                               }];
        
        [alertVC addAction:cacheAction];
        [alertVC addAction:noCacheAction];
        [alertVC addAction:cancelAction];
        
        alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:alertVC
                         animated:YES
                       completion:nil];
    }
    else if (indexPath.row == 2) {
        [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
      
        // 清理视频文件
        [DownloadCacheVideo clearTmpDirectory];
        [DownloadCacheVideo clearCachesDirectory];
        
        // 清理缓存
        [self.settingsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [TIP showText:@"缓存已清理" inView:self.view];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return SettingTableViewCellHeight;
}

@end

