//
//  MIZeroMessagesViewController.m
//  MinnieManager
//
//  Created by songzhen on 2019/7/12.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "IMManager.h"
#import "StudentService.h"
#import "HomeworkSession.h"
#import "MIZeroMessagesTableViewCell.h"
#import "MIZeroMessagesViewController.h"
#import "HomeworkSessionViewController.h"

@interface MIZeroMessagesViewController ()<
UITableViewDelegate,
UITableViewDataSource
>
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *zeroMsgBtn;
@property (weak, nonatomic) IBOutlet UIButton *qestionHomeworkBtn;

@property (strong, nonatomic) NSMutableArray *zeroMessagesArray;

@property (assign, nonatomic) HomeworkMessageType messageType;
@property (assign, nonatomic) NSInteger currentIndex;


@end

@implementation MIZeroMessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor emptyBgColor];
    self.tableView.tableFooterView = [UIView new];
    self.zeroMessagesArray = [NSMutableArray array];
    
    self.currentIndex = -1;
    self.zeroMsgBtn.selected = YES;
    [self requestStudentZeroTask];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.currentIndex = -1;
}

#pragma mark -   UITableViewDelegate,UITableViewDataSource

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.zeroMessagesArray.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row == 0) {
    
        return 30;
    } else {
    
        StudentZeroTask * zeroTaskData = self.zeroMessagesArray[indexPath.row - 1];
        return [MIZeroMessagesTableViewCell cellHeightWithZeroMessage:zeroTaskData];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MIZeroMessagesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MIZeroMessagesTableViewCellId];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIZeroMessagesTableViewCell class]) owner:nil options:nil] lastObject];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (indexPath.row == 0) {
        
        if (self.messageType == HomeworkMessageType_QuestionHomework) {
            
            [cell setupImage:@""
                        name:@"名字"
                   taskTitle:@"任务"
                     comment:@"问题备注"
                     teacher:@"对象"
                       index:0];
        } else {
            
            [cell setupImage:@""
                        name:@"名字"
                   taskTitle:@"任务"
                     comment:@"评语"
                     teacher:@"对象"
                       index:0];
        }
    } else {
        
        StudentZeroTask * zeroTaskData = self.zeroMessagesArray[indexPath.row - 1];
        [cell setupImage:zeroTaskData.avatar
                    name:zeroTaskData.nickName
               taskTitle:zeroTaskData.title
                 comment:zeroTaskData.content
                 teacher:zeroTaskData.createTeacher
                   index:indexPath.row];
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    StudentZeroTask * zeroTaskData = self.zeroMessagesArray[indexPath.row - 1];
#if MANAGERSIDE
    if (indexPath.row == self.currentIndex) {
        return;
    }
    self.currentIndex = indexPath.row;
    
    WeakifySelf;
    NSString *userId = [NSString stringWithFormat:@"%@", @(zeroTaskData.userId)];
    NSString *clientId = [IMManager sharedManager].client.clientId;
    AVIMClientStatus status = [IMManager sharedManager].client.status;
    if ([userId isEqualToString:clientId] && status == AVIMClientStatusOpened) {
        
        [weakSelf requestHomeworkSession:zeroTaskData];
    } else {
        
        [[IMManager sharedManager] setupWithClientId:userId callback:^(BOOL success,  NSError * error) {
            if (!success) {
                [HUD showErrorWithMessage:@"IM服务暂不可用，请稍后再试"];
                return ;
            };
            [weakSelf requestHomeworkSession:zeroTaskData];
        }];
    }
#endif
}

#if MANAGERSIDE

- (void)requestHomeworkSession:(StudentZeroTask *)data {
    
    HomeworkSession *session = [[HomeworkSession alloc] init];
    session.homeworkSessionId = data.hometaskId;
    HomeworkSessionViewController *vc = [[HomeworkSessionViewController alloc] initWithNibName:@"HomeworkSessionViewController" bundle:nil];
    vc.homeworkSession = session;
//    vc.teacher = APP.currentUser;
    [self.navigationController pushViewController:vc animated:YES];
//    if (self.pushVCCallback) {
//        self.pushVCCallback(vc);
//    }
}

#endif



- (void)updateZeroMessages{
    
    self.zeroMsgBtn.selected = YES;
    [self requestStudentZeroTask];
}
- (void)requestStudentZeroTask{
    self.currentIndex = -1;
    if (self.zeroMessagesArray.count == 0) {
        self.tableView.hidden = YES;
        [self.view showLoadingView];
    }
    WeakifySelf;
    [StudentService requestStudentZeroTaskCallback:^(Result *result, NSError *error) {
        [weakSelf.view hideAllStateView];
        if (error) {
            if (weakSelf.zeroMessagesArray.count == 0) {
              
                [weakSelf.view showFailureViewWithRetryCallback:^{
                    [weakSelf requestStudentZeroTask];
                }];
            }
            return ;
        } ;
        
        NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
        [self.zeroMessagesArray removeAllObjects];
        [self.zeroMessagesArray addObjectsFromArray:dictionary[@"list"]];
        if (weakSelf.zeroMessagesArray.count == 0) {
            
            [weakSelf.view showEmptyViewWithImage:nil
                                            title:@"暂无零分动态"
                                    centerYOffset:0 linkTitle:nil
                                linkClickCallback:nil
                                    retryCallback:^{
                
                                        [weakSelf requestStudentZeroTask];
                                    }];
        } else {
            weakSelf.tableView.hidden = NO;
            [weakSelf.tableView reloadData];
        }
    }];
}

- (IBAction)zeroMsgAction:(id)sender {
    if (self.zeroMsgBtn.selected) {
        return;
    }
    self.qestionHomeworkBtn.selected = NO;
    self.zeroMsgBtn.selected = YES;
    self.messageType = HomeworkMessageType_ZeroMessages;
    [self.tableView reloadData];
}
- (IBAction)questionHomeworkAction:(id)sender {
   
    if (self.qestionHomeworkBtn.selected) {
        return;
    }
    self.zeroMsgBtn.selected = NO;
    self.qestionHomeworkBtn.selected = YES;
    self.messageType = HomeworkMessageType_QuestionHomework;
    [self.tableView reloadData];
}

@end
