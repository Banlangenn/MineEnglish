//
//  HomeworkPreviewViewController.m
//  MinnieStudent
//
//  Created by songzhen on 2019/5/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "AudioPlayer.h"
#import <AVKit/AVKit.h>
#import "VICacheManager.h"
#import "FileUploader.h"
#import "NEPhotoBrowser.h"
#import "VIResourceLoaderManager.h"
#import "AudioPlayerViewController.h"
#import "WBGImageEditorViewController.h"

#import "HomeworkSessionService.h"
#import "SessionHomeworkTableViewCell.h"
#import "HomeworkPreviewViewController.h"

@interface HomeworkPreviewViewController ()<
NEPhotoBrowserDelegate,
NEPhotoBrowserDataSource,
UITableViewDelegate,
UITableViewDataSource,
VIResourceLoaderManagerDelegate
>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

// 作业session
@property (nonatomic, strong) HomeworkSession *homeworkSession;

@property (nonatomic, weak) UIImageView *currentSelectedImageView;

@property (nonatomic, weak) NSString *currentSelectedImageUrl;

@property (nonatomic, strong) NEPhotoBrowser *photoBrowser;

@property (nonatomic, strong) VIResourceLoaderManager *resourceLoaderManager;


@property (nonatomic, strong) NSMutableArray * homeworkImages;    //图片作业详情

@end

@implementation HomeworkPreviewViewController

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    self.homework.cellHeight = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.homeworkSession = [[HomeworkSession alloc] init];
    // 作业管理页面已获得cell高度，和预览中高度不匹配，清除高度，重新计算
    self.homework.cellHeight = 0;
    self.homeworkSession.homework = self.homework;
    
    //从作业中提取
    self.homeworkImages = [NSMutableArray array];
    for (int i = 0; i < self.homeworkSession.homework.items.count; i++)
    {
        HomeworkItem * items = [self.homeworkSession.homework.items objectAtIndex:i];
        if ([items.type isEqualToString:HomeworkItemTypeImage])
        {
            [self.homeworkImages addObject:items.imageUrl];
        }
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundColor = [UIColor colorWithHex:0xF5F5F5];
    UIView *footerView = [[UIView alloc] init];
    footerView.backgroundColor =[UIColor clearColor];
    self.tableView.tableFooterView = footerView;
    [self.tableView reloadData];
}
- (IBAction)backAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource && UITableViewDelagete

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [SessionHomeworkTableViewCell heightWithHomeworkSession:self.homeworkSession];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.homeworkSession) {
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *nibName =  @"SessionHomeworkTableViewCell";;
    SessionHomeworkTableViewCell *cell = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] lastObject];
    
    [cell setupWithHomeworkSession:self.homeworkSession];
    
    WeakifySelf;
    [cell setVideoCallback:^(NSString *videoUrl) {
        [weakSelf playerVideoWithURL:videoUrl];
    }];
    [cell setImageCallback:^(NSString * imageUrl, UIImageView * currentImage, NSInteger index) {
       
        weakSelf.currentSelectedImageView = currentImage;
        weakSelf.currentSelectedImageUrl = imageUrl;
        [weakSelf showCurrentSelectedImage];
    }];
    
    [cell setAudioCallback:^(NSString * audioUrl, NSString * audioCoverUrl) {
        [weakSelf playAudioWithURL:audioUrl withCoverURL:audioCoverUrl];
    }];
    return cell;
}

- (void)showCurrentSelectedImage {
    
    self.photoBrowser = [[NEPhotoBrowser alloc] init];
    self.photoBrowser.delegate = self;
    self.photoBrowser.dataSource = self;
    self.photoBrowser.clickedImageView = self.currentSelectedImageView;
    
    [self.photoBrowser showInContext:self.navigationController];
}
- (void)playerVideoWithURL:(NSString *)url {
    
    [[AudioPlayer sharedPlayer] stop];
    AVAudioSession *session =[AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSInteger playMode = [[Application sharedInstance] playMode];

    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc]init];
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
}

- (void)playAudioWithURL:(NSString *)url withCoverURL:(NSString *)coverUrl
{
    [[AudioPlayer sharedPlayer] stop];
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
    //播放失败清除缓存
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
                                                             [self dismissViewControllerAnimated:YES completion:^{
                                                                 
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

@end
