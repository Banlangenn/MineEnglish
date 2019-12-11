//
//  TrialClassViewController.m
//  MinnieStudent
//
//  Created by yebw on 2018/4/12.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import "CircleService.h"
#import "CircleHomework.h"
#import "EntranceClassView.h"
#import "UIScrollView+Refresh.h"
#import "CircleVideoTableViewCell.h"
#import "CircleLikeUsersTableViewCell.h"
#import "CircleCommentTableViewCell.h"
#import "CircleMoreCommentsTableViewCell.h"
#import "CircleBottomTableViewCell.h"
#import "MIPlayerViewController.h"

#import "IMManager.h"
#import "AlertView.h"
#import "PushManager.h"
#import "AuthService.h"
#import "AppDelegate.h"
#import "ManagerServce.h"
#import "TrialClassService.h"
#import "LoginViewController.h"
#import "EnrollTrialClassView.h"
#import "AppDelegate+ConfigureUI.h"
#import "TrialClassViewController.h"
#import "PortraitNavigationController.h"
#import <SDWebImage/UIImageView+WebCache.h>


@interface TrialClassViewController ()<
UITableViewDelegate,
UITableViewDataSource
>
// 关于米妮
@property (weak, nonatomic) IBOutlet UIButton *aboutBtn;
// 同学圈
@property (weak, nonatomic) IBOutlet UIButton *schoolCircleBtn;

// 报名
@property (weak, nonatomic) IBOutlet UIButton *enrollBtn;
// 入学
@property (weak, nonatomic) IBOutlet UIButton *entranceBtn;

@property (weak, nonatomic) IBOutlet UIView *btnBgView;

// 等待审核
@property (weak, nonatomic) IBOutlet UIButton *waitBtn;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *grade;
@property (nonatomic, assign) NSInteger gender;
@property (weak, nonatomic) IBOutlet UIImageView *firstImageView;
@property (weak, nonatomic) IBOutlet UIImageView *secondImageView;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;// 关于
@property (weak, nonatomic) IBOutlet UITableView *circleTableView;// 同学圈

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *image1ViewHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *image2ViewHeight;

@property (nonatomic, assign) BOOL bFirstDown;
@property (nonatomic, assign) BOOL bSecondDown;

@property (nonatomic, strong) NSArray *images;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger contentHeight;
@property (nonatomic, strong) NSMutableArray *imageViews;

@property (nonatomic, strong) NSMutableArray *homeworks;
@property (nonatomic, copy) NSString *nextUrl;


@end

@implementation TrialClassViewController

- (void)viewDidLoad {
   
    [super viewDidLoad];
    self.homeworks = [NSMutableArray array];

    [self configureUI];
    [self requestImages];
    [self registerCellNibs];
}

- (void)configureUI{
    
    Student *user = APP.currentUser;
    if (user.enrollState == 1) {
        [self.waitBtn setTitle:@"报名审核中，请耐心等待..." forState:UIControlStateNormal];
        self.btnBgView.hidden = YES;
        self.waitBtn.hidden = NO;
    } else {
             
        self.btnBgView.hidden = NO;
        self.waitBtn.hidden = YES;
    }
    [self showCircle:NO];
    self.aboutBtn.selected = YES;
    self.schoolCircleBtn.selected = NO;
    
    self.circleTableView.tableFooterView = [UIView new];
    self.circleTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    if (user.enrollState == 1) {
        [self showEnrolledAlertView];
    }
}

- (void)showCircle:(BOOL)show{
    
    if (show) {// 同学圈
        self.scrollView.hidden = YES;
        self.circleTableView.hidden = NO;
        
    } else {// 关于

        self.scrollView.hidden = NO;
        self.circleTableView.hidden = YES;
    }
}

- (void)checkDownloadFinish
{
    if (self.bFirstDown && self.bSecondDown)
    {
        self.contentViewHeight.constant = self.image1ViewHeight.constant + self.image2ViewHeight.constant + 100;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    Student *user = APP.currentUser;
}

- (void)showEnrolledAlertView {
   
    [self.waitBtn setTitle:@"报名审核中，请耐心等待..." forState:UIControlStateNormal];
    
    [AlertView showInView:self.view
                withImage:[UIImage imageNamed:@"pop_img_welcome"]
                    title:@"欢迎加入minnie英文教室"
                  message:@"你目前已报名, 请等待教师回复"
                   action:@"知道啦"
           actionCallback:^{
           }];
}


#pragma mark - pressed action
- (IBAction)exitButtonPressed:(id)sender {

    AppDelegate * app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [app logout];
}

- (IBAction)aboutButtonPressed:(id)sender {
    
    self.aboutBtn.selected = YES;
    self.schoolCircleBtn.selected = NO;
    [self showCircle:NO];
}

- (IBAction)schoolCircleButtonPressed:(id)sender {
    
    self.aboutBtn.selected = NO;
    self.schoolCircleBtn.selected = YES;
    [self showCircle:YES];
    if (self.homeworks.count == 0) {
        [self requestAllHomeworks];
    }
}

// 报名
- (IBAction)enrollButtonPressed:(id)sender {
    
    Student *user = APP.currentUser;
    if (user.enrollState == 1) return;
    [EnrollTrialClassView showInSuperView:self.view
                                 callback:^(NSString *name,
                                            NSString *grade,
                                            NSInteger gender) {
                                     self.name = name;
                                     self.grade = grade;
                                     self.gender = gender;
                                     
                                     [HUD showProgressWithMessage:@"正在报名..."];
                                     [TrialClassService enrollWithName:self.name
                                                                 grade:self.grade
                                                                gender:self.gender
                                                              callback:^(Result *result, NSError *error) {
                                                                  if (error != nil) {
                                                                      [HUD showErrorWithMessage:@"报名失败"];
                                                                  } else {
                                                                      [HUD showWithMessage:@"报名成功"];
                                                                      
                                                                      NSString *gender = self.gender==1?@"男孩":@"女孩";
                                                                      NSString *text = [NSString stringWithFormat:@"%@的%@ %@(%@) 报名", self.grade, gender, self.name, APP.currentUser.username];
                                                                      
                                                                      [PushManager pushText:text
                                                                                    toUsers:@[]
                                                                                addChannels:@[@"SuperManager"]];
                                                                      
                                                                      [EnrollTrialClassView hideAnimated:YES];
                                                                      
                                                                      Student *user = APP.currentUser;
                                                                      user.clazz = nil;
                                                                      user.enrollState = 1;
                                                                      APP.currentUser = user;
                                                                      
                                                                      [self showEnrolledAlertView];
                                                                  }
                                                              }];
                                     
                                    // [self showEnrollAlert];
                                 }];
}

// 入学
- (IBAction)entranceButtonPressed:(id)sender {
    
    [EntranceClassView showInSuperView:self.view callback:^(NSString * _Nonnull inviteCode) {
       
        
    }];
    
}

// 等待
- (IBAction)waitButtonPressed:(id)sender {
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.homeworks.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
    CircleHomework *homework = self.homeworks[section];
    
    NSInteger number = 1; // 同学圈内容
    number ++; // 点赞区域始终有，根据高度来确定显不显示
    if (homework.comments.count > 0) {
        number += homework.comments.count; // 返回的评论，可能不是全部
        if (homework.comments.count < homework.commentCount) { // 查看全部的按钮
            number += 1;
        }
    }
    number ++; // 最后圆角白底
    
    return number;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    
    CircleHomework *homework = self.homeworks[indexPath.section];
    if (indexPath.row == 0) { //
        if (homework.videoUrl.length > 0) {
            CircleVideoTableViewCell *videoCell = [tableView dequeueReusableCellWithIdentifier:CircleVideoTableViewCellId forIndexPath:indexPath];
            
            [videoCell setupWithHomework:homework];
            WeakifySelf;
            [videoCell setVideoClickCallback:^{
                [weakSelf playVideoWithHomework:homework];
            }];
            cell = videoCell;
        }
    } else if (indexPath.row == 1) {
        if (homework.likeUsers.count == 0) {
            UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:@"BlankLikeUsersCellId"];
            if (blankCell == nil) {
                blankCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"BlankLikeUsersCellId"];
            }
            
            cell = blankCell;
        } else {
            CircleLikeUsersTableViewCell *likeUsersCell = [tableView dequeueReusableCellWithIdentifier:CircleLikeUsersTableViewCellId forIndexPath:indexPath];
            
            [likeUsersCell setupWithLikeUsers:homework.likeUsers];
            cell = likeUsersCell;
        }
    } else {
        NSArray *comments = homework.comments;
        NSInteger index = indexPath.row - 2;
        if (index < comments.count) {
            CircleCommentTableViewCell *commentCell = [tableView dequeueReusableCellWithIdentifier:CircleCommentTableViewCellId forIndexPath:indexPath];
            
            Comment *comment = homework.comments[index];
            BOOL isLastOne = (homework.comments.count-1) == index;
            [commentCell setupWithComment:comment
                               isFirstOne:index==0
                                isLastOne:isLastOne
                                  hasMore:homework.comments.count<homework.commentCount];
            
            cell = commentCell;
        } else {
            if (comments.count < homework.commentCount && index == comments.count) {
                CircleMoreCommentsTableViewCell *moreCell = [tableView dequeueReusableCellWithIdentifier:CircleMoreCommentsTableViewCellId forIndexPath:indexPath];
                cell = moreCell;
            } else {
                CircleBottomTableViewCell *bottomCell = [tableView dequeueReusableCellWithIdentifier:CircleBottomTableViewCellId forIndexPath:indexPath];
                
                cell = bottomCell;
            }
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CircleHomework *homework = self.homeworks[indexPath.section];
    
    if (indexPath.row == 0) { // 内容区域
        if (homework.videoUrl.length > 0) {
            return [CircleVideoTableViewCell cellHeight];
        }
        
        return 0;
    } else if (indexPath.row == 1) { // 点赞用户区域
        if (homework.likeUsers.count == 0) {
            return 0.f;
        }
        return [CircleLikeUsersTableViewCell heightWithLikeUsers:homework.likeUsers];
    } else {
        NSArray *comments = homework.comments;
        NSInteger index = indexPath.row - 2;
        if (index < comments.count) {
            Comment *comment = comments[index];
            BOOL isLastOne = (comments.count-1) == index;
            return [CircleCommentTableViewCell heightOfComment:comment isFirstOne:index==0 isLastOne:isLastOne];
        } else {
            if (index==comments.count && homework.commentCount>comments.count) {
                return CircleMoreCommentsTableViewCellHeight;
            } else {
                return CircleBottomTableViewCellHeight;
            }
        }
    }
}

#pragma mark - privacy

- (void)showEnrollAlert {
    NSString *message = @"是否报名？确认后我们将通过电话联系您，请保持电话畅通";
    
    [AlertView showInView:self.view
                withImage:[UIImage imageNamed:@"pop_img_welcome"]
                    title:@"确认"
                  message:message
                  action1:@"取消"
          action1Callback:^{
          }
                  action2:@"确认"
          action2Callback:^{
              [HUD showProgressWithMessage:@"正在报名..."];
              [TrialClassService enrollWithName:self.name
                                          grade:self.grade
                                         gender:self.gender
                                       callback:^(Result *result, NSError *error) {
                                           if (error != nil) {
                                               [HUD showErrorWithMessage:@"报名失败"];
                                           } else {
                                               [HUD showWithMessage:@"报名成功"];
                                               
                                               NSString *gender = self.gender==1?@"男孩":@"女孩";
                                               NSString *text = [NSString stringWithFormat:@"%@的%@ %@(%@) 报名", self.grade, gender, self.name, APP.currentUser.username];

                                               [PushManager pushText:text
                                                             toUsers:@[]
                                                         addChannels:@[@"SuperManager"]];
                                               
                                               [EnrollTrialClassView hideAnimated:YES];
                                               
                                               Student *user = APP.currentUser;
                                               user.clazz = nil;
                                               user.enrollState = 1;
                                               APP.currentUser = user;
                                               
                                               [self showEnrolledAlertView];
                                           }
                                       }];
          }];
}

- (void)playVideoWithHomework:(CircleHomework *)homework {
  
    NSString *url = homework.videoUrl;
    MIPlayerViewController *playerViewController = [[MIPlayerViewController alloc]init];
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [playerViewController playVideoWithUrl:url];
    playerViewController.view.frame = [UIScreen mainScreen].bounds;
}

- (void)requestImages{
    
    [ManagerServce getWelcomesImagesWithType:0 callback:^(Result *result, NSError *error) {
        
        if (error) {
            
            UIImage *image = [UIImage imageNamed:@"首页1.png"];
            UIImageView *imageV = [[UIImageView alloc] initWithImage:image];
            [self.contentView addSubview:imageV];
            
            CGFloat imageHeight = ScreenWidth * image.size.height / image.size.width;
            imageV.frame = CGRectMake(0,0, ScreenWidth, imageHeight);
            self.contentViewHeight.constant = imageHeight;
            return ;
        }
        
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *list = (NSArray *)(dict[@"urls"]);
        
        self.images = list;
        self.currentIndex = 0;
        self.contentHeight = 0;
        [self updateContentImage];
    }];
}

#pragma mark - 获取展示图片
- (void)updateContentImage{
    
    if (self.currentIndex >= self.images.count) {
        return;
    }
    NSString * imageUrl = self.images[self.currentIndex];
    
    UIImageView *imageV = [[UIImageView alloc] init];
    [self.contentView addSubview:imageV];

    [imageV sd_setImageWithURL:[NSURL URLWithString:imageUrl] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
       
        if (image.size.width > 0) {
            
            CGFloat imageHeight = ScreenWidth * image.size.height / image.size.width;
            CGRect rect = CGRectMake(0, self.contentHeight , ScreenWidth, imageHeight);
            imageV.frame = rect;
            self.contentHeight = self.contentHeight + imageHeight;
            self.contentViewHeight.constant = self.contentHeight;
        }
        self.currentIndex++;
        [self updateContentImage];
    }];
}

#pragma mark - 获取全校同学圈
- (void)requestAllHomeworks{
    
    if (self.homeworks.count == 0) {
        [self.view showLoadingView];
        self.circleTableView.hidden = YES;
    }
    [CirlcleService requestAllHomeworksWithCallback:^(Result *result, NSError *error) {

        [self handleRequestResult:result
                             isLoadMore:NO
                                  error:error];
    }];
}

- (void)loadMoreHomeworks{
        
    [CirlcleService loadMoreHomeworksWithURL:self.nextUrl
                                    callback:^(Result *result, NSError *error) {
        
        [self handleRequestResult:result
                             isLoadMore:YES
                                  error:error];
    }];
}


- (void)handleRequestResult:(Result *)result
                 isLoadMore:(BOOL)isLoadMore
                      error:(NSError *)error {

    NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
    NSString *nextUrl = dictionary[@"next"];
    NSArray *homeworks = dictionary[@"list"];
    [self.view hideAllStateView];
    self.circleTableView.hidden = NO;
    
    if (isLoadMore) {
        [self.circleTableView footerEndRefreshing];
        
        if (error != nil) {
            return;
        }
        
        if (homeworks.count > 0) {
            [self.homeworks addObjectsFromArray:homeworks];
        }
        
        if (nextUrl.length == 0) {
            [self.circleTableView removeFooter];
        }
        [self.circleTableView reloadData];
    } else {
        // 停止加载
        [self.circleTableView headerEndRefreshing];
        
        if (error != nil) {
            if (homeworks.count > 0) {
                [TIP showText:@"加载失败" inView:self.view];
            } else {
                WeakifySelf;
                self.circleTableView.hidden = YES;
                [self.view showFailureViewWithRetryCallback:^{
                    [weakSelf requestAllHomeworks];
                }];
            }
            return;
        }
        
        [self.homeworks removeAllObjects];
        self.nextUrl = nil;
        
        if (homeworks.count > 0) {
            
            [self.homeworks addObjectsFromArray:homeworks];
            [self.circleTableView reloadData];
            
            [self.circleTableView addPullToRefreshWithTarget:self
                                               refreshingAction:@selector(requestAllHomeworks)];
            
            if (nextUrl.length > 0) {
                WeakifySelf;
                [self.circleTableView addInfiniteScrollingWithRefreshingBlock:^{
                    [weakSelf loadMoreHomeworks];
                }];
            } else {
                [self.circleTableView removeFooter];
            }
            
            APP.circleList = self.homeworks;
            
        } else {
            WeakifySelf;
            self.circleTableView.hidden = YES;
            [self.view showEmptyViewWithImage:nil
                                        title:@"暂无同学圈内容"
                                centerYOffset:0
                                    linkTitle:nil
                            linkClickCallback:nil
                                retryCallback:^{
                                    [weakSelf requestAllHomeworks];
                                }];
        }
    }
    
    self.nextUrl = nextUrl;
}

- (void)registerCellNibs {
    
    [self.circleTableView registerNib:[UINib nibWithNibName:@"CircleVideoTableViewCell" bundle:nil] forCellReuseIdentifier:CircleVideoTableViewCellId];
    [self.circleTableView registerNib:[UINib nibWithNibName:@"CircleLikeUsersTableViewCell" bundle:nil] forCellReuseIdentifier:CircleLikeUsersTableViewCellId];
    [self.circleTableView registerNib:[UINib nibWithNibName:@"CircleCommentTableViewCell" bundle:nil] forCellReuseIdentifier:CircleCommentTableViewCellId];
    [self.circleTableView registerNib:[UINib nibWithNibName:@"CircleMoreCommentsTableViewCell" bundle:nil] forCellReuseIdentifier:CircleMoreCommentsTableViewCellId];
    [self.circleTableView registerNib:[UINib nibWithNibName:@"CircleBottomTableViewCell" bundle:nil] forCellReuseIdentifier:CircleBottomTableViewCellId];
}
@end



