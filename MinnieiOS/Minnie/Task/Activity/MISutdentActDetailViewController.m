//
//  MISutdentActDetailViewController.m
//  Minnie
//
//  Created by songzhen on 2019/6/8.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "Result.h"
#import "NSDate+Extension.h"
#import "ManagerServce.h"
#import "UIScrollView+Refresh.h"
#import "MIStuActDetailHeaderView.h"
#import "MISutActDetailTableViewCell.h"
#import "MIStuUploadVideoViewController.h"
#import "MISutdentActDetailViewController.h"

#import "AudioPlayer.h"
#import <AVKit/AVKit.h>
#import "VICacheManager.h"
#import "FileUploader.h"
#import "NEPhotoBrowser.h"
#import "VIResourceLoaderManager.h"
#import "AudioPlayerViewController.h"
#import "WBGImageEditorViewController.h"

#import <objc/runtime.h>
#import <AVKit/AVKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface MISutdentActDetailViewController ()<
NEPhotoBrowserDelegate,
NEPhotoBrowserDataSource,
VIResourceLoaderManagerDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate
>
@property (weak, nonatomic) IBOutlet UILabel *actTitleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UIButton *commitBtn;

@property (strong,nonatomic) NSArray *rankList;

@property (nonatomic, strong) MBProgressHUD * mHud;


@property (nonatomic, weak) UIImageView *currentSelectedImageView;
@property (nonatomic, strong) NEPhotoBrowser *photoBrowser;
@property (nonatomic, strong) VIResourceLoaderManager *resourceLoaderManager;

@property (nonatomic, weak) NSString *currentSelectedImageUrl;

@property (nonatomic, assign) NSInteger submitNum;

@property (nonatomic, strong) MIStuActDetailHeaderView *headerView;

@end

@implementation MISutdentActDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _headerView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIStuActDetailHeaderView class]) owner:nil options:nil].lastObject;
    _headerView.autoresizingMask = UIViewAutoresizingNone;
    [self setupActInfo];
    
    WeakifySelf;
    [_headerView setVideoCallback:^(NSString *videoUrl) {
        [weakSelf playerVideoWithURL:videoUrl];
    }];
    [_headerView setImageCallback:^(NSString * imageUrl, UIImageView * currentImage, NSInteger index) {
        weakSelf.currentSelectedImageView = currentImage;
        weakSelf.currentSelectedImageUrl = imageUrl;
        [weakSelf showCurrentSelectedImage];
    }];
    
    [_headerView setAudioCallback:^(NSString * audioUrl, NSString * audioCoverUrl) {
        [weakSelf playAudioWithURL:audioUrl withCoverURL:audioCoverUrl];
    }];
    
    self.tableview.tableHeaderView = _headerView;
    UIView *footerView = [[UIView alloc] init];
    footerView.backgroundColor = [UIColor clearColor];
    self.tableview.tableFooterView = footerView;
    
    [self.tableview addPullToRefreshWithRefreshingBlock:^{
        
        [weakSelf requestGetActivityDetail];
        [weakSelf requestGetStuActivityRankList];
        [weakSelf requestactLogsActivity];
    }];
    [self.tableview headerBeginRefreshing];
}

- (void)setupActInfo{
    
    NSDate *endDate = [NSDate dateByDateString:self.actInfo.endTime format:@"yyyy-MM-dd HH:mm:ss"];
    if ([endDate isEarlierThanDate:[NSDate date]]) {
      
        if (self.actCallBack) {
            self.actCallBack();
        }
        [HUD showWithMessage:@"活动已结束"];
        [self.navigationController popViewControllerAnimated:YES];
        return; // 活动结束
    }
    _headerView.actInfo = self.actInfo;
    CGFloat height = [MIStuActDetailHeaderView heightWithActInfo:self.actInfo];
    _headerView.frame = CGRectMake(0, 0, ScreenWidth, height);
}


- (IBAction)backAction:(id)sender {
    
    if (self.actCallBack) {
        self.actCallBack();
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)uploadAction:(id)sender {
    [self handleAddItem];
}

- (IBAction)myUploadAction:(id)sender {
    
    MIStuUploadVideoViewController *uploadVC = [[MIStuUploadVideoViewController alloc] initWithNibName:NSStringFromClass([MIStuUploadVideoViewController class]) bundle:nil];
    uploadVC.actId = self.actInfo.activityId;
    [self.navigationController pushViewController:uploadVC animated:YES];
}

#pragma mark - UITableViewDataSource && UITableViewDelagete
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.rankList.count) {
        if (indexPath.row == 0) {
            return 40;
        } else {
            return MISutActDetailTableViewCellHeight;
        }
    }
    return 0.01;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.rankList.count) {
        
        return self.rankList.count + 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActDetailCellId"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ActDetailCellId"];
            cell.textLabel.font = [UIFont systemFontOfSize:14];
            cell.textLabel.textColor = [UIColor detailColor];
        }
        cell.textLabel.text = @"当前排名:";
        return cell;
    } else {
       
        MISutActDetailTableViewCell *contentCell = [tableView dequeueReusableCellWithIdentifier:MISutActDetailTableViewCellId];
        if (contentCell == nil) {
            contentCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MISutActDetailTableViewCell class]) owner:nil options:nil] lastObject];
        }
        WeakifySelf;
        contentCell.videoCallback = ^(NSString * _Nullable videUrl) {
            [weakSelf playerVideoWithURL:videUrl];
        };
        [contentCell setupRanInfo:self.rankList[indexPath.row - 1] index:indexPath.row];
        return contentCell;
    }
    
}

#pragma mark - 获取活动详情
- (void)requestGetActivityDetail{
    
    WeakifySelf;
    [ManagerServce requestGetActivityDetailWithActId:self.actInfo.activityId callback:^(Result *result, NSError *error) {
        
        // 更新活动
        ActivityInfo *actInfo = (ActivityInfo *)(result.userInfo);
        weakSelf.actInfo = actInfo;
        [weakSelf setupActInfo];
        [weakSelf.tableview headerEndRefreshing];
    }];
}

#pragma mark - 获取活动排行列表
- (void)requestGetStuActivityRankList{
    
    WeakifySelf;
    [ManagerServce requestGetStuActivityRankListWithActId:self.actInfo.activityId callback:^(Result *result, NSError *error) {
        
        [weakSelf.tableview hideAllStateView];
        [weakSelf.tableview headerEndRefreshing];
        if (error) {
            
            [weakSelf.tableview showFailureViewWithRetryCallback:^{
                [weakSelf requestGetStuActivityRankList];
            }];
            return;
        }
        
        [weakSelf.tableview hideAllStateView];
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *folderList = (NSArray *)(dict[@"list"]);
        weakSelf.rankList = folderList;
    
        if (weakSelf.rankList.count) {
            [weakSelf.tableview reloadData];
        } else {
            
            CGFloat offsetY = 0;
            if ([MIStuActDetailHeaderView heightWithActInfo:weakSelf.actInfo] < ScreenHeight/2.0) {
                offsetY = ScreenHeight/7.0;
            } else if (([MIStuActDetailHeaderView heightWithActInfo:weakSelf.actInfo] < ScreenHeight)) {
                
                offsetY = ScreenHeight/2.0 - (ScreenHeight - [MIStuActDetailHeaderView heightWithActInfo:weakSelf.actInfo])/2.0;
            } else {
                offsetY = [MIStuActDetailHeaderView heightWithActInfo:weakSelf.actInfo] + 40;
            }
            [weakSelf.tableview showEmptyViewWithImage:nil
                                            title:@"暂无排行"
                                    centerYOffset:offsetY
                                        linkTitle:nil
                                linkClickCallback:nil
                                    retryCallback:^{
                                        
                                    }];
            [weakSelf.tableview reloadData];
        }
    }];
}

#pragma mark - 获取我的上传
- (void)requestactLogsActivity{
    
    WeakifySelf;
    [ManagerServce requestactLogsActivityId:self.actInfo.activityId stuId:APP.currentUser.userId callback:^(Result *result, NSError *error) {
        
        [weakSelf.tableview headerEndRefreshing];
        [weakSelf.view hideAllStateView];
        if (error) return;
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *folderList = (NSArray *)(dict[@"list"]);
        
        weakSelf.submitNum = folderList.count;
        weakSelf.commitBtn.enabled = YES;
        if (folderList.count == 0) {
            [weakSelf.commitBtn setTitle:[NSString stringWithFormat:@"上传(可提交%lu次)",weakSelf.actInfo.submitNum] forState:UIControlStateNormal];
        } else  if (folderList.count >= weakSelf.actInfo.submitNum) {
            weakSelf.commitBtn.enabled = NO;
            [weakSelf.commitBtn setTitle:@"上传（剩余0次)" forState:UIControlStateNormal];
        } else {
            [weakSelf.commitBtn setTitle:[NSString stringWithFormat:@"上传（剩余%lu次)",weakSelf.actInfo.submitNum - folderList.count] forState:UIControlStateNormal];
        }
    }];
}

#pragma mark - 播放视频、展示图片
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


#pragma mark - 上传视频
- (void)handleAddItem {
    
    // 适配ipad版本
    UIAlertControllerStyle alertStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        alertStyle = UIAlertControllerStyleActionSheet;
    } else {
        alertStyle = UIAlertControllerStyleAlert;
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"选择视频"
                                                                     message:nil
                                                              preferredStyle:alertStyle];
    WeakifySelf;
    UIAlertAction * videoAction = [UIAlertAction actionWithTitle:@"视频"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [weakSelf addVideoItem];
                                                         }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    [alertVC addAction:videoAction];
    [alertVC addAction:cancelAction];

    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:alertVC
                                           animated:YES
                                         completion:nil];
}

- (void)addVideoItem {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeMovie];

    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)uploadVideoForPath:(NSURL *)videoUrl{
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld_compressedVideo.mp4",time(NULL)]];
    [HUD showProgressWithMessage:@"正在压缩视频文件..."];
    AVURLAsset *avAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    
    NSTimeInterval durationInSeconds = 0.0;
    if (avAsset != nil) {
        durationInSeconds = CMTimeGetSeconds(avAsset.duration);
    }
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPreset1280x720];
        exportSession.outputURL = [NSURL fileURLWithPath:path];
        exportSession.shouldOptimizeForNetworkUse = true;
        exportSession.outputFileType = AVFileTypeMPEG4;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    WeakifySelf;
                    __block BOOL flag = NO;
                    QNUploadOption * option = [[QNUploadOption alloc] initWithMime:nil progressHandler:^(NSString *key, float percent) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (!weakSelf.mHud)
                            {
                                weakSelf.mHud = [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传视频%.f%%...", percent * 100] cancelCallback:^{
                                    flag = YES;
                                }];
                            }
                            else
                            {
                                UILabel * label = [weakSelf.mHud.customView viewWithTag:99];
                                
                                label.text = [NSString stringWithFormat:@"正在上传视频%.f%%...", percent * 100];
                            }
                        });
                    } params:nil checkCrc:NO cancellationSignal:^BOOL{
                        return flag;
                    }];
                    
                    [[FileUploader shareInstance] qn_uploadFile:path type:UploadFileTypeVideo option:option completionBlock:^(NSString * _Nullable videoUrl, NSError * _Nullable error) {
                        weakSelf.mHud = nil;
                        if (videoUrl.length == 0) {
                            [HUD showErrorWithMessage:@"视频上传失败"];
                            
                            return ;
                        }
                        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                        
                        [weakSelf requestCommitActivityVideoWithActTimes:ceil(durationInSeconds) videoUrl:videoUrl];
                        [weakSelf.tableview reloadData];
                    }];
                });
            }else{
                NSLog(@"当前压缩进度:%f",exportSession.progress);
            }
            NSLog(@"%@",exportSession.error);
            
        }];
    }
}

#pragma mark 上传活动视频
- (void)requestCommitActivityVideoWithActTimes:(NSInteger)times videoUrl:(NSString *)videoUrl{
    WeakifySelf;
    [ManagerServce requestCommitActivityId:self.actInfo.activityId actTimes:times actUrl:videoUrl callback:^(Result *result, NSError *error) {
        if (error) {
            [HUD showErrorWithMessage:@"视频上传失败"];
        } else {
            [HUD showWithMessage:@"视频上传成功"];
            [weakSelf requestGetStuActivityRankList];
            [weakSelf requestactLogsActivity];
        }
    }];
}

#pragma mark - UIImagePickerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.movie"]) {
        [self handleVideoPickerResult:picker didFinishPickingMediaWithInfo:info];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleVideoPickerResult:(UIImagePickerController *)picker
  didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        [self uploadVideoForPath:videoUrl];
    }];
}

@end
