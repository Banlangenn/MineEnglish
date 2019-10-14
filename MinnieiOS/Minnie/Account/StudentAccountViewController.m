//
//  AccountViewController.m
//  X5
//
//  Created by yebw on 2017/8/21.
//  Copyright © 2017年 mfox. All rights reserved.
// 学生-我的

#import "StudentAccountViewController.h"
#import "ProfileTableViewCell.h"
#import "GoodWorkTableViewCell.h"
#import "CircleAndStarTableViewCell.h"
#import "SettingsViewController.h"
#import "MessagesViewController.h"
#import "AvatarEditViewController.h"
#import "NicknameEditViewController.h"
#import "StudentAwardsViewController.h"
#import "MyClassViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CircleHomeworksViewController.h"
#import "CircleService.h"
#import "MessageService.h"
#import "StudentService.h"
#import "IMManager.h"
#import "StudentStarListViewController.h"
#import "PublicService.h"


@interface StudentAccountViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *accountTableView;
@property (nonatomic, weak) IBOutlet UIImageView *redPointImageView;
@property (nonatomic, weak) BaseRequest *requestUnreaderRequest;

@property (nonatomic, weak) CircleAndStarTableViewCell *circleAndStarCell;

@end

@implementation StudentAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileDidUpdate:) name:kNotificationKeyOfProfileUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeworkSessionUpdate:) name:kIMManagerContentMessageDidReceiveNotification object:nil];
    
    self.redPointImageView.layer.cornerRadius = 4.f;
    self.redPointImageView.layer.masksToBounds = YES;
    self.redPointImageView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    WeakifySelf;
    if (self.requestUnreaderRequest != nil) {
        [self.requestUnreaderRequest clearCompletionBlock];
        [self.requestUnreaderRequest stop];
        self.requestUnreaderRequest = nil;
    }
    
  //  WeakifySelf;
    self.requestUnreaderRequest = [CirlcleService requestUnreadCircleCountWithCallback:^(Result *result, NSError *error) {
        StrongifySelf;
        strongSelf.requestUnreaderRequest = nil;
        if (error == nil && [result.userInfo isKindOfClass:[NSDictionary class]]) {
            NSDictionary *userInfo = (NSDictionary *)(result.userInfo);
            NSInteger count = [userInfo[@"count"] integerValue];
            APP.currentUser.circleUpdate = count;
//            [strongSelf.circleAndStarCell update];
        }
    }];
    
    [MessageService requestUpdateCountWithCallback:^(Result *result, NSError *error) {
        if (error == nil && [result.userInfo isKindOfClass:[NSDictionary class]]) {
            NSDictionary *userInfo = (NSDictionary *)(result.userInfo);
            NSInteger count = [userInfo[@"count"] integerValue];
            
            self.redPointImageView.hidden = count==0;
        }
    }];
    // 更新用户信息
    [self updateSutdentInfo];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}

#pragma mark - Private Methods

- (void)homeworkSessionUpdate:(NSNotification *)notification {
    //重新获取作业详情
    WeakifySelf;
    [StudentService requestStudentWithPhoneNumber:APP.currentUser.phoneNumber callback:^(Result *result, NSError *error) {
        StrongifySelf;
        if (result.userInfo != nil) {
            Student *student = (Student *)(result.userInfo);
            [APP setCurrentUser:student];
            [strongSelf.accountTableView reloadData];
        }
    }];
}
    
- (void)profileDidUpdate:(NSNotification *)notification {
    [self.accountTableView reloadData];
}


#pragma mark - IBActions

- (IBAction)messagesButtonPressed:(id)sender {
    MessagesViewController *messagesVC = [[MessagesViewController alloc] initWithNibName:NSStringFromClass([MessagesViewController class]) bundle:nil];
    [messagesVC setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:messagesVC animated:YES];
}

- (IBAction)settingsButtonPressed:(id)sender {
    SettingsViewController *settingsVC = [[SettingsViewController alloc] initWithNibName:NSStringFromClass([SettingsViewController class]) bundle:nil];
    [settingsVC setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:settingsVC animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
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
            
            profileCell.classButtonClickCallback = ^{
                MyClassViewController *classVC = [[MyClassViewController alloc] initWithNibName:NSStringFromClass([MyClassViewController class]) bundle:nil];
                [classVC setClassId:APP.currentUser.clazz.classId];
                [classVC setHidesBottomBarWhenPushed:YES];
                [weakSelf.navigationController pushViewController:classVC animated:YES];
            };
        }
        
        [profileCell.avatarImageView sd_setImageWithURL:[APP.currentUser.avatarUrl imageURLWithWidth:64.f]];
        [profileCell.nicknameLabel setText:APP.currentUser.nickname];
        
        NSString *title = [NSString stringWithFormat:@"  %@  ",APP.currentUser.clazz.name];
        [profileCell.classButton setTitle:title forState:UIControlStateNormal];

        cell = profileCell;
    } else if (indexPath.row == 1) {
        GoodWorkTableViewCell *goodworkCell = [tableView dequeueReusableCellWithIdentifier:GoodWorkTableViewCellId];
        
        if (goodworkCell == nil) {
            goodworkCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([GoodWorkTableViewCell class]) owner:nil options:nil] lastObject];
        }
        
        [goodworkCell update];
        
        cell = goodworkCell;
    } else if (indexPath.row == 2) { // 星兑换
        CircleAndStarTableViewCell *circleAndStarCell = [tableView dequeueReusableCellWithIdentifier:GoodWorkTableViewCellId];
        if (circleAndStarCell == nil) {
            circleAndStarCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([CircleAndStarTableViewCell class]) owner:nil options:nil] lastObject];
        }
        
        circleAndStarCell.circleClickCallback = ^{
            CircleHomeworksViewController *circleVC = [[CircleHomeworksViewController alloc] initWithNibName:@"CircleHomeworksViewController" bundle:nil];
            circleVC.clazz = APP.currentUser.clazz;
            [circleVC setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:circleVC animated:YES];
        };
        
        circleAndStarCell.starClickCallback = ^{
            
            StudentAwardsViewController *awardsVC = [[StudentAwardsViewController alloc] initWithNibName:NSStringFromClass([StudentAwardsViewController class]) bundle:nil];
            [awardsVC setHidesBottomBarWhenPushed:YES];
            [weakSelf.navigationController pushViewController:awardsVC animated:YES];
        };
        
        [circleAndStarCell updateTitle:@"星兑换" image:@"my_img_星兑换"];
        cell = circleAndStarCell;
        self.circleAndStarCell = circleAndStarCell;
    } else { // 星星排行榜
        CircleAndStarTableViewCell *circleAndStarCell = [tableView dequeueReusableCellWithIdentifier:GoodWorkTableViewCellId];
        if (circleAndStarCell == nil) {
            circleAndStarCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([CircleAndStarTableViewCell class]) owner:nil options:nil] lastObject];
        }
        
        circleAndStarCell.starClickCallback = ^{
            StudentStarListViewController *awardsVC = [[StudentStarListViewController alloc] initWithNibName:NSStringFromClass([StudentStarListViewController class]) bundle:nil];
            [awardsVC setHidesBottomBarWhenPushed:YES];
            [weakSelf.navigationController pushViewController:awardsVC animated:YES];
        };
        [circleAndStarCell updateTitle:@"星星排行榜" image:@"my_star_rank"];
        cell = circleAndStarCell;
        self.circleAndStarCell = circleAndStarCell;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0;
    
    if (indexPath.row == 0) {
        height = ProfileTableViewCellHeight;
    } else if (indexPath.row == 1) {
        height = GoodWorkTableViewCellHeight;
    } else {
        height = CircleAndStarTableViewCellHeight;
    }
    return height;
}

- (void)updateSutdentInfo{
   
    NSInteger userId = APP.currentUser.userId;
    if (userId == 0) {
        return;
    }
    WeakifySelf;
    [PublicService requestUserInfoWithId:userId
                                callback:^(Result *result, NSError *error) {
                                    if (error == nil) {

                                        Student *userInfo = (Student *)(result.userInfo);
                                        userInfo.token = APP.currentUser.token;
                                        APP.currentUser = userInfo;
                                        [weakSelf.accountTableView reloadData];
                                    }
                                }];

}
@end

