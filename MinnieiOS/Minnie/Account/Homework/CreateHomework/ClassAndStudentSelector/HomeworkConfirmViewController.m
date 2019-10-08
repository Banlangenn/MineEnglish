//
//  HomeworkConfirmViewController.m
//  MinnieTeacher
//
//  Created by songzhen on 2019/4/30.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "Homework.h"
#import "PushManager.h"
#import "NSDate+YYAdd.h"
#import "HomeworkSendLog.h"
#import "HomeworkService.h"
#import "HomeworkSendHistoryHeaderView.h"
#import "HomeworkSendHisTableViewCell.h"
#import "HomeworkConfirmViewController.h"

@interface HomeworkConfirmViewController ()<
UITableViewDelegate,
UITableViewDataSource>{
    
    HomeworkSendLog *_sendData;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;


@end

@implementation HomeworkConfirmViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([HomeworkSendHisTableViewCell class]) bundle:nil] forCellReuseIdentifier:HomeworkSendHisTableViewCellId];
    [self footerView];
    // 处理发送数据
    NSMutableArray *homeworkTitles = [NSMutableArray array];
    for (Homework *homework in self.homeworks) {
        [homeworkTitles addObject:homework.title];
    }
    NSMutableArray *classNames = [NSMutableArray array];
    for (Clazz *clazz in self.classes) {
        if (clazz.name.length) {
            [classNames addObject:clazz.name];
        }
    }
    NSMutableArray *studentNames = [NSMutableArray array];
    for (User *student in self.students) {
        if (student.nickname.length){
            [studentNames addObject:student.nickname];
        }else if (student.username.length) {
            [studentNames addObject:student.username];
        }
    }
    _sendData = [[HomeworkSendLog alloc] init];
    _sendData.homeworkTitles = homeworkTitles;
    _sendData.studentNames = studentNames;
    _sendData.classNames = classNames;
    _sendData.createTime = [self.dateTime stringWithFormat:@"YYYYY-MM-DD HH:mm:ss"];
    if (self.teacher.nickname.length){
        _sendData.teacherName = self.teacher.nickname;
    }else if (self.teacher.username.length) {
        _sendData.teacherName = self.teacher.username;
    }
}
- (void)footerView{
    
    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirmBtn setTitle:@"确认发送" forState: UIControlStateNormal];
    confirmBtn.frame = CGRectMake(0, 0, ScreenWidth, 40.0);
    
    [confirmBtn setBackgroundColor:[UIColor colorWithHex:0x0098FE]];
    [confirmBtn addTarget:self action:@selector(confirmSendBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat footerHeight = (isIPhoneX ? 34 : 0) + 40;
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0,ScreenHeight - footerHeight, ScreenWidth, footerHeight)];
    [footerView addSubview:confirmBtn];
    footerView.backgroundColor = [UIColor colorWithHex:0x0098FE];
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:footerView];
}

- (void)confirmSendBtnClicked:(UIButton *)btn{
    
    [self sendHomeworkWithTeacher:self.teacher date:self.dateTime];
}

- (void)sendHomeworkWithTeacher:(Teacher *)teacher date:(NSDate *)date {
   
    [HUD showProgressWithMessage:@"正在发送作业"];
    NSMutableArray *homeworkIds = [NSMutableArray array];
    for (Homework *homework in self.homeworks) {
        [homeworkIds addObject:@(homework.homeworkId)];
    }
    
    NSMutableArray *classIds = [NSMutableArray array];
    for (Clazz *clazz in self.classes) {
        [classIds addObject:@(clazz.classId)];
    }
    
    NSMutableArray *studentIds = [NSMutableArray array];
    for (User *student in self.students) {
        [studentIds addObject:@(student.userId)];
    }
    
    WeakifySelf;
    [HomeworkService sendHomeworkIds:homeworkIds
                            classIds:classIds
                          studentIds:studentIds
                           teacherId:teacher.userId
                                date:date
                            callback:^(Result *result, NSError *error) {
                                if (error != nil) {
                                    [HUD showErrorWithMessage:@"作业发送失败"];
                                    return;
                                }
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfSendHomework object:nil];
                                
                                if (studentIds.count > 0) {
                                    [PushManager pushText:@"你有新的作业" toUsers:studentIds date:date];
                                }
                                
                                if (classIds.count > 0) {
                                    [PushManager pushText:@"你有新的作业" toClasses:classIds date:date];
                                }
                                [HUD showWithMessage:@"作业发送成功"];
                                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfHomeworkSendSuccess object:nil];
                                [weakSelf dismissToRootViewController];
                            }];
}
-(void)dismissToRootViewController{
    
    UIViewController *vc = self;
    while(vc.presentingViewController){
        
        vc = vc.presentingViewController;
    }
    [vc dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)backBtnClicked:(id)sender {
    if (self.cancelCallBack) {
        self.cancelCallBack();
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

 #pragma mark - UITableViewDataSource && UITableViewDelagete
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [HomeworkSendHisTableViewCell calculateCellHightForData:_sendData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HomeworkSendHisTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:HomeworkSendHisTableViewCellId forIndexPath:indexPath];
    cell.lineView.hidden = YES;
    [cell setContentData:_sendData];
    return cell;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView * headerView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([HomeworkSendHistoryHeaderView class]) owner:nil options:nil] firstObject];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
