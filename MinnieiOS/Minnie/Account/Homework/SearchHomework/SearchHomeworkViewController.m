//
//  SearchHomeworkViewController.m
//  X5Teacher
//
//  Created by yebw on 2018/2/4.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "ClassAndStudentSelectView.h"
#import "SearchHomeworkViewController.h"
#import "HomeworkService.h"
#import "TagService.h"
#import "UIScrollView+Refresh.h"
#import "TagCollectionViewCell.h"
#import "HomeworkTableViewCell.h"
#import "MIMoveHomeworkTaskView.h"

#import "NEPhotoBrowser.h"
//#import "VICacheManager.h"
#import "TeacherService.h"
#import "SelectTeacherView.h"
#import "HomeworkConfirmView.h"
#import "EqualSpaceFlowLayout.h"
//#import "VIResourceLoaderManager.h"
#import "MIPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
//#import "AudioPlayerViewController.h"
#import "MIScoreListViewController.h"
#import "HomeworkPreviewViewController.h"
#import "ClassAndStudentSelectorController.h"

@interface SearchHomeworkViewController ()<
UITextFieldDelegate,
UITableViewDataSource,
UITableViewDelegate,
NEPhotoBrowserDelegate,
NEPhotoBrowserDataSource,
UICollectionViewDelegate,
UICollectionViewDataSource,
EqualSpaceFlowLayoutDelegate
//VIResourceLoaderManagerDelegate
>

@property (nonatomic, weak) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet UIImageView *searchImageV;

@property (nonatomic, weak) IBOutlet UIView *tagsView;
@property (nonatomic, weak) IBOutlet UIView *homeworksView;
@property (nonatomic, weak) IBOutlet UITableView *homeworksTableView;

@property (weak, nonatomic) IBOutlet UIButton *operateBtn;
@property (weak, nonatomic) IBOutlet UIButton *removeBtn;

@property (weak, nonatomic) IBOutlet UIButton *sendBtn;

@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;

@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *footerViewHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cancelTrailingConstraint;

@property (nonatomic, strong) UICollectionView *tagsCollectionView;

@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSMutableArray<NSString *> * selectTags;
@property (nonatomic, strong) NSMutableArray *homeworks;
@property (nonatomic, copy) NSString *nextUrl;

@property (weak, nonatomic) IBOutlet UILabel *noresultLabel;
@property (nonatomic, strong) BaseRequest *searchRequest;
@property (nonatomic, assign) BOOL shouldReloadWhenAppeared;

@property (nonatomic, strong) NSMutableArray * keywords;

@property (nonatomic, assign) NSInteger currentSelectedIndex;


@property (nonatomic, strong) NEPhotoBrowser *photoBrowser;
@property (nonatomic, copy) NSString *currentSelectedImageUrl;
@property (nonatomic, strong) UIImageView *currentSelectedImageView;
//@property (nonatomic, strong) VIResourceLoaderManager *resourceLoaderManager;

// 操作模式
@property (nonatomic, assign) BOOL inEditMode;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *selectedHomeworkIds;

@end

@implementation SearchHomeworkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentSelectedIndex = -1;
    self.selectTags = [[NSMutableArray alloc] init];
    self.keywords = [[NSMutableArray alloc] init];
    self.homeworks = [NSMutableArray array];
    self.selectedHomeworkIds = [NSMutableArray array];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldReloadDataWhenAppeared:)
                                                 name:kNotificationKeyOfAddHomework
                                               object:nil];
    
    self.homeworksTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self registerCellNibs];
    [self requestTags];
    
#if MANAGERSIDE
    UIView *rightLineView = [[UIView alloc] initWithFrame:CGRectMake(kColumnThreeWidth - 1, 0, 0.5, ScreenHeight)];
    rightLineView.backgroundColor = [UIColor separatorLineColor];
    [self.view addSubview:rightLineView];
#endif
}


- (void)shouldReloadDataWhenAppeared:(NSNotification *)notification {
    self.shouldReloadWhenAppeared = YES;
}

- (void)dealloc {
    [self.searchRequest clearCompletionBlock];
    [self.searchRequest stop];
    self.searchRequest = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.shouldReloadWhenAppeared) {
        self.shouldReloadWhenAppeared = NO;
        
        [self.homeworks removeAllObjects];
        self.nextUrl = nil;
        
        [self.searchRequest stop];
        self.searchRequest = nil;
        
        [self searchWithKeyword];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    [self.searchTextField becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}

- (IBAction)cancelButtonPressed:(id)sender {
    if (self.popDetailCallBack) {
        self.popDetailCallBack();
    }
    [self.navigationController popViewControllerAnimated:NO];
}
#pragma mark - 操作 发送 移动
- (IBAction)operateButtonPressed:(id)sender {
    
    
    self.inEditMode = !self.inEditMode;
    self.operateBtn.selected = self.inEditMode;
    if (self.inEditMode) { // 操作模式
        self.operateBtn.selected = YES;
        self.searchTextField.hidden = YES;
        self.cancelBtn.hidden = YES;
        self.searchImageV.hidden = YES;
        self.inEditMode = YES;
        self.footerView.hidden = NO;
        self.footerViewHeightConstraint.constant = 50;
        
        [self.selectedHomeworkIds removeAllObjects];
        
        _currentSelectedIndex = -1;
        if (self.popDetailCallBack) {
            self.popDetailCallBack();
        }
    } else {
        self.operateBtn.selected = NO;
        self.searchTextField.hidden = NO;
        self.cancelBtn.hidden = NO;
        self.searchImageV.hidden = NO;
        self.footerView.hidden = YES;
        self.footerViewHeightConstraint.constant = 0;
        self.inEditMode = NO;
    }
    
    [self.homeworksTableView reloadData];
}
- (void)cancelEditMode{
    // 手动取消编辑模式
    self.inEditMode = YES;
    [self operateButtonPressed:nil];
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

- (IBAction)removeButtonPressed:(id)sender {
    
    MIMoveHomeworkTaskView *view = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIMoveHomeworkTaskView class]) owner:nil options:nil].lastObject;
    view.frame = [UIScreen mainScreen].bounds;
    view.isMultiple = YES;
    WeakifySelf;
    view.callback = ^{
        
        [weakSelf.homeworks removeAllObjects];
        [weakSelf.selectedHomeworkIds removeAllObjects];
        weakSelf.nextUrl = nil;
        [weakSelf cancelEditMode];
        if (self.keywords.count > 0) {
            [self searchWithKeyword];
        }
    };
    view.cancelCallback = ^{
        [weakSelf cancelEditMode];
    };
    view.currentFileInfo = [FileInfo new];
    view.homeworkIds = self.selectedHomeworkIds;
    [[UIApplication sharedApplication].keyWindow addSubview:view];
}

#pragma mark - Private Methods

- (void)registerCellNibs {
    [self.homeworksTableView registerNib:[UINib nibWithNibName:NSStringFromClass([HomeworkTableViewCell class]) bundle:nil] forCellReuseIdentifier:HomeworkTableViewCellId];
    
    [self addContentView];
}
- (void)addContentView{
    
    CGFloat contentWidth = ScreenWidth;
#if MANAGERSIDE
    contentWidth = kColumnThreeWidth;
#endif
    
    EqualSpaceFlowLayout *flowLayout = [[EqualSpaceFlowLayout alloc] initWithCollectionViewWidth:contentWidth];
    flowLayout.delegate = self;
    flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, kNaviBarHeight + 70, 10);
    
    CGFloat height =  ScreenHeight - kNaviBarHeight - 60;
    self.tagsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 60, contentWidth,height) collectionViewLayout:flowLayout];
    self.tagsCollectionView.backgroundColor = [UIColor whiteColor];
    self.tagsCollectionView.delegate = self;
    self.tagsCollectionView.dataSource = self;
    self.tagsCollectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tagsView addSubview:self.tagsCollectionView];
    

    self.tagsCollectionView.contentSize = CGSizeMake(contentWidth, height);
    [self.tagsCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([TagCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:TagCollectionViewCellId];
}

- (void)requestTags {
    
    [TagService requestTagsWithCallback:^(Result *result, NSError *error) {
        if (error == nil) {
            self.tags = (NSArray *)(result.userInfo);
            [self.tagsCollectionView reloadData];
            
            if (self.searchTextField.text.length == 0) {
                self.homeworksView.hidden = YES;
                self.tagsView.hidden = NO;
                
                self.operateBtn.hidden = YES;
                self.cancelTrailingConstraint.constant = 0;
            } else {
                self.homeworksView.hidden = NO;
                self.tagsView.hidden = YES;
                
                self.operateBtn.hidden = NO;
                self.cancelTrailingConstraint.constant = 40;
            }
        }
    }];
}

- (void)textDidChange:(NSNotification *)notification {
    [self.searchRequest stop];
    
    if (self.searchTextField.text.length == 0) {
        self.tagsView.hidden = NO;
        self.homeworksView.hidden = YES;
        self.noresultLabel.hidden = YES;
        [self.selectTags removeAllObjects];
        [self.homeworks removeAllObjects];
        
        self.operateBtn.hidden = YES;
        self.cancelTrailingConstraint.constant = 0;
    } else {
        self.tagsView.hidden = YES;
        [self.homeworks removeAllObjects];
        self.nextUrl = nil;
        [self.homeworksTableView reloadData];
        self.homeworksView.hidden = NO;
        [self.homeworksView hideAllStateView];
        self.homeworksTableView.hidden = YES;
        
        self.operateBtn.hidden = NO;
        self.cancelTrailingConstraint.constant = 40;
    }
}

- (void)searchWithKeyword {
   
    self.tagsView.hidden = YES;
    self.homeworksView.hidden = NO;
    
    self.operateBtn.hidden = NO;
    self.cancelTrailingConstraint.constant = 40;

    [self.homeworksView showLoadingView];
    
    WeakifySelf;
    self.searchRequest = [HomeworkService searchHomeworkWithKeyword:self.keywords
                                                            fieldId:self.fieldId
                                                           callback:^(Result *result, NSError *error) {
                                                               [weakSelf handleSearchResult:result error:error];
                                                           }];
}

- (void)loadMoreHomeworks {
    if (self.searchRequest != nil) {
        return;
    }
    
    WeakifySelf;
    self.searchRequest = [HomeworkService searchHomeworkWithNextUrl:self.nextUrl
                                                        withKeyword:self.keywords
                                                            fieldId:self.fieldId
                                                           callback:^(Result *result, NSError *error) {
                                                               [weakSelf handleSearchResult:result error:error];
                                                           }];
}


- (void)handleSearchResult:(Result *)result error:(NSError *)error {
    self.searchRequest = nil;
    
    _currentSelectedIndex = -1;
    if (self.popDetailCallBack) {
        self.popDetailCallBack();
    }
    [self.homeworksView hideAllStateView];
    
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
                [self.homeworksView showFailureViewWithRetryCallback:^{
                    [weakSelf searchWithKeyword];
                }];
            }
            
            return;
        }
        
        if (homeworks.count > 0) {
            self.homeworksTableView.hidden = NO;
            self.noresultLabel.hidden = YES;
            [self.homeworks removeAllObjects];
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
            
            self.noresultLabel.hidden = NO;
            self.homeworksTableView.hidden = YES;
        }
    }
    
    self.nextUrl = nextUrl;
}


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [self.keywords removeAllObjects];
    [self.selectTags removeAllObjects];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField;
{
//    [self.keywords removeAllObjects];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    
    [self.keywords removeAllObjects];
    [self.searchRequest stop];
    
    [self.keywords addObjectsFromArray:[textField.text componentsSeparatedByString:@" "]];
    if (self.keywords.count > 0) {
        [self searchWithKeyword];
    }
    
    return NO;
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
//    [cell updateWithEditMode:NO selected:NO];
    
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
        weakSelf.sendBtn.enabled = weakSelf.selectedHomeworkIds.count>0;
        weakSelf.removeBtn.enabled = weakSelf.selectedHomeworkIds.count>0;
    }];
    
    [cell setSendCallback:^{
        
        [weakSelf sendHomeworkWithIndexPath:indexPath];
    }];
    
    // 作业预览
    [cell setPreviewCallback:^{
        
        [weakSelf previewHomeworkWithIndexPath:indexPath];
    }];
    
    // 点击空白处 -> 得分列表
    [cell setBlankCallback:^{
       
        [weakSelf toScoreListVCWithIndexPath:indexPath];
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
    
    if (indexPath.row == _currentSelectedIndex) {
        [cell selectedState:YES];
    } else {
        [cell selectedState:NO];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Homework *homework = self.homeworks[indexPath.row];
    return [HomeworkTableViewCell cellHeightWithHomework:homework];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [self toScoreListVCWithIndexPath:indexPath];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.tags.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TagCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:TagCollectionViewCellId
                                                                            forIndexPath:indexPath];
    NSString *tag = self.tags[indexPath.row];
    
    [cell setupWithTag:tag];
    [cell setChoice:NO];
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *tag = self.tags[indexPath.row];
    CGSize itemSize = [TagCollectionViewCell cellSizeWithTag:tag];
    // 标签长度大于屏幕
    CGFloat contentWidth = ScreenWidth;
#if MANAGERSIDE
    contentWidth = kColumnThreeWidth;
#endif
    if (itemSize.width > contentWidth -10) {
        
        itemSize.width = contentWidth - 10;
    }
    
    return itemSize;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    NSString *tag = self.tags[indexPath.item];
    
    if (![self.selectTags containsObject:tag])
    {
        [self.selectTags addObject:tag];
    }
    else
    {
        [self.selectTags removeObject:tag];
    }
    
    NSMutableString * searchString = [[NSMutableString alloc] init];
    for (int i = 0; i < self.selectTags.count; i++)
    {
        NSString * tagString = [self.selectTags objectAtIndex:i];
        [searchString appendString:tagString];
        if (i != self.selectTags.count - 1)
        {
            [searchString appendString:@" "];
        }
    }
    
    self.searchTextField.text = searchString;
    [self.searchTextField becomeFirstResponder];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{

    [self.searchTextField resignFirstResponder];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [self.searchTextField resignFirstResponder];
}

#pragma mark - VIResourceLoaderManagerDelegate
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


#pragma mark - 显示图片 视频 音频
- (void)showCurrentSelectedImage {
    
    self.photoBrowser = [[NEPhotoBrowser alloc] init];
    self.photoBrowser.delegate = self;
    self.photoBrowser.dataSource = self;
    self.photoBrowser.clickedImageView = self.currentSelectedImageView;
    [self.photoBrowser showInContext:self.navigationController];
}
- (void)showVideoWithUrl:(NSString *)videoUrl {
    
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
//    [playerViewController setOverlyViewCoverUrl:coverUrl];
    
    MIPlayerViewController *playerViewController = [[MIPlayerViewController alloc]init];
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [playerViewController playVideoWithUrl:url];
    [playerViewController setOverlyViewCoverUrl:coverUrl];
}

- (void)toScoreListVCWithIndexPath:(NSIndexPath *)indexPath{
    
#if MANAGERSIDE
    
    if (self.currentSelectedIndex == indexPath.row) {
        return;
    }
    self.currentSelectedIndex = indexPath.row;
    [self.homeworksTableView reloadData];
    
    Homework *homework = self.homeworks[indexPath.row];
    MIScoreListViewController *scoreListVC = [[MIScoreListViewController alloc] initWithNibName:NSStringFromClass([MIScoreListViewController class]) bundle:nil];
    WeakifySelf;
    scoreListVC.editTaskCallBack = ^{
        weakSelf.currentSelectedIndex = -1;
        [weakSelf searchWithKeyword];
        
        if (weakSelf.popDetailCallBack) {
            weakSelf.popDetailCallBack();
        }
    };
    scoreListVC.cancelCallBack = ^{
        weakSelf.currentSelectedIndex = -1;
        [weakSelf.homeworksTableView reloadData];
    };
    scoreListVC.homework = homework;
    scoreListVC.currentFileInfo = homework.fileInfos.subFile;
    if (self.pushVCCallBack) {
        self.pushVCCallBack(scoreListVC);
    }
#else
   
    NSLog(@"keywords:%@",self.keywords);
    Homework *homework = self.homeworks[indexPath.row];
    MIScoreListViewController *scoreListVC = [[MIScoreListViewController alloc] initWithNibName:NSStringFromClass([MIScoreListViewController class]) bundle:nil];
    scoreListVC.homework = homework;
    scoreListVC.currentFileInfo = homework.fileInfos.subFile;
    scoreListVC.teacherSider = YES;
    [self.navigationController pushViewController:scoreListVC animated:YES];

#endif
}

- (void)sendHomeworkWithIndexPath:(NSIndexPath *)indexPath{
    
    Homework *homework = self.homeworks[indexPath.row];
#if MANAGERSIDE
    
    ClassAndStudentSelectView *selectView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([ClassAndStudentSelectView class]) owner:nil options:nil].lastObject;
    selectView.selectBack = ^(NSArray<Clazz *> * _Nullable classes, NSArray<User *> * _Nullable students) {
        
        [self classAndStudentSelectViewClasses:classes students:students homeworks:@[homework]];
    };
    [selectView showSelectView];
#else
        ClassAndStudentSelectorController *vc = [[ClassAndStudentSelectorController alloc] init];
        [vc setHomeworks:@[homework]];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];

        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController presentViewController:nav animated:YES completion:nil];
#endif
}

- (void)previewHomeworkWithIndexPath:(NSIndexPath *)indexPath{
    
    Homework *homework = self.homeworks[indexPath.row];
    HomeworkPreviewViewController *vc = [[HomeworkPreviewViewController alloc] initWithNibName:NSStringFromClass([HomeworkPreviewViewController class]) bundle:nil];
    vc.homework = homework;
    
#if MANAGERSIDE
    if (self.pushVCCallBack) {
        self.pushVCCallBack(vc);
    }
#else
    [self.navigationController pushViewController:vc animated:YES];
#endif

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

@end

