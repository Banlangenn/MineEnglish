//
//  MIScoreListViewController.m
//  
//
//  Created by songzhen on 2019/5/31.
//

#import "Result.h"
#import "IMManager.h"
#import "ScoreInfo.h"
#import "ManagerServce.h"
#import "HomeworkService.h"
#import "HomeworkSessionService.h"
#import "HomeworkSessionService.h"
#import "UIScrollView+Refresh.h"
#import "MIMoveHomeworkTaskView.h"
#import "MIScoreListTableViewCell.h"
#import "MIScoreListViewController.h"
#import "CSCustomSplitViewController.h"
#import "MICreateTaskViewController.h"
#import "HomeworkSessionViewController.h"


@interface MIScoreListViewController ()<
UITableViewDelegate,
UITableViewDataSource
>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *moveButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headViewConstraintHeight;

@property (strong, nonatomic) NSMutableArray *scoreListArray;

@property (nonatomic ,copy) NSString *nextUrl;

@property (nonatomic ,assign) BOOL isLoadMore;

@property (nonatomic ,assign) NSInteger currentIndex;
@end

@implementation MIScoreListViewController

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.currentIndex = -1;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self configureUI];
    [self requestScoreListIsLoadMore:NO];
    self.headViewConstraintHeight.constant = kNaviBarHeight;
    [self requestHomeworkDetail];
}

-(void)configureUI{
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.scoreListArray = [NSMutableArray array];
    
    UIView *footrView = [[UIView alloc] init];
    footrView.backgroundColor = [UIColor clearColor];
    _tableView.tableFooterView = footrView;
    _tableView.cellLayoutMarginsFollowReadableWidth = NO;
    
    if (self.hiddenEditTask) {
        self.moveButton.hidden = YES;
        self.editButton.hidden = YES;
    }
}

- (IBAction)backAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
    if (self.cancelCallBack) {
        self.cancelCallBack();
    }
}
- (IBAction)moveTaskAction:(id)sender {
    
    MIMoveHomeworkTaskView *view = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIMoveHomeworkTaskView class]) owner:nil options:nil].lastObject;
    view.frame = [UIScreen mainScreen].bounds;
    view.isMultiple = YES;
    WeakifySelf;
    view.callback = ^{
        if (weakSelf.editTaskCallBack) {
            weakSelf.editTaskCallBack();
        }
        [weakSelf.navigationController popViewControllerAnimated:YES];
    };
    view.homeworkIds = @[@(self.homework.homeworkId)];
    view.currentFileInfo = self.currentFileInfo;
    [[UIApplication sharedApplication].keyWindow addSubview:view];
}

- (IBAction)editTaskAction:(id)sender {

    MICreateTaskViewController *createVC = [[MICreateTaskViewController alloc] init];
    createVC.teacherSider = self.teacherSider;
    [createVC setupCreateHomework:self.homework currentFileInfo:self.currentFileInfo taskType:-1];
    WeakifySelf;
    if (self.teacherSider) {
        createVC.callBack = ^(BOOL isDelete) {
            if (weakSelf.editTaskCallBack) {
                weakSelf.editTaskCallBack();
            }
        };
        [self.navigationController pushViewController:createVC animated:YES];
    } else {
#if MANAGERSIDE
        
        UIView *bgView = [Utils viewOfVCAddToWindowWithVC:createVC width:ScreenWidth - kRootModularWidth];
        createVC.callBack = ^(BOOL isDelete) {
            if (weakSelf.editTaskCallBack) {
                weakSelf.editTaskCallBack();
            }
            if (bgView.superview) {
                [bgView removeFromSuperview];
            }
        };
        createVC.closeViewCallBack = ^{
            if (bgView.superview) {
                [bgView removeFromSuperview];
            }
        };
#endif
    }
}

#pragma mark -
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.scoreListArray.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return MIScoreListTableViewCellHeight;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MIScoreListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MIScoreListTableViewCellId];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIScoreListTableViewCell class]) owner:nil options:nil] lastObject];
    }
        ScoreInfo*model = self.scoreListArray[indexPath.row];
        [cell setupModel:model];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ScoreInfo *scoreInfo = self.scoreListArray[indexPath.row];

#if MANAGERSIDE
    if (indexPath.row == self.currentIndex) {
        return;
    }
    self.currentIndex = indexPath.row;
    
    WeakifySelf;
    NSString *userId = [NSString stringWithFormat:@"%@", @(scoreInfo.userId)];
    NSString *clientId = [IMManager sharedManager].client.clientId;
    AVIMClientStatus status = [IMManager sharedManager].client.status;
    if ([userId isEqualToString:clientId] && status == AVIMClientStatusOpened) {
        
        [weakSelf requestHomeworkSession:scoreInfo];
    } else {
        
        [[IMManager sharedManager] setupWithClientId:userId callback:^(BOOL success,  NSError * error) {
            if (!success) {
                [HUD showErrorWithMessage:@"IM服务暂不可用，请稍后再试"];
                return ;
            };
            [weakSelf requestHomeworkSession:scoreInfo];
        }];
    }
#endif
}

#if MANAGERSIDE

- (void)requestHomeworkSession:(ScoreInfo *)scoreInfo {
    
    HomeworkSession *session = [[HomeworkSession alloc] init];
    session.homeworkSessionId = scoreInfo.hometaskId;
    HomeworkSessionViewController *vc = [[HomeworkSessionViewController alloc] initWithNibName:@"HomeworkSessionViewController" bundle:nil];
    vc.homeworkSession = session;
    vc.teacher = self.teacher;
    [self.navigationController pushViewController:vc animated:YES];
}

#endif


#pragma mark - 获取列表
- (void)requestScoreListIsLoadMore:(BOOL)isLoadMore{
    
    WeakifySelf;
    if (isLoadMore) {
        
        [ManagerServce requestScoreListByHomeworkId:self.homework.homeworkId
                                          teacherId:self.teacher.userId
                                            nextUrl:self.nextUrl
                                           callback:^(Result *result, NSError *error) {
            [weakSelf.view hideAllStateView];
            [weakSelf.tableView footerEndRefreshing];
            if (error) {
                return ;
            }
            [weakSelf dealWithData:result isLoadMore:isLoadMore];
        }];
    } else {
        
        self.tableView.hidden = YES;
        [self.view showLoadingView];
        [ManagerServce requestScoreListByHomeworkId:self.homework.homeworkId
                                          teacherId:self.teacher.userId
                                            nextUrl:nil
                                           callback:^(Result *result, NSError *error) {
            
            [weakSelf.view hideAllStateView];
            [weakSelf.tableView footerEndRefreshing];
            if (error) {
                if (weakSelf.scoreListArray.count == 0) {
                    
                    [self.view showEmptyViewWithImage:nil title:@"得分列表为空" centerYOffset:0 linkTitle:nil linkClickCallback:nil retryCallback:^{
                        [weakSelf requestScoreListIsLoadMore:NO];
                    }];
                }
                return ;
            }
            [weakSelf dealWithData:result isLoadMore:isLoadMore];
        }];
    }
}

- (void)dealWithData:(Result *)result isLoadMore:(BOOL)isLoadMore{
    NSDictionary *dict = (NSDictionary *)(result.userInfo);
    NSArray *scoreList = (NSArray *)(dict[@"list"]);
    NSString *nextUrl = dict[@"next"];
    if (isLoadMore) {

        self.tableView.hidden = NO;
        [self.scoreListArray addObjectsFromArray:scoreList];
    } else {
        [self.scoreListArray removeAllObjects];
        [self.scoreListArray addObjectsFromArray:scoreList];
        if (self.scoreListArray.count == 0) {
            WeakifySelf;
            [self.view showEmptyViewWithImage:nil title:@"得分列表为空" centerYOffset:0 linkTitle:nil linkClickCallback:nil retryCallback:^{
                [weakSelf requestScoreListIsLoadMore:NO];
            }];
        } else {
            self.tableView.hidden = NO;
        }
    }
    self.nextUrl = nextUrl;
    if (self.nextUrl.length >0) {
        WeakifySelf;
        [self.tableView addInfiniteScrollingWithRefreshingBlock:^{
            
            [weakSelf requestScoreListIsLoadMore:YES];
        }];
    } else {
        [self.tableView removeFooter];
    }
    [self.tableView reloadData];
}

#pragma mark - 获取作业详情 （包含文件夹，创建老师）
- (void)requestHomeworkDetail{
    
    [HomeworkService requestHomeworkDetailWithId:self.homework.homeworkId callback:^(Result *result, NSError *error) {
       
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        Homework *homework = (Homework *)dict[@"data"];
        if (homework != nil) {
            self.homework = homework;
        }
    }];
}

- (FileInfo *)currentFileInfo{
    
    if (!_currentFileInfo) {
        _currentFileInfo = [[FileInfo alloc] init];
    }
    return _currentFileInfo;
}

@end
