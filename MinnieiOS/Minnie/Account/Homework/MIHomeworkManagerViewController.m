//
//  MIHomeworkManagerViewController.m
//  Minnie
//
//  Created by songzhen on 2019/6/8.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "Result.h"
#import "ManagerServce.h"
#import "UIScrollView+Refresh.h"
#import "MIAddTypeTableViewCell.h"
#import "MICreateTaskViewController.h"
#import "SearchHomeworkViewController.h"
#import "MIHomeworkManagerViewController.h"
#import "MIHomeworkSubFileViewController.h"
#import "HomeWorkSendHistoryViewController.h"

@interface MIHomeworkManagerViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong,nonatomic) NSMutableArray *folderArray;

@end

@implementation MIHomeworkManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.folderArray = [NSMutableArray array];
    // Do any additional setup after loading the view from its nib.
    [self.tableView registerNib:[UINib nibWithNibName:@"MIAddTypeTableViewCell" bundle:nil] forCellReuseIdentifier:MIAddTypeTableViewCellId];
    WeakifySelf;
    [self.tableView addPullToRefreshWithRefreshingBlock:^{
        
        if (!weakSelf) return ;
        [weakSelf requestGetFiles];
    }];
    [self.tableView headerBeginRefreshing];
}
- (IBAction)backAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)createAction:(id)sender {
    [self showSelectedTask];
}

- (IBAction)searchAction:(id)sender {
    
    SearchHomeworkViewController *vc = [[SearchHomeworkViewController alloc] initWithNibName:@"SearchHomeworkViewController" bundle:nil];
    vc.fieldId = 0;
    [self.navigationController pushViewController:vc animated:NO];
}

- (IBAction)recordAction:(id)sender {
    
    if (!APP.currentUser.canManageHomeworks) {
        [HUD showErrorWithMessage:@"无操作权限"];
        return;
    }
    HomeWorkSendHistoryViewController * historyHomeworkVC = [[HomeWorkSendHistoryViewController alloc] initWithNibName:@"HomeWorkSendHistoryViewController" bundle:nil];
    [self.navigationController pushViewController:historyHomeworkVC animated:YES];
}

#pragma mark - UITableViewDataSource && UITableViewDelagete
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return MIAddTypeTableViewCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return self.folderArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MIAddTypeTableViewCell *contentCell = [tableView dequeueReusableCellWithIdentifier:MIAddTypeTableViewCellId forIndexPath:indexPath];
    ParentFileInfo *parentFileInfo = self.folderArray[indexPath.row];
    [contentCell setupWithContentTitle:parentFileInfo.fileInfo.fileName];
    return contentCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MIHomeworkSubFileViewController *subVC = [[MIHomeworkSubFileViewController alloc] initWithNibName:NSStringFromClass([MIHomeworkSubFileViewController class]) bundle:nil];
    subVC.parentFileInfo = self.folderArray[indexPath.row];
    [self.navigationController pushViewController:subVC animated:YES];
}


#pragma mark - 获取文件夹信息
- (void)requestGetFiles{
    
    WeakifySelf;
    weakSelf.tableView.hidden = YES;
    [ManagerServce requestGetFilesWithFileId:0 callback:^(Result *result, NSError *error) {
       
        [weakSelf.view hideAllStateView];
        [weakSelf.tableView headerEndRefreshing];
        if (error) {
            [weakSelf.view showFailureViewWithRetryCallback:^{
                [weakSelf requestGetFiles];
            }];
            return ;
        };
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *folderList = (NSArray *)(dict[@"list"]);
        [weakSelf.folderArray removeAllObjects];
        [weakSelf.folderArray addObjectsFromArray:folderList];
        
        if (weakSelf.folderArray.count) {
            weakSelf.tableView.hidden = NO;
            [weakSelf.tableView reloadData];
        } else {
            [weakSelf.view showEmptyViewWithImage:nil title:@"文件夹为空" linkTitle:nil linkClickCallback:nil];
        }
    }];
}


- (void)showSelectedTask{
    
    WeakifySelf;
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"选择任务类型"
                                                                     message:nil
                                                              preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:kHomeworkTaskNotifyName
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        [weakSelf goToCreateTaskWithType:MIHomeworkTaskType_Notify];
                                                    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:kHomeworkTaskFollowUpName
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        [weakSelf goToCreateTaskWithType:MIHomeworkTaskType_FollowUp];
                                                        
                                                    }];
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:kHomeworkTaskWordMemoryName
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        [weakSelf goToCreateTaskWithType:MIHomeworkTaskType_WordMemory];
                                                    }];
    UIAlertAction *action4 = [UIAlertAction actionWithTitle:kHomeworkTaskGeneralTaskName
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        [weakSelf goToCreateTaskWithType:MIHomeworkTaskType_GeneralTask];
                                                    }];
    UIAlertAction *action6 = [UIAlertAction actionWithTitle:kHomeworkTaskNameExaminationStatistics
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        [weakSelf goToCreateTaskWithType:MIHomeworkTaskType_ExaminationStatistics];
                                                    }];
    
    UIAlertAction *action7 = [UIAlertAction actionWithTitle:kHomeworkTaskPictureTranslation
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        [weakSelf goToCreateTaskWithType:MIHomeworkTaskType_PictureTranslation];
                                                    }];
    UIAlertAction *action8 = [UIAlertAction actionWithTitle:@"取消"
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                    }];
    
    [alertVC addAction:action1];
    [alertVC addAction:action2];
    [alertVC addAction:action3];
    [alertVC addAction:action4];
    [alertVC addAction:action6];
    [alertVC addAction:action7];
    [alertVC addAction:action8];

    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertVC
                       animated:YES
                     completion:nil];
}

- (void)goToCreateTaskWithType:(MIHomeworkTaskType)type{
    
    MICreateTaskViewController *createVC = [[MICreateTaskViewController alloc] initWithNibName:NSStringFromClass([MICreateTaskViewController class]) bundle:nil];
    createVC.teacherSider = YES;
    [createVC setupCreateHomework:nil currentFileInfo:nil taskType:type];
    [self.navigationController pushViewController:createVC animated:YES];
}

@end
