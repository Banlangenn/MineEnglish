//
//  MIHomeworkTaskListViewController.m
//  Minnie
//
//  Created by songzhen on 2019/6/8.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "Result.h"
#import "ManagerServce.h"
#import "HomeworkTableViewCell.h"
#import "MIMoveHomeworkTaskView.h"
#import "MIScoreListViewController.h"
#import "HomeworkPreviewViewController.h"
#import "ClassAndStudentSelectorController.h"
#import "HomeWorkSendHistoryViewController.h"

#import <AVKit/AVKit.h>
#import "VICacheManager.h"
#import "NEPhotoBrowser.h"
#import "UIScrollView+Refresh.h"
#import "AudioPlayerViewController.h"
#import "VIResourceLoaderManager.h"
#import "MIHomeworkTaskListViewController.h"

@interface MIHomeworkTaskListViewController ()<
UITableViewDelegate,
UITableViewDataSource,
NEPhotoBrowserDelegate,
NEPhotoBrowserDataSource,
VIResourceLoaderManagerDelegate
>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomContraint;
@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *operatorBtn;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;

@property (nonatomic, assign) BOOL inEditMode;

@property (nonatomic, strong) NSMutableArray <Homework *> *homeworks;

@property (nonatomic, strong) NSMutableArray <NSNumber *> *selectedHomeworkIds;

@property (nonatomic, strong) BaseRequest *homeworksRequest;

@property (nonatomic, strong) NSString *nextUrl;

@property (nonatomic, strong) NEPhotoBrowser *photoBrowser;
@property (nonatomic, copy) NSString *currentSelectedImageUrl;
@property (nonatomic, strong) UIImageView *currentSelectedImageView;
@property (nonatomic, strong) VIResourceLoaderManager *resourceLoaderManager;

@property (nonatomic, assign) BOOL shouldReloadWhenAppeared;

@property (nonatomic, assign) NSInteger currFileIndex;


@end

@implementation MIHomeworkTaskListViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _homeworks = [NSMutableArray array];
    _selectedHomeworkIds = [NSMutableArray array];
    self.titleLabel.text = self.currentFileInfo.fileName;
    [self registerCellNibs];
    [self configureUI];
    self.footerView.hidden = !self.inEditMode;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldReloadDataWhenAppeared:)
                                                 name:kNotificationKeyOfAddHomework
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeworkDidSendSuccess) name:kNotificationKeyOfHomeworkSendSuccess object:nil];

    WeakifySelf;
    [self.tableView addPullToRefreshWithRefreshingBlock:^{
        
        [weakSelf requestHomeworks];
    }];
    [self.tableView headerBeginRefreshing];
}
- (void)configureUI{
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundColor = [UIColor bgColor];
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 12.f)];
    self.tableView.tableFooterView = footerView;
}

- (IBAction)backAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)operationAction:(id)sender {
    
    self.inEditMode = !self.inEditMode;
    self.operatorBtn.selected = self.inEditMode;
    if (self.inEditMode) {
        
        [self.selectedHomeworkIds removeAllObjects];
        self.footerView.hidden = NO;
        self.bottomContraint.constant = 50;
    } else {
        self.footerView.hidden = YES;
        self.bottomContraint.constant = 0;
    }
    [self.tableView reloadData];
}

- (IBAction)sendAction:(id)sender {
    
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
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}
- (IBAction)deleteAction:(id)sender {
    
    MIMoveHomeworkTaskView *view = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIMoveHomeworkTaskView class]) owner:nil options:nil].lastObject;
    view.frame = [UIScreen mainScreen].bounds;
    view.isMultiple = NO;
    WeakifySelf;
    view.callback = ^{
        
        [weakSelf.homeworks removeAllObjects];
        [weakSelf.selectedHomeworkIds removeAllObjects];
        weakSelf.nextUrl = nil;
        
        [weakSelf operationAction:nil];
        [weakSelf requestHomeworks];
    };
    view.homeworkIds = self.selectedHomeworkIds;
    view.currentFileInfo = self.currentFileInfo;
    [[UIApplication sharedApplication].keyWindow addSubview:view];
}

- (void)registerCellNibs {
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([HomeworkTableViewCell class]) bundle:nil] forCellReuseIdentifier:HomeworkTableViewCellId];
}

#pragma mark - Private Methods
- (void)shouldReloadDataWhenAppeared:(NSNotification *)notification {
    self.shouldReloadWhenAppeared = YES;
}

- (void)homeworkDidSendSuccess{
    self.inEditMode = YES;
    [self operationAction:nil];
}

#pragma mark - 请求作业列表
- (void)requestHomeworks {
    
    if (self.homeworksRequest != nil) {
        return;
    }
    self.footerView.hidden = YES;
    WeakifySelf;
    self.homeworksRequest = [ManagerServce requesthomeworksByFileWithFileId:self.currentFileInfo.fileId
                                                                   sortType:1
                                                                    nextUrl:nil callback:^(Result *result, NSError *error) {
        
        StrongifySelf;
        [weakSelf.view hideAllStateView];
        [strongSelf handleRequestResult:result error:error isLoad:NO];
    }];
}
- (void)loadMoreHomeworks {
    if (self.homeworksRequest != nil) {
        return;
    }
    WeakifySelf;
    self.homeworksRequest = [ManagerServce requesthomeworksByFileWithFileId:self.currentFileInfo.fileId
                                                                   sortType:1
                                                                    nextUrl:self.nextUrl
                                                                   callback:^(Result *result, NSError *error) {
        
        StrongifySelf;
        [weakSelf.view hideAllStateView];
        [strongSelf handleRequestResult:result error:error isLoad:YES];
    }];
}

- (void)handleRequestResult:(Result *)result error:(NSError *)error isLoad:(BOOL)isLoadMore{
    
    self.homeworksRequest = nil;
    NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
    NSString *nextUrl = dictionary[@"next"];
    NSArray *homeworks = dictionary[@"list"];
    
    if (isLoadMore) {
        [self.tableView footerEndRefreshing];
        if (error != nil) {
            
            if (self.homeworks == 0) {
                WeakifySelf;
                [self.view showFailureViewWithRetryCallback:^{
                    [weakSelf requestHomeworks];
                }];
            }
            return;
        }
        [self.homeworks addObjectsFromArray:homeworks];
        if (self.homeworks.count == 0) {
            WeakifySelf;
            self.operatorBtn.enabled = NO;
            [self.view showEmptyViewWithImage:nil title:@"作业列表为空"
                                centerYOffset:0
                                    linkTitle:nil
                            linkClickCallback:nil retryCallback:^{
                
                                [weakSelf requestHomeworks];
                            }];
        } else {
            
            self.operatorBtn.enabled = YES;
            self.tableView.hidden = NO;
            self.footerView.hidden = !self.inEditMode;
        }
        if (nextUrl.length == 0) {
            [self.tableView removeFooter];
        }
        [self.tableView reloadData];
    } else {
        // 停止加载
        [self.tableView headerEndRefreshing];
        if (error != nil) {
            if (homeworks.count > 0) {
                [TIP showText:@"加载失败" inView:self.view];
            } else {
                WeakifySelf;
                [self.view showFailureViewWithRetryCallback:^{
                    [weakSelf requestHomeworks];
                }];
            }
            return;
        }
        
        if (homeworks.count > 0) {
            
            [self.homeworks removeAllObjects];
            [self.homeworks addObjectsFromArray:homeworks];
            
            if (nextUrl.length > 0) {
                WeakifySelf;
                [self.tableView addInfiniteScrollingWithRefreshingBlock:^{
                    [weakSelf loadMoreHomeworks];
                }];
            } else {
                [self.tableView removeFooter];
            }
            
            self.operatorBtn.enabled = YES;
            self.tableView.hidden = NO;
            self.footerView.hidden = !self.inEditMode;
            [self.tableView reloadData];
        } else {
            WeakifySelf;
            self.operatorBtn.enabled = NO;
            [self.view showEmptyViewWithImage:nil title:@"作业列表为空"
                                centerYOffset:0
                                    linkTitle:nil
                            linkClickCallback:nil retryCallback:^{
                                
                                [weakSelf requestHomeworks];
                            }];
        }
    }
    self.nextUrl = nextUrl;
}

#pragma mark - 显示图片 视频 音频
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
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
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
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
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
        weakSelf.deleteBtn.enabled = weakSelf.selectedHomeworkIds.count>0;
        weakSelf.sendBtn.enabled = weakSelf.selectedHomeworkIds.count>0;
    }];
    
    // 作业预览
    [cell setPreviewCallback:^{
        
        HomeworkPreviewViewController *vc = [[HomeworkPreviewViewController alloc] init];
        vc.homework = homework;
        [weakSelf.navigationController pushViewController:vc animated:YES];
    }];
    
    // 点击空白处 -> 得分列表
    [cell setBlankCallback:^{
        
        MIScoreListViewController *scoreListVC = [[MIScoreListViewController alloc] initWithNibName:NSStringFromClass([MIScoreListViewController class]) bundle:nil];
        WeakifySelf;
        scoreListVC.editTaskCallBack = ^{
            
            [weakSelf requestHomeworks];
        };
        scoreListVC.homework = homework;
        scoreListVC.currentFileInfo = self.currentFileInfo;
        scoreListVC.teacherSider = YES;
        [self.navigationController pushViewController:scoreListVC animated:YES];
    }];
    [cell setSendCallback:^{
        
        ClassAndStudentSelectorController *vc = [[ClassAndStudentSelectorController alloc] init];
        [vc setHomeworks:@[homework]];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [weakSelf.navigationController presentViewController:nav animated:YES completion:nil];
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
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Homework *homework = self.homeworks[indexPath.row];
    CGFloat height = [HomeworkTableViewCell cellHeightWithHomework:homework];
    return height < 100 ? 100 : height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    Homework *homework = self.homeworks[indexPath.row];
    MIScoreListViewController *scoreListVC = [[MIScoreListViewController alloc] initWithNibName:NSStringFromClass([MIScoreListViewController class]) bundle:nil];
    WeakifySelf;
    scoreListVC.editTaskCallBack = ^{
        [weakSelf requestHomeworks];
    };
    scoreListVC.homework = homework;
    scoreListVC.teacherSider = YES;
    scoreListVC.currentFileInfo = self.currentFileInfo;
    [self.navigationController pushViewController:scoreListVC animated:YES];
}


- (void)setCurrentFileInfo:(FileInfo *)currentFileInfo{
    _currentFileInfo = currentFileInfo;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.homeworksRequest clearCompletionBlock];
    [self.homeworksRequest stop];
    self.homeworksRequest = nil;
    
    NSLog(@"%s", __func__);
}

@end
