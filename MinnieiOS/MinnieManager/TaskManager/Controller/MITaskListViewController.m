//
//  MITaskListViewController.m
//  MinnieManager
//
//  Created by songzhen on 2019/5/28.
//  Copyright © 2019 minnieedu. All rights reserved.
//  任务管理 - 任务列表

#import "ManagerServce.h"
#import "MITaskEmptyView.h"
#import "FilterAlertView.h"
#import "HomeworkTableViewCell.h"
#import "MIMoveHomeworkTaskView.h"
#import "MITaskListViewController.h"
#import "MIScoreListViewController.h"
#import "MICreateTaskViewController.h"
#import "HomeworkPreviewViewController.h"


#import <AVKit/AVKit.h>
#import "TeacherService.h"
#import "UIScrollView+Refresh.h"
//#import "VICacheManager.h"
#import "NEPhotoBrowser.h"
//#import "AudioPlayerViewController.h"
//#import "VIResourceLoaderManager.h"
#import "SelectTeacherView.h"
#import "HomeworkConfirmView.h"
#import "ClassAndStudentSelectView.h"
#import "MIPlayerViewController.h"

@interface MITaskListViewController ()<
UITableViewDelegate,
UITableViewDataSource,
NEPhotoBrowserDelegate,
NEPhotoBrowserDataSource
//VIResourceLoaderManagerDelegate
>

@property (nonatomic, assign) BOOL inEditMode;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIButton *createBtn;
@property (weak, nonatomic) IBOutlet UILabel *folderLabel;
@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UIButton *operatorBtn;

@property (weak, nonatomic) IBOutlet UIButton *switchTypeBtn;

@property (weak, nonatomic) IBOutlet UILabel *selectCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *footerHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *rightLineView;

@property (nonatomic, strong)  MITaskEmptyView *emptyView;

@property (nonatomic, strong) NSMutableArray <Homework *> *homeworks;

@property (nonatomic, strong) NSMutableArray <NSNumber *> *selectedHomeworkIds;

@property (nonatomic, strong) BaseRequest *homeworksRequest;

@property (nonatomic, strong) NSString *nextUrl;

@property (nonatomic, strong) NEPhotoBrowser *photoBrowser;
@property (nonatomic, copy) NSString *currentSelectedImageUrl;
@property (nonatomic, strong) UIImageView *currentSelectedImageView;
//@property (nonatomic, strong) VIResourceLoaderManager *resourceLoaderManager;

@property (nonatomic, assign) BOOL shouldReloadWhenAppeared;

@property (nonatomic, strong) FileInfo *currentFileInfo;

@property (nonatomic, assign) NSInteger currFileIndex;


@property (nonatomic, assign) BOOL viewAnimated;


@property (nonatomic, assign) NSInteger currentSelectedIndex;

// 当前任务列表类型 0按名称 1按时间
@property (nonatomic, assign) NSInteger taskListtype;


@end

@implementation MITaskListViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.taskListtype = 0;
    self.currentSelectedIndex = -1;
    _homeworks = [NSMutableArray array];
    _currentFileInfo = [[FileInfo alloc] init];
    _selectedHomeworkIds = [NSMutableArray array];
    [self registerCellNibs];
    [self configureUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldReloadDataWhenAppeared:)
                                                 name:kNotificationKeyOfAddHomework
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeworkDidSendSuccess) name:kNotificationKeyOfHomeworkSendSuccess object:nil];
    
    // 教师批改作业
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadWhenHomeworkCorrected:)
                                                 name:kNotificationKeyOfCorrectHomework
                                               object:nil];
}

- (void)configureUI{
    
    self.view.backgroundColor = [UIColor unSelectedColor];
    self.tableView.backgroundColor = [UIColor unSelectedColor];
    self.tableView.separatorColor = [UIColor clearColor];
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 12.f)];
    self.tableView.tableFooterView = footerView;
    self.selectCountLabel.layer.masksToBounds = YES;
    self.selectCountLabel.layer.cornerRadius = 10.5;
}
- (void)registerCellNibs {
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([HomeworkTableViewCell class]) bundle:nil] forCellReuseIdentifier:HomeworkTableViewCellId];
}
- (IBAction)switchTypeAction:(id)sender {

    WeakifySelf;
    [FilterAlertView showInView:self.view
                   atFliterType:self.taskListtype
                 forFliterArray:@[@"按名称",@"按时间"]
                 withAtionBlock:^(NSInteger index) {
                     StrongifySelf;
                     if (strongSelf.pushVCCallBack) {
                         strongSelf.pushVCCallBack(nil);
                     }
                     strongSelf.taskListtype = index;
                     [strongSelf requestHomeworks];
                 }];
}

#pragma mark - actions  新建  发送记录  操作
- (IBAction)addTaskAction:(id)sender {
  
    [self showSelectedTask];
}

- (IBAction)operationAction:(id)sender {
    
    self.inEditMode = !self.inEditMode;
    self.operatorBtn.selected = self.inEditMode;
    if (self.inEditMode) {
        
        [self.selectedHomeworkIds removeAllObjects];
        self.switchTypeBtn.hidden = YES;
        self.createBtn.hidden = YES;
        self.folderLabel.hidden = YES;
        self.footerView.hidden = NO;
        self.footerHeightConstraint.constant = 50;
    } else {
        
        self.switchTypeBtn.hidden = NO;
        self.createBtn.hidden = NO;
        self.folderLabel.hidden = NO;
        self.footerView.hidden = YES;
        self.footerHeightConstraint.constant = 0;
    }
    [self.tableView reloadData];
}

#pragma mark - 发送作业 && 移动作业
- (IBAction)sendHomeworkAction:(id)sender {
    
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
 
    ClassAndStudentSelectView *selectView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([ClassAndStudentSelectView class]) owner:nil options:nil].lastObject;
    WeakifySelf;
    selectView.cancelBack = ^{
        [weakSelf cancelEditMode];
    };
    selectView.selectBack = ^(NSArray<Clazz *> * _Nullable classes, NSArray<User *> * _Nullable students) {
        [weakSelf classAndStudentSelectViewClasses:classes students:students homeworks:homeworks];
    };
    [selectView showSelectView];
}

- (void)classAndStudentSelectViewClasses:(NSArray<Clazz *> *)classes students:(NSArray<User *> *)students homeworks:(NSArray *)homeworks{
   
    WeakifySelf;
    [TeacherService requestTeachersWithCallback:^(Result *result, NSError *error) {
        
        if (error != nil) {
            
            [weakSelf cancelEditMode];
            [HUD showErrorWithMessage:@"教师获取失败"];
            return;
        }
        
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *teachers = (NSArray *)(dict[@"list"]);
        [SelectTeacherView showInSuperView:[UIApplication sharedApplication].keyWindow
                                  teachers:teachers
                                  callback:^(Teacher *teacher, NSDate *date) {
                                      
                                      [SelectTeacherView hideAnimated:NO];
                                      
                                      UIView *confirmViewBg = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
                                      confirmViewBg.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
                                      [[UIApplication sharedApplication].keyWindow addSubview:confirmViewBg];
                                      
                                      HomeworkConfirmView *confirmView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([HomeworkConfirmView class]) owner:nil options:nil].lastObject;
                                      [confirmView setupConfirmViewHomeworks:homeworks
                                                                     classes:classes
                                                                    students:students
                                                                     teacher:teacher];
                                      [confirmViewBg addSubview:confirmView];
                                      [confirmView mas_makeConstraints:^(MASConstraintMaker *make) {
                                         
                                          make.centerX.equalTo(confirmViewBg.mas_centerX);
                                          make.centerY.equalTo(confirmViewBg.mas_centerY);
                                          make.width.equalTo(@375);
                                          make.height.mas_equalTo(ScreenHeight - 102);
                                      }];
                                      confirmView.cancelCallBack = ^{
                                          if (confirmViewBg.superview) {
                                              [confirmViewBg removeFromSuperview];
                                          }
                                          [weakSelf cancelEditMode];
                                      };
                                      confirmView.successCallBack = ^{
                                         
                                          if (confirmViewBg.superview) {
                                              [confirmViewBg removeFromSuperview];
                                          }
                                          [weakSelf cancelEditMode];
                                      };
                                  } cancelback:^{
                                      [weakSelf cancelEditMode];
                                  }];
    }];
}

- (void)showConfirmViewClasses:(NSArray<Clazz *> *)classes students:(NSArray<User *> *)students homeworks:(NSArray *)homeworks{
    
    UIView *confirmViewBg = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    confirmViewBg.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [[UIApplication sharedApplication].keyWindow addSubview:confirmViewBg];
    
}

// 新需求改为移动任务
- (IBAction)deleteHomeworkAction:(id)sender{
    
    MIMoveHomeworkTaskView *view = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIMoveHomeworkTaskView class]) owner:nil options:nil].lastObject;
    view.frame = [UIScreen mainScreen].bounds;
    view.isMultiple = YES;
    WeakifySelf;
    view.callback = ^{
       
        [weakSelf.homeworks removeAllObjects];
        [weakSelf.selectedHomeworkIds removeAllObjects];
        weakSelf.nextUrl = nil;
        [weakSelf cancelEditMode];
        [weakSelf requestHomeworks];
    };
    view.cancelCallback = ^{
        [weakSelf cancelEditMode];
    };
    view.homeworkIds = self.selectedHomeworkIds;
    view.currentFileInfo = self.currentFileInfo;
    [[UIApplication sharedApplication].keyWindow addSubview:view];
}

- (void)cancelEditMode{
    // 手动取消编辑模式
    self.inEditMode = YES;
    [self operationAction:nil];
}

#pragma mark - Private Methods
- (void)shouldReloadDataWhenAppeared:(NSNotification *)notification {
    self.shouldReloadWhenAppeared = YES;
}

- (void)homeworkDidSendSuccess{

    [self cancelEditMode];
}

- (void)reloadWhenHomeworkCorrected:(NSNotification *)notification {
    
    self.currentSelectedIndex = -1;
    [self.tableView reloadData];
}

- (void)resetSelectIndex{
    
    self.currentSelectedIndex = -1;
    [self.tableView reloadData];
}

#pragma mark - 请求作业列表
- (void)requestHomeworks {
    
    if (self.homeworksRequest != nil) {
        return;
    }
    WeakifySelf;
    if (self.emptyView.superview) {
        [self.emptyView removeFromSuperview];
    }
    if (self.homeworks.count == 0) {
        self.view.backgroundColor = [UIColor unSelectedColor];
        [self.view showLoadingView];
    }
    self.homeworksRequest = [ManagerServce requesthomeworksByFileWithFileId:self.currentFileInfo.fileId
                                                                   sortType:self.taskListtype+1
                                                                    nextUrl:nil
                                                                   callback:^(Result *result, NSError *error) {

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
    if (self.emptyView.superview) {
        [self.emptyView removeFromSuperview];
    }
    self.homeworksRequest = [ManagerServce requesthomeworksByFileWithFileId:self.currentFileInfo.fileId
                                                                   sortType:self.taskListtype + 1
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
  
            [self showEmptyViewWithIsFolder:NO folderIndex:self.currFileIndex];
        } else {
            [self showTaskList:YES];
        }
        if (nextUrl.length == 0) {
            [self.tableView removeFooter];
        }
        [self.tableView reloadData];
    } else {
        // 停止加载
        [self.tableView headerEndRefreshing];
        self.tableView.hidden = homeworks.count==0;
        
        if (error != nil) {
            
            if (self.homeworks == 0) {
                WeakifySelf;
                [self.view showFailureViewWithRetryCallback:^{
                    [weakSelf requestHomeworks];
                }];
            }
            return;
        }
        
        if (homeworks.count > 0) {
            
            [self showTaskList:YES];
            [self.view hideAllStateView];
            [self.homeworks removeAllObjects];
            [self.homeworks addObjectsFromArray:homeworks];
            [self.tableView reloadData];
            
            if (nextUrl.length > 0) {
                WeakifySelf;
                [self.tableView addInfiniteScrollingWithRefreshingBlock:^{
                    [weakSelf loadMoreHomeworks];
                }];
            } else {
                [self.tableView removeFooter];
            }
        } else {
            
            [self showEmptyViewWithIsFolder:NO folderIndex:self.currFileIndex];
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
//
//    AVAudioSession *session =[AVAudioSession sharedInstance];
//    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
//    NSInteger playMode = [[Application sharedInstance] playMode];
//
//    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc]init];
//    AVPlayer *player;
//    if (playMode == 1)// 在线播放
//    {
//        [VICacheManager cleanCacheForURL:[NSURL URLWithString:videoUrl] error:nil];
//        player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:videoUrl]];
//    }
//    else
//    {
//        VIResourceLoaderManager *resourceLoaderManager = [VIResourceLoaderManager new];
//        resourceLoaderManager.delegate = self;
//        self.resourceLoaderManager = resourceLoaderManager;
//        AVPlayerItem *playerItem = [resourceLoaderManager playerItemWithURL:[NSURL URLWithString:videoUrl]];
//        player = [AVPlayer playerWithPlayerItem:playerItem];
//    }
//    playerViewController.player = player;
//    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:playerViewController animated:YES completion:nil];
//    playerViewController.view.frame = self.view.frame;
//    [playerViewController.player play];
    
    MIPlayerViewController *playerViewController = [[MIPlayerViewController alloc]init];
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [playerViewController playVideoWithUrl:videoUrl];
}

- (void)showAudioWithURL:(NSString *)url withCoverURL:(NSString *)coverUrl
{
//    AVAudioSession *session =[AVAudioSession sharedInstance];
//    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
//    AudioPlayerViewController *playerViewController = [[AudioPlayerViewController alloc]init];
//    NSInteger playMode = [[Application sharedInstance] playMode];
//    AVPlayer *player;
//    if (playMode == 1)// 在线播放
//    {
//        [VICacheManager cleanCacheForURL:[NSURL URLWithString:url] error:nil];
//        player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:url]];
//    }
//    else
//    {
//        VIResourceLoaderManager *resourceLoaderManager = [VIResourceLoaderManager new];
//        resourceLoaderManager.delegate = self;
//        self.resourceLoaderManager = resourceLoaderManager;
//        AVPlayerItem *playerItem = [resourceLoaderManager playerItemWithURL:[NSURL URLWithString:url]];
//        player = [AVPlayer playerWithPlayerItem:playerItem];
//    }
//
//
//    playerViewController.player = player;
//    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:playerViewController animated:YES completion:nil];
//    playerViewController.view.frame = self.view.frame;
//    [playerViewController.player play];
    
    MIPlayerViewController *playerViewController = [[MIPlayerViewController alloc]init];
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [playerViewController playAudioWithUrl:url coverUrl:coverUrl];
}


//#pragma mark - VIResourceLoaderManagerDelegate
//- (void)resourceLoaderManagerLoadURL:(NSURL *)url didFailWithError:(NSError *)error
//{
//    [VICacheManager cleanCacheForURL:url error:nil];
//    // 适配ipad版本
//    UIAlertControllerStyle alertStyle;
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        alertStyle = UIAlertControllerStyleActionSheet;
//    } else {
//        alertStyle = UIAlertControllerStyleAlert;
//    }
//    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil
//                                                                     message:@"播放失败"
//                                                              preferredStyle:alertStyle];
//    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定"
//                                                           style:UIAlertActionStyleCancel
//                                                         handler:^(UIAlertAction * _Nonnull action) {
//                                                             [self.tabBarController dismissViewControllerAnimated:YES completion:^{
//
//                                                             }];
//                                                         }];
//
//    [alertVC addAction:cancelAction];
//
//    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:alertVC
//                       animated:YES
//                     completion:nil];
//
//}

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
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    Homework *homework = self.homeworks[indexPath.row];
    
    [cell setupWithHomework:homework];
    if (self.inEditMode) {
        [cell selectedState:NO];
    } else {
        [cell selectedState: (indexPath.row == self.currentSelectedIndex) ? YES : NO];
    }
    [cell updateWithEditMode:self.inEditMode selected:[self.selectedHomeworkIds containsObject:@(homework.homeworkId)]];
    
    WeakifySelf;
    [cell setSelectCallback:^{
        if ([weakSelf.selectedHomeworkIds containsObject:@(homework.homeworkId)]) {
            [weakSelf.selectedHomeworkIds removeObject:@(homework.homeworkId)];
        } else {
            [weakSelf.selectedHomeworkIds addObject:@(homework.homeworkId)];
        }
        weakSelf.selectCountLabel.text = [NSString stringWithFormat:@"%zd", weakSelf.selectedHomeworkIds.count];
        weakSelf.deleteBtn.enabled = weakSelf.selectedHomeworkIds.count>0;
        weakSelf.sendBtn.enabled = weakSelf.selectedHomeworkIds.count>0;
    }];
    
    // 作业预览
    [cell setPreviewCallback:^{
        
        HomeworkPreviewViewController *vc = [[HomeworkPreviewViewController alloc] init];
        vc.homework = homework;
        if (weakSelf.pushVCCallBack) {
            weakSelf.pushVCCallBack(vc);
        }
    }];
    
    // 点击空白处 -> 得分列表
    [cell setBlankCallback:^{
       
        weakSelf.currentSelectedIndex = indexPath.row;
        [tableView reloadData];
        MIScoreListViewController *scoreListVC = [[MIScoreListViewController alloc] initWithNibName:NSStringFromClass([MIScoreListViewController class]) bundle:nil];
        scoreListVC.editTaskCallBack = ^{
         
            [weakSelf requestHomeworks];
            if (weakSelf.createTaskCallBack) {
                weakSelf.createTaskCallBack(nil, 1);
            }
        };
        scoreListVC.cancelCallBack = ^{
            weakSelf.currentSelectedIndex = -1;
            [weakSelf.tableView reloadData];
        };
        scoreListVC.homework = homework;
        scoreListVC.currentFileInfo = weakSelf.currentFileInfo;
        if (weakSelf.pushVCCallBack) {
            weakSelf.pushVCCallBack(scoreListVC);
        }
    }];
    [cell setSendCallback:^{

        ClassAndStudentSelectView *selectView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([ClassAndStudentSelectView class]) owner:nil options:nil].lastObject;
        WeakifySelf;
        selectView.cancelBack = ^{
            [weakSelf cancelEditMode];
        };
        selectView.selectBack = ^(NSArray<Clazz *> * _Nullable classes, NSArray<User *> * _Nullable students) {
          
            [weakSelf classAndStudentSelectViewClasses:classes students:students homeworks:@[homework]];
        };
        [selectView showSelectView];
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
  
//    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (self.currentSelectedIndex == indexPath.row) {
        return;
    }
    self.currentSelectedIndex = indexPath.row;
    [tableView reloadData];
    
    Homework *homework = self.homeworks[indexPath.row];
    MIScoreListViewController *scoreListVC = [[MIScoreListViewController alloc] initWithNibName:NSStringFromClass([MIScoreListViewController class]) bundle:nil];
    WeakifySelf;
    scoreListVC.editTaskCallBack = ^{
        [weakSelf requestHomeworks];
        if (weakSelf.createTaskCallBack) {
            weakSelf.createTaskCallBack(nil, 1);
        }
    };
    scoreListVC.cancelCallBack = ^{
        weakSelf.currentSelectedIndex = -1;
        [weakSelf.tableView reloadData];
    };
    scoreListVC.homework = homework;
    scoreListVC.currentFileInfo = self.currentFileInfo;
    if (self.pushVCCallBack) {
        self.pushVCCallBack(scoreListVC);
    }
}

// 请求作业列表
- (void)showTaskListWithFoldInfo:(FileInfo * _Nullable)fileInfo folderIndex:(NSInteger)folder{
  
    self.currFileIndex = folder;
    self.currentFileInfo = fileInfo;
    self.folderLabel.text = self.currentFileInfo.fileName;
    if (fileInfo) {
        // 显示任务列表
        self.viewAnimated = YES;
        [self cancelEditMode];
        self.taskListtype = 0;
        [self requestHomeworks];
    } else { // 显示为空
        [self showTaskList:NO];
    }
}

#pragma mark - 显示空白内容
- (void)showTaskList:(BOOL)isShow{
    
    self.currentSelectedIndex = -1;
    if (isShow) {

        self.rightLineView.hidden = NO;
        self.tableView.hidden = NO;
        self.headerView.hidden = NO;
        if (self.inEditMode) {
            self.footerView.hidden = NO;
            self.footerHeightConstraint.constant = 50;
        } else {
            self.footerView.hidden = YES;
            self.footerHeightConstraint.constant = 0;
        }
        if (self.emptyView.superview) {
            [self.emptyView removeFromSuperview];
        }
        self.view.backgroundColor = [UIColor unSelectedColor];
        if (self.viewAnimated) {
            
            [self showAnimation];
            self.viewAnimated = NO;
        }
    } else {
        
        [self cancelEditMode];
        [self.view hideAllStateView];
        self.rightLineView.hidden = YES;
        self.tableView.hidden = YES;
        self.headerView.hidden = YES;
        self.footerView.hidden = YES;
        self.footerHeightConstraint.constant = 0;
        if (self.emptyView.superview) {
            [self.emptyView removeFromSuperview];
        }
        self.view.backgroundColor = [UIColor emptyBgColor];
    }
}

- (void)showAnimation{
  
    self.view.frame = CGRectMake(kColumnThreeWidth, 0, kColumnThreeWidth, ScreenHeight);
    WeakifySelf;
    [UIView animateWithDuration:0.2 animations:^{
        
        weakSelf.view.frame = CGRectMake(0, 0, kColumnThreeWidth, ScreenHeight);
    }];
}

#pragma mark - 显示添加文件or文件夹 YES 添加文件夹 NO 添加文件
- (void)showEmptyViewWithIsFolder:(BOOL)isAddFolder folderIndex:(NSInteger)index{
    
    if (self.emptyView == nil) {
        
        self.emptyView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MITaskEmptyView class]) owner:nil options:nil] lastObject];
    }
    self.currentSelectedIndex = -1;
    self.tableView.hidden = YES;
    self.rightLineView.hidden = NO;
    [self.view addSubview:self.emptyView];
    WeakifySelf;
    self.emptyView.callBack = ^(BOOL isAddFolder) {
        
        __block NSInteger currIndex = index;
        if (isAddFolder) { // 添加二级文件夹
            
            if (weakSelf.addFolderCallBack) {
                
                weakSelf.addFolderCallBack(currIndex);
            }
        } else { // 新建任务
            [weakSelf showSelectedTask];
        }
    };
    self.emptyView.frame = CGRectMake(0, 0, kColumnThreeWidth - 1, ScreenHeight);
    self.emptyView.isAddFolder = isAddFolder;

    
    self.view.backgroundColor = [UIColor unSelectedColor];
    self.view.frame = CGRectMake(0, 0, kColumnThreeWidth, ScreenHeight);
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
    UIAlertAction *action7 = [UIAlertAction actionWithTitle:@"取消"
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        
                                                    }];
    
    [alertVC addAction:action1];
    [alertVC addAction:action2];
    [alertVC addAction:action3];
    [alertVC addAction:action4];
    [alertVC addAction:action6];
    [alertVC addAction:action7];

    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertVC
                       animated:YES
                     completion:nil];
}

- (void)goToCreateTaskWithType:(MIHomeworkTaskType)type{
    
    MICreateTaskViewController *createVC = [[MICreateTaskViewController alloc] initWithNibName:NSStringFromClass([MICreateTaskViewController class]) bundle:nil];
    [createVC setupCreateHomework:nil currentFileInfo:self.currentFileInfo taskType:type];

    WeakifySelf;
    UIView *bgView = [Utils viewOfVCAddToWindowWithVC:createVC width:ScreenWidth - kRootModularWidth];
    createVC.callBack = ^(BOOL isDelete) {
     
        [weakSelf requestHomeworks];
        if (weakSelf.createTaskCallBack) {
            weakSelf.createTaskCallBack(nil, 1);
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
}

- (void)dealloc {
  
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.homeworksRequest clearCompletionBlock];
    [self.homeworksRequest stop];
    self.homeworksRequest = nil;
}

@end
