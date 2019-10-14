//
//  TeachersViewController.m
//  X5Teacher
//
//  Created by yebw on 2017/12/19.
//  Copyright © 2017年 netease. All rights reserved.
//  教师管理

#import "TeachersViewController.h"
#import "TeacherService.h"
#import "TeacherTableViewCell.h"
#import "TeachersTableHeaderView.h"
//#import "TeacherEditViewController.h"
#import "MITeacherAuthorViewController.h"

@interface TeachersViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray<Teacher *> *teachers;
@property (nonatomic, strong) BaseRequest *teachersRequest;

@property (nonatomic, weak) IBOutlet UIButton *addButton;
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UITableView *teachersTableView;

@end

@implementation TeachersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerCellNibs];
    
    // TODO: 超级管理员才有新建
    if (APP.currentUser.authority == TeacherAuthoritySuperManager) {
        self.addButton.hidden = NO;
    } else {
        self.addButton.hidden = YES;
    }

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload:)
                                                 name:kNotificationKeyOfAddTeacher
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload:)
                                                 name:kNotificationKeyOfUpdateTeacher
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload:)
                                                 name:kNotificationKeyOfDeleteTeacher
                                               object:nil];
    
    TeachersTableHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:@"TeachersTableHeaderView" owner:nil options:nil] lastObject];
    [self.teachersTableView setTableHeaderView:headerView];
    
    [self requestTeachers];
}

- (void)dealloc {
    [self.teachersRequest clearCompletionBlock];
    [self.teachersRequest stop];
    self.teachersRequest = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}

#pragma mark - Notification

- (void)reload:(NSNotification *)notification {
    [self requestTeachers];
}

#pragma mark - IBAction

- (IBAction)addButtonPressed:(id)sender {
    
    MITeacherAuthorViewController *editVC = [[MITeacherAuthorViewController alloc] initWithNibName:@"MITeacherAuthorViewController" bundle:nil];
    [self.navigationController pushViewController:editVC animated:YES];
}

#pragma mark - Private Methods

- (void)registerCellNibs {
    [self.teachersTableView registerNib:[UINib nibWithNibName:@"TeacherTableViewCell" bundle:nil] forCellReuseIdentifier:TeacherTableViewCellId];
}

- (void)requestTeachers {
    if (self.teachersRequest != nil) {
        return;
    }
    
    [self.teachers removeAllObjects];
    
    self.teachersTableView.hidden = YES;
    [self.containerView showLoadingView];
    
    WeakifySelf;
    self.teachersRequest = [TeacherService requestTeachersWithCallback:^(Result *result, NSError *error) {
        
        StrongifySelf;
        strongSelf.teachersRequest = nil;
        
        if (error != nil) {
            __weak TeachersViewController * weakSelf = strongSelf;
            [strongSelf.containerView showFailureViewWithRetryCallback:^{
                [weakSelf requestTeachers];
            }];
            
            return;
        }
        
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *teachers = (NSArray *)(dict[@"list"]);
        if (teachers.count == 0) {
            [strongSelf.containerView showEmptyViewWithImage:nil
                                                       title:@"暂无教师"
                                                   linkTitle:nil
                                           linkClickCallback:nil];
        } else {
            [strongSelf.containerView hideAllStateView];
            
            if (strongSelf.teachers == nil) {
                strongSelf.teachers = [NSMutableArray array];
            }
            
            [strongSelf.teachers addObjectsFromArray:teachers];
            
            strongSelf.teachersTableView.hidden = NO;
            [strongSelf.teachersTableView reloadData];
        }
    }];
}

#pragma mark - DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.teachers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TeacherTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TeacherTableViewCellId forIndexPath:indexPath];
    
    Teacher *teacher = self.teachers[indexPath.row];
    
    [cell setupWithTeacher:teacher];
    
    return cell;
}

#pragma mark - Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return TeacherTableViewCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    Teacher *teacher = self.teachers[indexPath.row];
//    TeacherEditViewController *editVC = [[TeacherEditViewController alloc] initWithNibName:@"TeacherEditViewController" bundle:nil];
//    editVC.teacher = teacher;
//    [self.navigationController pushViewController:editVC animated:YES];
    
    
    MITeacherAuthorViewController *editVC = [[MITeacherAuthorViewController alloc] initWithNibName:@"MITeacherAuthorViewController" bundle:nil];
    editVC.teacher = teacher;
    [self.navigationController pushViewController:editVC animated:YES];
}

@end

