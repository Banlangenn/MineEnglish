//
//  UnfinishedHomeworksViewController.m
//  X5
//
//  Created by yebw on 2017/8/27.
//  Copyright © 2017年 mfox. All rights reserved.
//

//#import "NSDate+X5.h"
#import "NSDate+Extension.h"
#import "ActivityInfo.h"
#import "ManagerServce.h"
#import "MIActivityBannerView.h"
#import "HomeworkSessionsViewController.h"
#import "HomeworkSessionViewController.h"
#import "HomeworkSessionTableViewCell.h"
#import "HomeworkSessionService.h"
#import "UIScrollView+Refresh.h"
#import "IMManager.h"
#import "NetworkStateErrorView.h"
#import <AFNetworking/AFNetworking.h>
#import "AppDelegate.h"
#if TEACHERSIDE || MANAGERSIDE
#else
#import "MISutdentActDetailViewController.h"
#endif


@interface HomeworkSessionsViewController ()<
UITableViewDataSource,
UITableViewDelegate,
MIActivityBannerViewDelegate
>
//   作业状态 0：待批改；1已完成；2未提交
@property (nonatomic, assign) NSInteger mState;

@property (nonatomic, weak) IBOutlet UITableView *homeworkSessionsTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;


// 作业会话请求
@property (nonatomic, strong) BaseRequest *homeworkSessionsRequest;
// 作业会话列表
@property (nonatomic, strong) NSMutableArray <HomeworkSession *> *homeworkSessions;
@property (nonatomic, strong) NSString *nextUrl;

// 页面出现是否需要刷新
@property (nonatomic, assign) BOOL shouldReloadWhenAppeard;

// 查询会话列表
@property (nonatomic, strong) NSArray *queriedConversations;
//名字搜索条件 只有在搜索页使用
@property (nonatomic, strong) NSString * searchFilterName;
//目前只有学生端处理
@property (nonatomic, strong) NSMutableArray * unReadHomeworkSessions;
@property (nonatomic, strong) NSMutableArray * noHandleNotications;

// banner 只显示在学生端，未完成
@property (nonatomic, strong) NSArray *bannerArray;
@property (nonatomic, strong) MIActivityBannerView *bannerView;
// 管理端
@property (nonatomic, assign) NSInteger currentSelectIndex;

@end

@implementation HomeworkSessionsViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _homeworkSessions = [NSMutableArray array];
    self.view.backgroundColor = [UIColor unSelectedColor];
    self.unReadHomeworkSessions = [[NSMutableArray alloc] init];
    self.noHandleNotications = [[NSMutableArray alloc] init];
    //先读出缓存中的数据
    [self.homeworkSessions removeAllObjects];
    [self registerCellNibs];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 12.f)];
    self.homeworkSessionsTableView.tableFooterView = footerView;
    
    [self setupRequestState];
#if MANAGERSIDE
    self.currentSelectIndex = -1;
#elif TEACHERSIDE
#else
    [self requestGetActivityList];
#endif
    
#if MANAGERSIDE
#else
    if (self.searchFliter != -1)
    {
        [self setupAndLoadConversations];
        [self requestHomeworkSessions];
    }
#endif
    [self addNotificationObservers];
}

- (void)setupRequestState
{   // 学生端：未完成、已完成  老师端：待批改、已完成、未提交
    if (self.isUnfinished)
    {
        if (self.bLoadConversion)
        {//   作业状态 0：待批改；1已完成；2未提交
            self.mState = 0;
        }
        else
        {
            self.mState = 2;
        }
    }
    else
    {
        self.mState = 1;
    }
}

#pragma mark - 会话初始化
- (void)setupAndLoadConversations {
    
    if (!self.isUnfinished) return;
    //不需要加载
//    if (!self.bLoadConversion)  return;
 
    NSString *userId;
    NSString *clientId = [IMManager sharedManager].client.clientId;
    AVIMClientStatus status = [IMManager sharedManager].client.status;
#if MANAGERSIDE
    userId = [NSString stringWithFormat:@"%@", @(self.teacher.userId)];
#else
    userId = [NSString stringWithFormat:@"%@", @(APP.currentUser.userId)];
#endif
    
    WeakifySelf;
    if ([userId isEqualToString:clientId] && status == AVIMClientStatusOpened) {
        [self loadConversationsWithHomeworkSessions:self.homeworkSessions];
    } else {
        
        [[IMManager sharedManager] setupWithClientId:userId callback:^(BOOL success,  NSError * error) {
            if (!success) {
                [HUD showErrorWithMessage:@"IM服务暂不可用，请稍后再试"];
                return ;
            };
            [weakSelf loadConversationsWithHomeworkSessions:self.homeworkSessions];
        }];
    }
}

#pragma mark -
#pragma mark - 查询消息会话，匹配最后一条消息内容
- (void)loadConversationsWithHomeworkSessions:(NSArray *)sessions {
    
    if (sessions.count == 0) {
        return;
    }
    NSDate *startTime = [NSDate date];
    AVIMClient *client = [IMManager sharedManager].client;
    NSMutableArray *queryArr = [NSMutableArray array];
//    for (HomeworkSession *homeworkSession in sessions) {
//
//        NSString *name = [NSString stringWithFormat:@"%ld",(long)homeworkSession.homeworkSessionId];
//        AVIMConversationQuery *query = [client conversationQuery];
//        [query whereKey:@"name" equalTo:name];
//        [queryArr addObject:query];
//    }
    
    for (HomeworkSession *homeworkSession in sessions) {

        NSString *name = [NSString stringWithFormat:@"%ld",(long)homeworkSession.homeworkSessionId];
        [queryArr addObject:name];
    }
    
    if (queryArr.count == 0) {
        return;
    }
    // 通过组合的方式，根据唯一homeworkSessionId，查询指定作业的消息会话内容，明确会话数量，减少耗时
//    AVIMConversationQuery *conversation = [AVIMConversationQuery orQueryWithSubqueries:queryArr];
    // 使用数组查询
    AVIMConversationQuery *conversation = [client conversationQuery];
    [conversation whereKey:@"name" containedIn:queryArr];
    
    // 缓存 先走网络查询，发生网络错误的时候，再从本地查询
    conversation.cachePolicy = kAVCachePolicyNetworkElseCache;
    // 设置查询选项，指定返回对话的最后一条消息
    conversation.option = AVIMConversationQueryOptionWithMessage;
    // 每条作业 homeworkSessionId唯一 限制查询数量，减少耗时
    conversation.limit = 1000;
    [conversation findConversationsWithCallback:^(NSArray<AVIMConversation *> * _Nullable conversations, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self mergeAndReloadWithQueriedConversations:conversations homeworkSessions:sessions];
        });
        NSLog(@" ======= 会话数:%@ total:%lu 耗时%.fms", @(conversations.count),sessions.count, [[NSDate date] timeIntervalSinceDate:startTime]*1000);
    }];
}

- (void)mergeAndReloadWithQueriedConversations:(NSArray *)conversations homeworkSessions:(NSArray *)sessions{
    
    NSArray *queriedConversations = conversations;
    for (HomeworkSession *homeworkSession in sessions) {
        
        for (AVIMConversation *conversation in queriedConversations) {
            
            if ([conversation.name integerValue] == homeworkSession.homeworkSessionId) {
                homeworkSession.conversation = conversation;
                homeworkSession.unreadMessageCount = conversation.unreadMessagesCount;
                
                AVIMMessage *message = conversation.lastMessage;
                if ([message isKindOfClass:[AVIMTextMessage class]]) {
                    homeworkSession.lastSessionContent = ((AVIMTextMessage *)message).text;
                } else if ([message isKindOfClass:[AVIMAudioMessage class]]) {
                    
                    NSString *typeName = ((AVIMTypedMessage *)message).attributes[@"typeName"];
                    if ([typeName isEqualToString:kHomeworkTaskFollowUpName] ||
                        [typeName isEqualToString:kHomeworkTaskWordMemoryName]) {
                        
                        homeworkSession.lastSessionContent = @"[链接]";
                    } else {
                        homeworkSession.lastSessionContent = @"[音频]";
                    }
                } else if ([message isKindOfClass:[AVIMVideoMessage class]]) {
                    homeworkSession.lastSessionContent = @"[视频]";
                } else if ([message isKindOfClass:[AVIMImageMessage class]]) {
                    homeworkSession.lastSessionContent = @"[图片]";
                }
                NSLog(@" ======= 会话数=== :%lu text:%@", [conversation.name integerValue], homeworkSession.lastSessionContent);
#if TEACHERSIDE || MANAGERSIDE
                homeworkSession.shouldColorLastSessionContent = message.ioType == AVIMMessageIOTypeOut;
#else
                homeworkSession.shouldColorLastSessionContent = message.ioType == AVIMMessageIOTypeIn;
                
                if (homeworkSession.updateTime == 0 && message != nil)
                {
                    [self updateHomeworkSessionModifiedTime:homeworkSession];
                }
#endif
                break;
            }
        }
        if (homeworkSession.conversation.lastMessageAt != nil) {
            homeworkSession.sortTime = [homeworkSession.conversation.lastMessageAt timeIntervalSince1970] * 1000;
            
        } else {
            homeworkSession.sortTime = homeworkSession.updateTime;
        }
    }
    [self updateUI];
}

#pragma mark - 更新作业任务时间
- (void)updateHomeworkSessionModifiedTime:(HomeworkSession *)homeworkSession
{
    [HomeworkSessionService updateHomeworkSessionModifiedTimeWithId:homeworkSession.homeworkSessionId
                                                           callback:^(Result *result, NSError *error) {
                                                           }];
}

#pragma mark - 添加观察者 && 处理事件
- (void)addNotificationObservers {

    // 下线通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(imOffline:)
                                                 name:kIMManagerClientOfflineNotification
                                               object:nil];
    // 上线通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(imOnline:)
                                                 name:kIMManagerClientOnlineNotification
                                               object:nil];
    // 未读消息个数通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadUnReadMessage:)
                                                 name:kIMManagerClientUnReadMessageCountNotification
                                               object:nil];
    // 接收到会话消息通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lastMessageDidChange:)
                                                 name:kIMManagerContentMessageDidReceiveNotification
                                               object:nil];
    // 发送消息成功通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lastMessageDidChange:)
                                                 name:kIMManagerContentMessageDidSendNotification
                                               object:nil];
    
    // 编辑标注后刷新列表
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestHomeworkSessions) name:kNotificationKeyOfStudentMarkChange object:nil];
    // 双击tab刷新作业列表
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestHomeworkSessions)
                                                 name:kNotificationKeyOfTabBarDoubleClick
                                               object:nil];
    // 后台唤起重新刷新任务列表
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestHomeworkSessions)
                                                 name:kNotificationKeyOfRefreshHomeworkSession
                                               object:nil];
    
    // 教师批改作业
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadWhenHomeworkCorrected:)
                                                 name:kNotificationKeyOfCorrectHomework
                                               object:nil];
//    以下为需要刷新网络
    // 教师删除一个班级
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateHomeworkSessions:)
                                                 name:kNotificationKeyOfDeleteClass
                                               object:nil];
    // 教师端发送一个作业
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateHomeworkSessions:)
                                                 name:kNotificationKeyOfSendHomework
                                               object:nil];
    // 教师端删除学生
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateHomeworkSessions:)
                                                 name:kNotificationKeyOfDeleteClassStudents
                                               object:nil];
    // 学生重做作业
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateHomeworkSessions:)
                                                 name:kNotificationKeyOfRedoHomework
                                               object:nil];
    // 教师端添加一个作业
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateHomeworkSessions:)
                                                 name:kNotificationKeyOfAddHomework
                                               object:nil];
    // 推送唤起程序刷新作业新任务列表
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateHomeworkSessions:)
                                                 name:kNotificationKeyOfApnsNewHomeworkSession
                                               object:nil];
}


#pragma mark - 处理通知响应事件
- (void)imOnline:(NSNotification *)notification {
    [self.homeworkSessionsTableView setTableHeaderView:nil];
}

- (void)imOffline:(NSNotification *)notification {
    
    if (self.homeworkSessionsTableView.tableHeaderView != nil)  return;
    if ([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus != AFNetworkReachabilityStatusNotReachable) {
        
        [self.homeworkSessionsTableView setTableHeaderView:nil];
        return ;
    }
    NetworkStateErrorView *errorView = [[[NSBundle mainBundle] loadNibNamed:@"NetworkStateErrorView" owner:nil options:0] lastObject];
    
    self.homeworkSessionsTableView.tableHeaderView = errorView;
}


#pragma mark - 通知事件->更新任务列表
- (void)updateHomeworkSessions:(NSNotification *)notification{
    
    if (self.homeworkSessions.count > 0) {
        [self.homeworkSessionsTableView headerBeginRefreshing];
    } else {
        [self requestHomeworkSessions];
    }
}

- (void)reloadWhenHomeworkCorrected:(NSNotification *)notification {
    
#if MANAGERSIDE
    [self resetCurrentSelectIndex];
#endif
    
    if (self.mState != 0) { // 更新已完成、待批改
        [self updateHomeworkSessions:nil];
    }

    
    HomeworkSession *session = notification.userInfo[@"HomeworkSession"];
    if (session == nil)  return;
    BOOL found = NO;
    for (HomeworkSession *s in self.homeworkSessions) {
        if (s.homeworkSessionId == session.homeworkSessionId) {
            [self.homeworkSessions removeObject:s];
            found = YES;
            break;
        }
    }
    if (found) {
        [self updateUI];
    }
}

- (void)lastMessageDidChange:(NSNotification *)notification {
   
    if (!self.isUnfinished) {
        return ;
    }
    AVIMMessage *message = (AVIMMessage *)(notification.userInfo)[@"message"];
    [self reloadTableViewForNewMessage:message];
    NSLog(@"lastMessageDidChange: %@",message);
}


- (void)reloadTableViewForNewMessage:(AVIMMessage *)message
{
    NSDictionary *attributes = ((AVIMTypedMessage *)message).attributes;
#if TEACHERSIDE || MANAGERSIDE
#else
    if (attributes[@"score"] != nil && [attributes[@"score"] integerValue] >= 0) {
        
        [self updateHomeworkSessions:nil];
        return ;
    }
#endif
    
    // 更新新消息内容
    AVIMConversation *messageConversation = [[IMManager sharedManager].client conversationForId:message.conversationId];
    NSString *homeworkSessionId = messageConversation.name;
    // 当前会话已存在
    BOOL bExit = NO;
    for (HomeworkSession *homeworkSession in self.homeworkSessions) {
        if (homeworkSession.homeworkSessionId == homeworkSessionId.integerValue) {
            if (homeworkSession.conversation == nil) {
                homeworkSession.conversation = messageConversation;
            }
            [self loadConversationsWithHomeworkSessions:@[homeworkSession]];
            bExit = YES;
            break;
        }
    }
    
    if (!bExit) {
        
        if (attributes[@"score"] == nil  && self.bLoadConversion) {
            // 会话消息不存在
            WeakifySelf;
            [HomeworkSessionService requestHomeworkSessionWithId:homeworkSessionId.integerValue callback:^(Result *result, NSError *error) {
               
                if (error != nil) return;
                HomeworkSession *session = (HomeworkSession *)(result.userInfo);
                [weakSelf.homeworkSessions addObject:session];
                [weakSelf loadConversationsWithHomeworkSessions:@[session]];
            }];
        }
    }
}

- (void)reloadUnReadMessage:(NSNotification *)notication
{
    //开启子线程做数据处理，避免数据交叉
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger unReadCount = [[notication.userInfo objectForKey:@"unReadCount"] integerValue];
        NSInteger homeworkSessionId = [[notication.userInfo objectForKey:@"homeworkSessionId"] integerValue];
        AVIMMessage * message = [notication.userInfo objectForKey:@"lastMessage"];
        BOOL bExist = NO;  //有可能有些作业需要下拉加载才能请求出来
        //遍历请求下来的数组
        // 数组 was mutated while being enumerated
        for (HomeworkSession * session in self.homeworkSessions)
        {
            if (session.homeworkSessionId == homeworkSessionId)
            {
                bExist = YES;
                session.unreadMessageCount = unReadCount;
                if (unReadCount == 0)
                {
                    //一般由点击事件产生,需要在重新进入页面的时候
//                    [self.unReadHomeworkSessions removeObject:session];
                    [self updateUI];
                }
                else
                {
//                    if (![self.unReadHomeworkSessions containsObject:session])
//                    {
//                        [self.unReadHomeworkSessions addObject:session];
//                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self reloadTableViewForNewMessage:message];
                    });
                }
                break;
            }
        }
    });
}

#pragma mark -
#pragma mark - 获取作业列表  加载更多  处理请求作业列表结果
- (void)requestSearchForName:(NSString *)name
{
    self.searchFilterName = name;
    [self requestHomeworkSessions];
}

- (void)requestSearchForSorceAtIndex:(NSInteger)index
{
    self.searchFliter = index;
    [self requestHomeworkSessions];
}

- (void)requestHomeworkSessions {
   
    // 教师端、管理端作业排序方式 按时间、任务、人
    // 学生端 按得分
    if (self.homeworkSessionsRequest != nil) {
        return;
    }
    if (self.homeworkSessions.count == 0) {
        [self.view showLoadingView];
        self.homeworkSessionsTableView.hidden = YES;
    }
    // mState 0：待批改；1已完成；2未提交
    WeakifySelf;
    if (self.searchFliter == -1)
    {// 教师端：-1 表示是按名字搜索
        
        self.homeworkSessionsRequest =
        [HomeworkSessionService searchHomeworkSessionWithName:self.searchFilterName
                                                     forState:self.mState
                                                    teacherId:self.teacher.userId
                                                     callback:^(Result *result, NSError *error) {
            StrongifySelf;
            [strongSelf handleRequestResult:result isLoadMore:NO error:error];
        }];
    }
    else if (self.searchFliter == 0)
    { // searchFliter   0 按时间
        self.homeworkSessionsRequest =
        [HomeworkSessionService requestHomeworkSessionsWithFinishState:self.mState
                                                             teacherId:self.teacher.userId
                                                              callback:^(Result *result, NSError *error) {
                                                                  
            StrongifySelf;
            [strongSelf handleRequestResult:result
                                 isLoadMore:NO
                                      error:error];
        }];
    }
    else
    {
        
#if TEACHERSIDE || MANAGERSIDE
        // searchFliter  1 按作业 2 按人 (教师端、管理端)
        self.homeworkSessionsRequest =
        [HomeworkSessionService searchHomeworkSessionWithType:self.searchFliter
                                                    teacherId:self.teacher.userId
                                                     forState:self.mState
                                                     callback:^(Result *result, NSError *error) {
            
            StrongifySelf;
            [strongSelf handleRequestResult:result isLoadMore:NO error:error];
        }];
#else
        // searchFliter  按得分 1：0星 2：1星 ··· 6：5星(学生端)
        self.homeworkSessionsRequest =
        [HomeworkSessionService searchHomeworkSessionWithScore:self.searchFliter - 1
                                                     teacherId:self.teacher.userId
                                                      callback:^(Result *result, NSError *error) {
            
            StrongifySelf;
            [strongSelf handleRequestResult:result isLoadMore:NO error:error];
            
        }];
#endif
    }
}
- (void)loadMoreHomeworkSessions {
   
    if (self.homeworkSessionsRequest != nil) {
        return;
    }
    WeakifySelf;
    if (self.searchFliter == -1)
    {// -1 表示是按名字搜索
        self.homeworkSessionsRequest = [HomeworkSessionService searchHomeworkSessionWithNameWithNextUrl:self.nextUrl callback:^(Result *result, NSError *error) {
            StrongifySelf;
            [strongSelf handleRequestResult:result
                                 isLoadMore:YES
                                      error:error];
        }];
    }
    else if (self.searchFliter == 0)
    {// 0 按时间
        self.homeworkSessionsRequest = [HomeworkSessionService requestHomeworkSessionsWithNextUrl:self.nextUrl
                                                                                         callback:^(Result *result, NSError *error) {
                                                                                             StrongifySelf;
                                                                                             [strongSelf handleRequestResult:result
                                                                                                                  isLoadMore:YES                    error:error];
                                                                                         }];
    }
    else
    {
        
#if TEACHERSIDE || MANAGERSIDE
        // searchFliter  1 按作业 2 按人 (教师端、管理端)
        self.homeworkSessionsRequest = [HomeworkSessionService searchHomeworkSessionWithTypeWithNextUrl:self.nextUrl callback:^(Result *result, NSError *error) {
            StrongifySelf;
            [strongSelf handleRequestResult:result isLoadMore:YES error:error];
        }];
#else
        // searchFliter  按得分 1：0星 2：1星 ··· 6：5星(学生端)
        self.homeworkSessionsRequest = [HomeworkSessionService searchHomeworkSessionWithScoreWithNextUrl:self.nextUrl callback:^(Result *result, NSError *error) {
            
            StrongifySelf;
            [strongSelf handleRequestResult:result isLoadMore:YES error:error];
        }];
#endif
    }
}
- (void)handleRequestResult:(Result *)result
                 isLoadMore:(BOOL)isLoadMore
                      error:(NSError *)error {
   
    [self.homeworkSessionsRequest clearCompletionBlock];
    self.homeworkSessionsRequest = nil;
    [self.view hideAllStateView];
    
    NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
    NSString *nextUrl = dictionary[@"next"];
    NSArray *homeworkSessions = dictionary[@"list"];
    
    if (isLoadMore) {
        
        [self.homeworkSessionsTableView footerEndRefreshing];
        self.homeworkSessionsTableView.hidden = NO;
        
        if (error != nil)  return;
        
        if (homeworkSessions.count > 0) {
           
            [self.homeworkSessions addObjectsFromArray:homeworkSessions];
            if (_mState == 0 || _mState == 2) {
                [self loadConversationsWithHomeworkSessions:homeworkSessions];
            } else {
                [self updateUI];
            }
        }
        if (nextUrl.length == 0) {
            [self.homeworkSessionsTableView removeFooter];
        }
    } else {
        // 停止加载
        [self.homeworkSessionsTableView headerEndRefreshing];
        self.homeworkSessionsTableView.hidden = homeworkSessions.count==0;
        
        if (error != nil) {
            if (homeworkSessions.count > 0) {
                [TIP showText:@"加载失败" inView:self.view];
            } else {
                WeakifySelf;
                [self.view showFailureViewWithRetryCallback:^{
                    
                    [weakSelf requestHomeworkSessions];
                }];
            }
            return;
        }
        
        [self.homeworkSessions removeAllObjects];
        self.nextUrl = nil;
        
        if (homeworkSessions.count > 0) {
            
            [self.homeworkSessions addObjectsFromArray:homeworkSessions];
            if (_mState == 0 || _mState == 2) {
                
                [self loadConversationsWithHomeworkSessions:homeworkSessions];
            } else {
                [self updateUI];
            }
           
            self.homeworkSessionsTableView.hidden = NO;
            [self.homeworkSessionsTableView addPullToRefreshWithTarget:self
                                                      refreshingAction:@selector(pullToRefresh)];
            
            if (nextUrl.length > 0) {
                WeakifySelf;
                [self.homeworkSessionsTableView addInfiniteScrollingWithRefreshingBlock:^{
                    [weakSelf loadMoreHomeworkSessions];
                }];
            } else {
                [self.homeworkSessionsTableView removeFooter];
            }
        } else {
            UIImage *image = self.isUnfinished?[UIImage imageNamed:@"缺省插画_无作业"]:nil;
            NSString *text = nil;
            
#if TEACHERSIDE || MANAGERSIDE
            
            if (self.searchFliter == -1) {
                
                text = @"无搜索结果";
            } else{
                text = self.isUnfinished?@"好棒！所有作业都批改完了！":@"还没有批改过的作业~";
            }
#else
            text = self.isUnfinished?@"好棒！所有作业都完成了！\n去同学圈看看大家做得怎么样":@"还没有完成过作业";
#endif
            
            WeakifySelf;
            [self.view showEmptyViewWithImage:image
                                        title:text
                                centerYOffset:0
                                    linkTitle:nil
                            linkClickCallback:nil
                                retryCallback:^{
                                    
                                    [weakSelf requestHomeworkSessions];
                                }];
        }
    }
    self.nextUrl = nextUrl;
}

- (void)pullToRefresh{
    
    [self requestHomeworkSessions];
#if TEACHERSIDE || MANAGERSIDE
#else
    [self requestGetActivityList];
#endif
}

#pragma mark - UITableViewDataSource &&  UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.homeworkSessions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
    if (indexPath.row >= self.homeworkSessions.count) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Empty"];
    }
    HomeworkSessionTableViewCell *cell = nil;
    
    if (self.isUnfinished) {
        cell = [tableView dequeueReusableCellWithIdentifier:UnfinishedStudentHomeworkSessionTableViewCellId forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:FinishedHomeworkSessionTableViewCellId forIndexPath:indexPath];
    }
    HomeworkSession *homeworkSession = self.homeworkSessions[indexPath.row];
    [cell setupWithHomeworkSession:homeworkSession];
    
#if MANAGERSIDE
    // 管理端选中状态
    [cell setupSelectState:(indexPath.row == self.currentSelectIndex) ? YES : NO];
#endif
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    if (indexPath.row >= self.homeworkSessions.count) {
        return 0.f;
    }
    if (self.mState == 1){
        
        HomeworkSession *session = self.homeworkSessions[indexPath.row];
        CGFloat height = [HomeworkSessionTableViewCell cellHeightWithHomeworkSession:session
                                                                            finished:!self.isUnfinished];
        return height;
    }
    return 143;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row >= self.homeworkSessions.count) return ;
    
    NSString *userId;
    NSString *clientId = [IMManager sharedManager].client.clientId;
    AVIMClientStatus status = [IMManager sharedManager].client.status;
#if MANAGERSIDE
    userId = [NSString stringWithFormat:@"%@", @(self.teacher.userId)];
#else
    userId = [NSString stringWithFormat:@"%@", @(APP.currentUser.userId)];
#endif
    
    WeakifySelf;
    if ([userId isEqualToString:clientId] && status == AVIMClientStatusOpened) {
        [self toHomeworkSessionViewController:indexPath];
    } else {
        [[IMManager sharedManager] setupWithClientId:userId callback:^(BOOL success,  NSError * error) {
            if (!success) {
                [HUD showErrorWithMessage:@"IM服务暂不可用，请稍后再试"];
                return ;
            };
            [weakSelf toHomeworkSessionViewController:indexPath];
        }];
    }
}

- (void)toHomeworkSessionViewController:(NSIndexPath *)indexPath{
    
    HomeworkSession *session = self.homeworkSessions[indexPath.row];
#if MANAGERSIDE
    if (session.unreadMessageCount > 0) {
        session.unreadMessageCount = 0;
        [self.homeworkSessionsTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
#endif

    HomeworkSessionViewController *vc = [[HomeworkSessionViewController alloc] initWithNibName:@"HomeworkSessionViewController" bundle:nil];
    vc.homeworkSession = session;
#if MANAGERSIDE
    vc.homeworkSession.conversation = nil;
    vc.teacher = self.teacher;
    if (self.pushVCCallBack) {
        self.pushVCCallBack(vc);
    }
    WeakifySelf;
    vc.dissCallBack = ^{
        [weakSelf resetCurrentSelectIndex];
    };
    self.currentSelectIndex = indexPath.row;
    [self.homeworkSessionsTableView reloadData];
#else
    [vc setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:vc animated:YES];
#endif
}

#pragma mark - 更新UI
- (void)updateUI{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.homeworkSessions.count == 0) {
            UIImage *image = self.isUnfinished?[UIImage imageNamed:@"缺省插画_无作业"]:nil;
            NSString *text = nil;
            
#if TEACHERSIDE || MANAGERSIDE
            if (self.isUnfinished)
            {
                text = self.bLoadConversion? @"好棒！所有作业都批改完了！":@"还有没作业的提交~";
            }
            else
            {
                text = @"还没有批改过的作业~";
            }
#else
            text = self.isUnfinished?@"好棒！所有作业都完成了！\n去同学圈看看大家做得怎么样":@"还没有完成过作业";
#endif
            
            WeakifySelf;
            [self.view showEmptyViewWithImage:image
                                        title:text
                                centerYOffset:0
                                    linkTitle:nil
                            linkClickCallback:nil
                                retryCallback:^{
                                    
                                    [weakSelf requestHomeworkSessions];
                                }];
        } else {
            [self.view hideAllStateView];
            self.homeworkSessionsTableView.hidden = NO;
        }
        [self.homeworkSessionsTableView reloadData];
    });
}

#pragma mark -
#pragma mark - ipad管理：更新作业
- (void)updateSessionList {
    
    [self resetCurrentSelectIndex];
  
    NSString *userId = [NSString stringWithFormat:@"%@", @(self.teacher.userId)];
    NSString *clientId = [IMManager sharedManager].client.clientId;
    AVIMClientStatus status = [IMManager sharedManager].client.status;
    
    WeakifySelf;
    if ([userId isEqualToString:clientId] && status == AVIMClientStatusOpened) {
        
        [weakSelf requestHomeworkSessions];
    } else {
        if (_mState == 0) {
            
            [[IMManager sharedManager] setupWithClientId:userId callback:^(BOOL success,  NSError * error) {
                
                [weakSelf requestHomeworkSessions];
            }];
        } else {
            [self requestHomeworkSessions];
        }
    }
}
#pragma mark - ipad端：重置选中任务状态
- (void)resetCurrentSelectIndex{
    
    self.currentSelectIndex = -1;
    [self.homeworkSessionsTableView reloadData];
}

#pragma mark -
#pragma mark - 学生端 获取活动列表
- (void)requestGetActivityList{
    WeakifySelf;
    [ManagerServce requestGetActivityListWithCallback:^(Result *result, NSError *error) {
        
        NSDictionary *dict = (NSDictionary *)result.userInfo;
        NSArray *list = dict[@"list"];
        
        NSMutableArray *tempList = [NSMutableArray array];
        for (ActivityInfo *actInfo in list) {
            
            NSDate *endDate = [NSDate dateByDateString:actInfo.endTime format:@"yyyy-MM-dd HH:mm:ss"];
            if ([endDate isEarlierThanDate:[NSDate date]]) {
                continue; // 活动结束
            }
            NSDate *startDate = [NSDate dateByDateString:actInfo.startTime format:@"yyyy-MM-dd HH:mm:ss"];
            if ([startDate isLaterThanDate:[NSDate date]]) {
                continue; // 活动未开始
            }
            [tempList addObject:actInfo];
        }
        weakSelf.bannerArray = tempList;
        
        if (weakSelf.mState == 0 && tempList.count > 0) {
            weakSelf.topConstraint.constant = 124;
            [weakSelf.view addSubview:weakSelf.bannerView];
            weakSelf.bannerView.imagesGroup = tempList;
        } else {
            weakSelf.topConstraint.constant = 0;
            if (weakSelf.bannerView.superview) {
                [weakSelf.bannerView removeFromSuperview];
            }
        }
    }];
}

#pragma mark - 学生端 活动 MIActivityBannerViewDelegate
- (void)bannerView:(MIActivityBannerView *)bannerView didSelectItemAtIndex:(NSInteger)index{
    
#if TEACHERSIDE || MANAGERSIDE
#else
    ActivityInfo *actInfo = self.bannerArray[index];
    MISutdentActDetailViewController *stuActDetailVC = [[MISutdentActDetailViewController alloc] initWithNibName:NSStringFromClass([MISutdentActDetailViewController class]) bundle:nil];
    stuActDetailVC.actInfo = actInfo;
    WeakifySelf;
    stuActDetailVC.actCallBack = ^{
        [weakSelf requestGetActivityList];
    };
    [stuActDetailVC setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:stuActDetailVC animated:YES];
    
#endif
}

#pragma mark - setter && getter
- (MIActivityBannerView *)bannerView
{
    if (!_bannerView) {
        _bannerView = [[MIActivityBannerView alloc] initWithFrame:CGRectMake(0, 12, ScreenWidth, 110)];
        _bannerView.delegate = self;
        _bannerView.backgroundColor = [UIColor bgColor];
    }
    return _bannerView;
}

- (void)registerCellNibs {
    [self.homeworkSessionsTableView registerNib:[UINib nibWithNibName:@"FinishedHomeworkSessionTableViewCell" bundle:nil] forCellReuseIdentifier:FinishedHomeworkSessionTableViewCellId];
    [self.homeworkSessionsTableView registerNib:[UINib nibWithNibName:@"UnfinishedStudentHomeworkSessionTableViewCell" bundle:nil] forCellReuseIdentifier:UnfinishedStudentHomeworkSessionTableViewCellId];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.homeworkSessionsRequest clearCompletionBlock];
    [self.homeworkSessionsRequest stop];
    self.homeworkSessionsRequest = nil;
    
    NSLog(@"%s", __func__);
}
@end



