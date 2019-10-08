//
//  HomeworkManagerViewController.m
//  X5Teacher
//
//  Created by yebw on 2018/2/3.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "HomeworkManagerViewController.h"
#import "Homework.h"
#import "HomeworkService.h"
#import "HomeworkTableViewCell.h"
#import "CreateHomeworkViewController.h"
#import "UIScrollView+Refresh.h"
#import "SearchHomeworkViewController.h"
#import "ClassAndStudentSelectorController.h"

#import "NEPhotoBrowser.h"
#import <AVKit/AVKit.h>
#import "HomeworkPreviewViewController.h"
#import "HomeWorkSendHistoryViewController.h"
#import "AudioPlayerViewController.h"
#import "VIResourceLoaderManager.h"
#import "VICacheManager.h"

@interface HomeworkManagerViewController ()<UITableViewDataSource, UITableViewDelegate, NEPhotoBrowserDataSource, NEPhotoBrowserDelegate,VIResourceLoaderManagerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *homeworksTableView;
@property (nonatomic, weak) IBOutlet UIButton *backButton;
@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (nonatomic, weak) IBOutlet UIButton *sendButton;
@property (nonatomic, weak) IBOutlet UILabel *deleteCountLabel;
@property (nonatomic, weak) IBOutlet UIButton *deleteButton;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *searchViewTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet UIButton *exitManagerBtn;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *operationViewBottomLayoutConstraint;

@property (nonatomic, assign) BOOL inEditMode;

@property (nonatomic, strong) BaseRequest *homeworksRequest;

@property (nonatomic, strong) NSMutableArray <Homework *> *homeworks;
@property (nonatomic, strong) NSString *nextUrl;

@property (nonatomic, strong) NSMutableArray <NSNumber *> *selectedHomeworkIds;

@property (nonatomic, assign) BOOL shouldReloadWhenAppeared;

@property (nonatomic, strong) NEPhotoBrowser *photoBrowser;
@property (nonatomic, weak) UIImageView *currentSelectedImageView;
@property (nonatomic, weak) NSString *currentSelectedImageUrl;
@property (nonatomic, strong) VIResourceLoaderManager *resourceLoaderManager;
@end

@implementation HomeworkManagerViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        _homeworks = [NSMutableArray array];
        _selectedHomeworkIds = [NSMutableArray array];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.deleteCountLabel.layer.cornerRadius = 11;
    self.deleteCountLabel.layer.masksToBounds = YES;
    
    self.operationViewBottomLayoutConstraint.constant = -50.f;
    
    [self registerCellNibs];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 12.f)];
    self.homeworksTableView.tableFooterView = footerView;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldReloadDataWhenAppeared:)
                                                 name:kNotificationKeyOfAddHomework
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeworkDidSendSuccess) name:kNotificationKeyOfHomeworkSendSuccess object:nil];
    
    [self requestHomeworks];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.shouldReloadWhenAppeared) {
        self.shouldReloadWhenAppeared = NO;
        
        [self.homeworks removeAllObjects];
        self.nextUrl = nil;
        
        [self.homeworksRequest stop];
        self.homeworksRequest = nil;
        
        [self requestHomeworks];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.homeworksRequest clearCompletionBlock];
    [self.homeworksRequest stop];
    self.homeworksRequest = nil;
    
    NSLog(@"%s", __func__);
}

- (IBAction)createButtonPressed:(id)sender {
    if (!APP.currentUser.canManageHomeworks) {
        [HUD showErrorWithMessage:@"无操作权限"];
        
        return;
    }
    
    CreateHomeworkViewController *createHomeworkVC = [[CreateHomeworkViewController alloc] initWithNibName:@"CreateHomeworkViewController" bundle:nil];
    [self.navigationController pushViewController:createHomeworkVC animated:YES];
}

- (IBAction)historyListButtonPressed:(UIButton *)sender {
    
    if (!APP.currentUser.canManageHomeworks) {
        [HUD showErrorWithMessage:@"无操作权限"];
        
        return;
    }
    
    HomeWorkSendHistoryViewController * historyHomeworkVC = [[HomeWorkSendHistoryViewController alloc] initWithNibName:@"HomeWorkSendHistoryViewController" bundle:nil];
    [self.navigationController pushViewController:historyHomeworkVC animated:YES];
    
}

- (IBAction)manageButtonPressed:(id)sender {
    if (self.inEditMode) {
        self.exitManagerBtn.hidden = YES;
        self.backButton.hidden = NO;
        self.searchViewTopLayoutConstraint.constant = 0.f;
        self.operationViewBottomLayoutConstraint.constant = -50.f;
        
        [self.selectedHomeworkIds removeAllObjects];
        self.deleteCountLabel.text = @"0";
        self.deleteButton.enabled = NO;
        self.sendButton.enabled = NO;
    } else {
        self.backButton.hidden = YES;
        self.exitManagerBtn.hidden = NO;
//        [self.manageButton setTitle:@"退出" forState:UIControlStateNormal];
        self.searchViewTopLayoutConstraint.constant = -46.f;
        self.operationViewBottomLayoutConstraint.constant = 0.f;
        if (isIPhoneX) {
            self.operationViewBottomLayoutConstraint.constant = 34.f;
        }
    }
    
    self.inEditMode = !self.inEditMode;
    
    [self.homeworksTableView reloadData];
}

- (IBAction)searchButtonPressed:(id)sender {
    SearchHomeworkViewController *vc = [[SearchHomeworkViewController alloc] initWithNibName:@"SearchHomeworkViewController" bundle:nil];
    vc.fieldId = 0;
    [self.navigationController pushViewController:vc animated:NO];
}

- (IBAction)sendButtonPressed:(id)sender {
    if (self.selectedHomeworkIds.count == 0) {
        return;
    }
    
    NSMutableArray *homeworks = [NSMutableArray array];
    
    for (int i = 0; i < self.selectedHomeworkIds.count; i++)
    {
        NSNumber * homeSelectId = [self.selectedHomeworkIds objectAtIndex:i];
        for (Homework *homework in self.homeworks) {
            if ([homeSelectId integerValue] == homework.homeworkId)
            {
                [homeworks addObject:homework];
            }
        }
    }
    
    ClassAndStudentSelectorController *vc = [[ClassAndStudentSelectorController alloc] init];
    [vc setHomeworks:homeworks];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.tabBarController presentViewController:nav animated:YES completion:nil];
}

- (IBAction)deleteButtonPressed:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认删除?"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"删除"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [HUD showProgressWithMessage:@"正在删除"];
                                                              
                                                              [HomeworkService deleteHomeworks:self.selectedHomeworkIds
                                                                                      callback:^(Result *result, NSError *error) {
                                                                                          if (error != nil) {
                                                                                              [HUD showErrorWithMessage:@"删除失败"];
                                                                                              return;
                                                                                          }
                                                                                          
                                                                                          [HUD showWithMessage:@"删除成功"];
                                                                                          
                                                                                          [self.homeworks removeAllObjects];
                                                                                          [self.selectedHomeworkIds removeAllObjects];
                                                                                          self.nextUrl = nil;
                                                                                          
                                                                                          [self.homeworksTableView reloadData];
                                                                                          
                                                                                          [self manageButtonPressed:nil];
                                                                                          [self requestHomeworks];
                                                                                      }];
                                                          }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];

    alertController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.tabBarController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Private Methods

- (void)shouldReloadDataWhenAppeared:(NSNotification *)notification {
    self.shouldReloadWhenAppeared = YES;
}

- (void)homeworkDidSendSuccess{
    self.inEditMode = YES;
    [self manageButtonPressed:nil];
}

- (void)registerCellNibs {
    [self.homeworksTableView registerNib:[UINib nibWithNibName:NSStringFromClass([HomeworkTableViewCell class]) bundle:nil] forCellReuseIdentifier:HomeworkTableViewCellId];
}

- (void)requestHomeworks {
    if (self.homeworksRequest != nil) {
        return;
    }
    
    [self.containerView showLoadingView];
    self.homeworksTableView.hidden = YES;
    
    WeakifySelf;
    self.homeworksRequest = [HomeworkService requestHomeworksWithCallback:^(Result *result, NSError *error) {
        StrongifySelf;
        [strongSelf handleRequestResult:result error:error];
    }];
}

- (void)loadMoreHomeworks {
    if (self.homeworksRequest != nil) {
        return;
    }
    
    WeakifySelf;
    self.homeworksRequest = [HomeworkService requestHomeworksWithNextUrl:self.nextUrl
                                                                callback:^(Result *result, NSError *error) {
                                                                    StrongifySelf;
                                                                    [strongSelf handleRequestResult:result error:error];
                                                                }];
}


- (void)handleRequestResult:(Result *)result error:(NSError *)error {
    self.homeworksRequest = nil;
    
    [self.containerView hideAllStateView];
    
    NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
    NSString *nextUrl = dictionary[@"next"];
    NSArray *homeworks = dictionary[@"list"];
    
    BOOL isLoadMore = self.nextUrl.length > 0;
    if (isLoadMore) {
        [self.homeworksTableView footerEndRefreshing];
        self.homeworksTableView.hidden = NO;
        
        if (error != nil) {
            return;
        }
        
        if (homeworks.count > 0) {
            [self.homeworks addObjectsFromArray:homeworks];
        }
        
        if (nextUrl.length == 0) {
            [self.homeworksTableView removeFooter];
        }
        
        [self.homeworksTableView reloadData];
    } else {
        // 停止加载
        [self.homeworksTableView headerEndRefreshing];
        self.homeworksTableView.hidden = homeworks.count==0;
        
        if (error != nil) {
            if (homeworks.count > 0) {
                [TIP showText:@"加载失败" inView:self.view];
            } else {
                WeakifySelf;
                [self.containerView showFailureViewWithRetryCallback:^{
                    [weakSelf requestHomeworks];
                }];
            }
            
            return;
        }
        
        if (homeworks.count > 0) {
            [self.view hideAllStateView];
            self.homeworksTableView.hidden = NO;
            
            [self.homeworks addObjectsFromArray:homeworks];
            [self.homeworksTableView reloadData];
            
            if (nextUrl.length > 0) {
                WeakifySelf;
                [self.homeworksTableView addInfiniteScrollingWithRefreshingBlock:^{
                    [weakSelf loadMoreHomeworks];
                }];
            } else {
                [self.homeworksTableView removeFooter];
            }
        } else {
            [self.view showEmptyViewWithImage:nil
                                        title:@"暂无作业"
                                centerYOffset:0
                                    linkTitle:nil
                            linkClickCallback:nil];
        }
    }
    
    self.nextUrl = nextUrl;
}

- (void)showCurrentSelectedImage {
    self.photoBrowser = [[NEPhotoBrowser alloc] init];
    self.photoBrowser.delegate = self;
    self.photoBrowser.dataSource = self;
    self.photoBrowser.clickedImageView = self.currentSelectedImageView;
    
    [self.photoBrowser showInContext:self.navigationController];
}

- (void)showVideoWithUrl:(NSString *)videoUrl {
    AVAudioSession *session =[AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSInteger playMode = [[Application sharedInstance] playMode];

    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc]init];
    AVPlayer *player;
    if (playMode == 1)// 在线播放
    {
        [VICacheManager cleanCacheForURL:[NSURL URLWithString:videoUrl] error:nil];
        player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:videoUrl]];
    }
    else
    {
        VIResourceLoaderManager *resourceLoaderManager = [VIResourceLoaderManager new];
        resourceLoaderManager.delegate = self;
        self.resourceLoaderManager = resourceLoaderManager;
        AVPlayerItem *playerItem = [resourceLoaderManager playerItemWithURL:[NSURL URLWithString:videoUrl]];
        player = [AVPlayer playerWithPlayerItem:playerItem];
    }
    playerViewController.player = player;
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.view.frame = self.view.frame;
    [playerViewController.player play];
}

- (void)showAudioWithURL:(NSString *)url withCoverURL:(NSString *)coverUrl
{
    AVAudioSession *session =[AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    AudioPlayerViewController *playerViewController = [[AudioPlayerViewController alloc]init];
    NSInteger playMode = [[Application sharedInstance] playMode];
    AVPlayer *player;
    if (playMode == 1)// 在线播放
    {
        [VICacheManager cleanCacheForURL:[NSURL URLWithString:url] error:nil];
        player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:url]];
    }
    else
    {
        VIResourceLoaderManager *resourceLoaderManager = [VIResourceLoaderManager new];
        resourceLoaderManager.delegate = self;
        self.resourceLoaderManager = resourceLoaderManager;
        AVPlayerItem *playerItem = [resourceLoaderManager playerItemWithURL:[NSURL URLWithString:url]];
        player = [AVPlayer playerWithPlayerItem:playerItem];
    }
    
    
    playerViewController.player = player;

    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.view.frame = self.view.frame;
    [playerViewController.player play];
    [playerViewController setOverlyViewCoverUrl:coverUrl];
}

#pragma mark - VIResourceLoaderManagerDelegate
- (void)resourceLoaderManagerLoadURL:(NSURL *)url didFailWithError:(NSError *)error
{
    [VICacheManager cleanCacheForURL:url error:nil];
    // 适配ipad版本
    UIAlertControllerStyle alertStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        alertStyle = UIAlertControllerStyleActionSheet;
    } else {
        alertStyle = UIAlertControllerStyleAlert;
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil
                                                                     message:@"播放失败"
                                                              preferredStyle:alertStyle];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self.tabBarController dismissViewControllerAnimated:YES completion:^{
                                                                 
                                                             }];
                                                         }];
    
    [alertVC addAction:cancelAction];

    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertVC
                       animated:YES
                     completion:nil];
    
}

#pragma mark - NEPhotoBrowserDataSource

- (NSInteger)numberOfPhotosInPhotoBrowser:(NEPhotoBrowser *)browser {
    return 1;
}
- (NSURL* __nonnull)photoBrowser:(NEPhotoBrowser * __nonnull)browser imageURLForIndex:(NSInteger)index {
    return [NSURL URLWithString:self.currentSelectedImageUrl];
}

- (UIImage * __nullable)photoBrowser:(NEPhotoBrowser * __nonnull)browser placeholderImageForIndex:(NSInteger)index {
    return self.currentSelectedImageView.image;
}

#pragma mark - NEPhotoBrowserDelegate

- (void)photoBrowser:(NEPhotoBrowser * __nonnull)browser willSavePhotoWithView:(NEPhotoBrowserView *)view {
    [HUD showProgressWithMessage:@"正在保存图片"];
}

- (void)photoBrowser:(NEPhotoBrowser * __nonnull)browser didSavePhotoSuccessWithImage:(UIImage *)image {
    [HUD showWithMessage:@"保存图片成功"];
}

- (void)photoBrowser:(NEPhotoBrowser * __nonnull)browser savePhotoErrorWithError:(NSError *)error {
    [HUD showErrorWithMessage:@"保存图片失败"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.homeworks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HomeworkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HomeworkTableViewCellId forIndexPath:indexPath];
    Homework *homework = self.homeworks[indexPath.row];
    
    [cell setupWithHomework:homework];
    [cell updateWithEditMode:self.inEditMode selected:[self.selectedHomeworkIds containsObject:@(homework.homeworkId)]];
    
    WeakifySelf;
    [cell setSelectCallback:^{
        if ([weakSelf.selectedHomeworkIds containsObject:@(homework.homeworkId)]) {
            [weakSelf.selectedHomeworkIds removeObject:@(homework.homeworkId)];
        } else {
            [weakSelf.selectedHomeworkIds addObject:@(homework.homeworkId)];
        }
        
        weakSelf.deleteCountLabel.text = [NSString stringWithFormat:@"%zd", weakSelf.selectedHomeworkIds.count];
        weakSelf.deleteButton.enabled = weakSelf.selectedHomeworkIds.count>0;
        weakSelf.sendButton.enabled = weakSelf.selectedHomeworkIds.count>0;
    }];
    
    // 作业预览
    [cell setPreviewCallback:^{
        
        HomeworkPreviewViewController *vc = [[HomeworkPreviewViewController alloc] init];
        vc.homework = homework;
        [weakSelf.navigationController pushViewController:vc animated:YES];
    }];
    
    // 点击空白处 -> 作业详情
    [cell setBlankCallback:^{
        
        CreateHomeworkViewController *createHomeworkVC = [[CreateHomeworkViewController alloc] initWithNibName:@"CreateHomeworkViewController" bundle:nil];
        createHomeworkVC.homework = homework;
        [self.navigationController pushViewController:createHomeworkVC animated:YES];
    }];
    [cell setSendCallback:^{
        ClassAndStudentSelectorController *vc = [[ClassAndStudentSelectorController alloc] init];
        [vc setHomeworks:@[homework]];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [weakSelf.tabBarController presentViewController:nav animated:YES completion:nil];
    }];
    
    [cell setImageCallback:^(UIImageView *imageView, NSString *imageUrl) {
        weakSelf.currentSelectedImageView = imageView;
        weakSelf.currentSelectedImageUrl = imageUrl;
        
        [weakSelf showCurrentSelectedImage];
    }];
    
    [cell setVideoCallback:^(NSString *videoUrl) {
        [weakSelf showVideoWithUrl:videoUrl];
    }];
    
    [cell setAudioCallback:^(NSString * audioUrl, NSString * audioCoverUrl) {
        [weakSelf showAudioWithURL:audioUrl withCoverURL:audioCoverUrl];
    }];
    
    if (!cell) {
        
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        return cell;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Homework *homework = self.homeworks[indexPath.row];
    CGFloat height = [HomeworkTableViewCell cellHeightWithHomework:homework];
    return height < 100 ? 100 : height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    Homework *homework = self.homeworks[indexPath.row];
    CreateHomeworkViewController *createHomeworkVC = [[CreateHomeworkViewController alloc] initWithNibName:@"CreateHomeworkViewController" bundle:nil];
    createHomeworkVC.homework = homework;
    [self.navigationController pushViewController:createHomeworkVC animated:YES];
}

@end

