//
//  AccountViewController.m
//  X5
//
//  Created by yebw on 2017/8/21.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "TeacherAccountViewController.h"
#import "ProfileTableViewCell.h"
#import "AccountTableViewCell.h"
#import "AccountManageTableViewCell.h"
#import "SettingsViewController.h"
#import "AvatarEditViewController.h"
#import "NicknameEditViewController.h"
#import "MessagesViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CircleHomeworksViewController.h"
#import "TeachersViewController.h"
#import "ExchangeRequestsViewController.h"
//#import "HomeworkManagerViewController.h"
#import "ClassesContainerController.h"
#import "StudentsViewController.h"
#import "MessageService.h"
#import "AwardsService.h"
#import "PublicService.h"
#import "MIHomeworkManagerViewController.h"

@interface TeacherAccountViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *accountTableView;

@property (nonatomic, weak) IBOutlet AccountTableViewCell *accountTableViewCell;

@end

@implementation TeacherAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(profileDidUpdate:)
                                                 name:kNotificationKeyOfProfileUpdated
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [MessageService requestUpdateCountWithCallback:^(Result *result, NSError *error) {
        if (error == nil && [result.userInfo isKindOfClass:[NSDictionary class]]) {
            NSDictionary *userInfo = (NSDictionary *)(result.userInfo);
            NSInteger count = [userInfo[@"count"] integerValue];
            
            [self.accountTableViewCell updateWithUnreadMessageCount:count];
        }
    }];
    
    [AwardsService requestUnexchangedRequestCountWithCallback:^(Result *result, NSError *error) {
        if (error == nil && [result.userInfo isKindOfClass:[NSDictionary class]]) {
            NSDictionary *userInfo = (NSDictionary *)(result.userInfo);
            NSInteger count = [userInfo[@"count"] integerValue];
            
            [self.accountTableViewCell updateWithUnexchangedCount:count];
        }
    }];
    // 更新用户信息
    [self updateTeacherInfo];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}

#pragma mark - Private Methods

- (void)profileDidUpdate:(NSNotification *)notification {
    [self.accountTableView reloadData];
}

#pragma mark - IBActions

- (IBAction)settingsButtonPressed:(id)sender {
    SettingsViewController *settingsVC = [[SettingsViewController alloc] initWithNibName:NSStringFromClass([SettingsViewController class]) bundle:nil];
    [settingsVC setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:settingsVC animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    WeakifySelf;
    if (indexPath.row == 0) {
        ProfileTableViewCell *profileCell = [tableView dequeueReusableCellWithIdentifier:ProfileTableViewCellId];
        if (profileCell == nil) {
            profileCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([ProfileTableViewCell class]) owner:nil options:nil] lastObject];
            
            profileCell.editAvatarCallback = ^{
                AvatarEditViewController *avatarEditVC = [[AvatarEditViewController alloc] initWithNibName:NSStringFromClass([AvatarEditViewController class]) bundle:nil];
                [avatarEditVC setHidesBottomBarWhenPushed:YES];
                [weakSelf.navigationController pushViewController:avatarEditVC animated:YES];
            };
            
            profileCell.editNicknameCallback = ^{
                NicknameEditViewController *nicknameEditVC = [[NicknameEditViewController alloc] initWithNibName:NSStringFromClass([NicknameEditViewController class]) bundle:nil];
                [nicknameEditVC setHidesBottomBarWhenPushed:YES];
                [weakSelf.navigationController pushViewController:nicknameEditVC animated:YES];
            };
        }
        
        [profileCell.avatarImageView sd_setImageWithURL:[APP.currentUser.avatarUrl imageURLWithWidth:64.f]];
        [profileCell.nicknameLabel setText:APP.currentUser.nickname];
        
        cell = profileCell;
    } else if (indexPath.row == 1) {
        AccountTableViewCell *accountCell = [tableView dequeueReusableCellWithIdentifier:AccountTableViewCellId];
        if (accountCell == nil) {
            accountCell = [[[NSBundle mainBundle] loadNibNamed:@"AccountTableViewCell" owner:nil options:nil] lastObject];
        }

        self.accountTableViewCell = accountCell;
        
        [accountCell setup];
        
        WeakifySelf;
        accountCell.messageCallback = ^{
            StrongifySelf;
            MessagesViewController *vc = [[MessagesViewController alloc] initWithNibName:@"MessagesViewController" bundle:nil];
            [vc setHidesBottomBarWhenPushed:YES];
            [strongSelf.navigationController pushViewController:vc animated:YES];
        };
        
        accountCell.exchangeCallback = ^{
            StrongifySelf;
            ExchangeRequestsViewController *vc = [[ExchangeRequestsViewController alloc] initWithNibName:@"ExchangeRequestsViewController" bundle:nil];
            [vc setExchanged:NO];
            [vc setHidesBottomBarWhenPushed:YES];
            [strongSelf.navigationController pushViewController:vc animated:YES];
        };
        
        cell = accountCell;
    } else if (indexPath.row == 2) {
        AccountManageTableViewCell *accountManageCell = [tableView dequeueReusableCellWithIdentifier:AccountManageTableViewCellId];
        if (accountManageCell == nil) {
            accountManageCell = [[[NSBundle mainBundle] loadNibNamed:@"AccountManageTableViewCell" owner:nil options:nil] lastObject];
        }
        
        [accountManageCell setup];
        
        WeakifySelf;
        accountManageCell.homeworkManageCallback = ^{
            StrongifySelf;
//            HomeworkManagerViewController *vc = [[HomeworkManagerViewController alloc] initWithNibName:@"HomeworkManagerViewController" bundle:nil];
//            [vc setHidesBottomBarWhenPushed:YES];
//            [strongSelf.navigationController pushViewController:vc animated:YES];
//
            
            MIHomeworkManagerViewController *vc = [[MIHomeworkManagerViewController alloc] initWithNibName:@"MIHomeworkManagerViewController" bundle:nil];
            [vc setHidesBottomBarWhenPushed:YES];
            [strongSelf.navigationController pushViewController:vc animated:YES];
            
        };
        
        accountManageCell.teacherManageCallback = ^{
            StrongifySelf;
            TeachersViewController *teachersVC = [[TeachersViewController alloc] initWithNibName:@"TeachersViewController" bundle:nil];
            [teachersVC setHidesBottomBarWhenPushed:YES];
            [strongSelf.navigationController pushViewController:teachersVC animated:YES];
        };
        
        accountManageCell.classManageCallback = ^{
            StrongifySelf;
            ClassesContainerController *classesVC = [[ClassesContainerController alloc] initWithNibName:NSStringFromClass([ClassesContainerController class]) bundle:nil];
            [classesVC setIsManageMode:YES];
            [classesVC setHidesBottomBarWhenPushed:YES];
            [strongSelf.navigationController pushViewController:classesVC animated:YES];
        };
        
        accountManageCell.studentManageCallback = ^{
            StrongifySelf;
            StudentsViewController *studentsVC = [[StudentsViewController alloc] initWithNibName:@"StudentsViewController" bundle:nil];
            [studentsVC setHidesBottomBarWhenPushed:YES];
            [strongSelf.navigationController pushViewController:studentsVC animated:YES];
        };

        cell = accountManageCell;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0;

    Teacher *teacher = APP.currentUser;
    if (indexPath.row == 0) {
        height = ProfileTableViewCellHeight;
    } else if (indexPath.row == 1) {
        height = AccountTableViewCellHeight;
        
        if (teacher.authority == TeacherAuthorityManager ||
            teacher.authority == TeacherAuthoritySuperManager) {
            
            if (!APP.currentUser.canExchangeRewards) {
                height -= 50.f;
            }
        } else {
            height -= 50.f;
        }
    } else if (indexPath.row == 2) {
        height = 0;
        
        if (teacher.authority == TeacherAuthoritySuperManager) {
            
            height = 200.f;
        } else if (teacher.authority == TeacherAuthorityManager) {
            
            if (teacher.canManageHomeworks) {
                height += 50.f;
            }
            
            if (teacher.canManageTeachers) {
                height += 50.f;
            }
            if (teacher.canManageCampus) {
                height += 50.f;
            }
            height += 50.f;
        } else {
            height += 50.f;
        }
    
        if (height > 0) {
            height += 12;
        }
    }
    
    return height;
}

- (void)updateTeacherInfo{
   
    NSInteger userId = APP.currentUser.userId;
    if (userId == 0) {
        return;
    }
    WeakifySelf;
    [PublicService requestUserInfoWithId:userId
                                callback:^(Result *result, NSError *error) {
                                    if (error == nil) {
                                        
                                        Teacher *userInfo = (Teacher *)(result.userInfo);
                                        userInfo.token = APP.currentUser.token;
                                        APP.currentUser = userInfo;
                                        [weakSelf.accountTableView reloadData];
                                    }
                                }];
    
}

@end

