//
//  MIStudentTaskRecordViewController.m
//  MinnieManager
//
//  Created by songzhen on 2019/12/9.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "UIScrollView+Refresh.h"
#import "HomeworkSessionService.h"
#import "HomeworkSessionTableViewCell.h"
#import "MIStudentTaskRecordViewController.h"
#import "HomeworkSessionViewController.h"

@interface MIStudentTaskRecordViewController ()<
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,strong) NSMutableArray *homeworkSessions;

@property (nonatomic,copy) NSString *nextUrl;

@end

@implementation MIStudentTaskRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.homeworkSessions = [NSMutableArray array];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kColumnThreeWidth, ScreenHeight) style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor bgColor];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerNib:[UINib nibWithNibName:@"FinishedHomeworkSessionTableViewCell" bundle:nil] forCellReuseIdentifier:FinishedHomeworkSessionTableViewCellId];

    
    // 下拉刷新
    [self.tableView addPullToRefreshWithTarget:self refreshingAction:@selector(requestHomeSession)];
    [self.tableView headerBeginRefreshing];
    
}


- (void)updateStarRecordWithSutdentId:(NSInteger)studentId{
    
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.homeworkSessions.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
          
    HomeworkSession *session = self.homeworkSessions[indexPath.row];
    CGFloat height = [HomeworkSessionTableViewCell cellHeightWithHomeworkSession:session
                                                                        finished:1];
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    HomeworkSessionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FinishedHomeworkSessionTableViewCellId forIndexPath:indexPath];
    if (!cell) {
        cell = [[HomeworkSessionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FinishedHomeworkSessionTableViewCellId];
    }
    HomeworkSession *homeworkSession = self.homeworkSessions[indexPath.row];
    [cell setupWithHomeworkSession:homeworkSession];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self toHomeworkSessionViewController:indexPath];
}
- (void)toHomeworkSessionViewController:(NSIndexPath *)indexPath{
    
    HomeworkSession *session = self.homeworkSessions[indexPath.row];
    HomeworkSessionViewController *vc = [[HomeworkSessionViewController alloc] initWithNibName:@"HomeworkSessionViewController" bundle:nil];
    vc.homeworkSession = session;
}


- (void)requestHomeSession{
 
    [HomeworkSessionService requestHomeworkSessionsWithFinishState:1
                                                         teacherId:0
                                                          callback:^(Result *result, NSError *error) {
                   
        [self.tableView headerEndRefreshing];
        if (error) return ;
        NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
        NSArray *homeworkSessions = dictionary[@"list"];
        [self.homeworkSessions removeAllObjects];
        [self.homeworkSessions addObjectsFromArray:homeworkSessions];
        [self.tableView reloadData];
        if (self.homeworkSessions.count == 0) {
            self.tableView.hidden = YES;
            WeakifySelf;
            [self.view showFailureViewWithRetryCallback:^{
                [weakSelf.tableView headerEndRefreshing];
            }];
        } else {
            self.tableView.hidden = NO;
        }
        
        self.nextUrl = dictionary[@"next"];
        if (self.nextUrl.length > 0) {
            // 上拉加载
            [self.tableView addInfiniteScrollingWithTarget:self refreshingAction:@selector(loadMore)];
        } else {
            [self.tableView footerResetNoMoreData];
        }
    }];
}

- (void)loadMore{
    
    [HomeworkSessionService requestHomeworkSessionsWithNextUrl:self.nextUrl callback:^(Result *result, NSError *error) {
              
        [self.tableView footerEndRefreshing];
        if (error) return ;
        NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
        NSArray *homeworkSessions = dictionary[@"list"];
        [self.homeworkSessions addObjectsFromArray:homeworkSessions];
        [self.tableView reloadData];
    }];
}

@end
