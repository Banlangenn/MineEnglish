//
//  HomeworkAnswersPickerViewController.m
//  Minnie
//
//  Created by 栋栋 施 on 2019/3/9.
//  Copyright © 2019年 minnieedu. All rights reserved.
//

#import "HomeworkAnswersPickerViewController.h"
#import "UIView+Layout.h"
#import "AnswerPickerCell.h"
#import "Masonry.h"
//#import "VIResourceLoaderManager.h"
//#import "VICacheManager.h"
#import <AVKit/AVKit.h>
#import "NEPhotoBrowser.h"
#import "AudioPlayer.h"
//#import "AudioPlayerViewController.h"
#import "MIPlayerViewController.h"
static CGFloat answerItemMargin = 5;

@interface HomeworkAnswersPickerViewController ()<UICollectionViewDelegate,UICollectionViewDataSource, NEPhotoBrowserDataSource, NEPhotoBrowserDelegate>


@property (weak, nonatomic) IBOutlet UICollectionView *mCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *preViewBtn;
@property (strong, nonatomic) NSMutableArray * selectedAnswers;
//@property (nonatomic, strong) VIResourceLoaderManager *resourceLoaderManager;
@property (nonatomic, strong) NEPhotoBrowser *photoBrowser;
@property (nonatomic, strong) UIImageView * currentSelectedImageView;
@end

@implementation HomeworkAnswersPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.preViewBtn.layer.cornerRadius = 5.0;
    
    self.selectedAnswers = [[NSMutableArray alloc] init];
   
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    CGFloat itemW = (ScreenWidth - (self.columnNumber + 1) * answerItemMargin) / self.columnNumber;
    layout.itemSize = CGSizeMake(itemW, itemW);
    layout.minimumLineSpacing = answerItemMargin;
    layout.minimumInteritemSpacing = answerItemMargin;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionInset = UIEdgeInsetsMake(answerItemMargin, answerItemMargin, answerItemMargin, answerItemMargin);
    self.mCollectionView.collectionViewLayout = layout;
    [self registerCellNib];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)registerCellNib
{
    
    [self.mCollectionView registerNib:[UINib nibWithNibName:@"AnswerPickerImageCell" bundle:nil] forCellWithReuseIdentifier:AnswerPickerImageCellId];
    [self.mCollectionView registerNib:[UINib nibWithNibName:@"AnswerPickerVideoCell" bundle:nil] forCellWithReuseIdentifier:AnswerPickerVideoCellId];
    [self.mCollectionView registerNib:[UINib nibWithNibName:@"AnswerPickerAudioCell" bundle:nil] forCellWithReuseIdentifier:AnswerPickerAudioCellId];
}

- (void)playerVideoWithURL:(NSString *)url {

//    AVAudioSession *session =[AVAudioSession sharedInstance];
//    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
//    NSInteger playMode = [[Application sharedInstance] playMode];
//    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc]init];
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
//    playerViewController.player = player;
//    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:playerViewController animated:YES completion:nil];
//    playerViewController.view.frame = self.view.frame;
//    [playerViewController.player play];
    
    MIPlayerViewController *playerViewController = [[MIPlayerViewController alloc]init];
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [playerViewController playVideoWithUrl:url];
    
}

- (void)showCurrentSelectedImage {
    self.photoBrowser = [[NEPhotoBrowser alloc] init];
    self.photoBrowser.delegate = self;
    self.photoBrowser.dataSource = self;
    self.photoBrowser.clickedImageView = self.currentSelectedImageView;
    [self.photoBrowser showInContext:self.navigationController];
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
    //    VIResourceLoaderManager *resourceLoaderManager = [VIResourceLoaderManager new];
    //    self.resourceLoaderManager = resourceLoaderManager;
    //    AVPlayerItem *playerItem = [resourceLoaderManager playerItemWithURL:[NSURL URLWithString:url]];
    //    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    //    playerViewController.player = player;
    //    [self presentViewController:playerViewController animated:YES completion:nil];
    //    playerViewController.view.frame = self.view.frame;
    //    [playerViewController.player play];
    
    MIPlayerViewController *playerViewController = [[MIPlayerViewController alloc]init];
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [playerViewController playVideoWithUrl:url];
    [playerViewController setOverlyViewCoverUrl:coverUrl];
}

- (IBAction)previewPressed:(UIButton *)sender {
    
    if (self.selectedAnswers.count != 1)
    {
        return;
    }
    
    HomeworkAnswerItem * answerItem  = self.selectedAnswers[0];
    
    if ([answerItem.type isEqualToString:HomeworkAnswerItemTypeVideo])
    {
        [self playerVideoWithURL:answerItem.videoUrl];
    }
    else if ([answerItem.type isEqualToString:HomeworkAnswerItemTypeImage])
    {
        HomeworkAnswerItem * answerItem = self.selectedAnswers[0];
        NSInteger index = [self.answerItems indexOfObject:answerItem];
        AnswerPickerCell * cell = (AnswerPickerCell *)[self.mCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        self.currentSelectedImageView = cell.contentImageView;
        [self showCurrentSelectedImage];
    }
    else
    {
        HomeworkAnswerItem * answerItem = self.selectedAnswers[0];
        [self showAudioWithURL:answerItem.audioUrl withCoverURL:answerItem.audioCoverUrl];
    }
}

- (IBAction)backPressed:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sendAnswerPressed:(UIButton *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(sendAnswer:)])
    {
        [_delegate sendAnswer:self.selectedAnswers];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
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
//    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:alertVC
//                       animated:YES
//                     completion:nil];
//    
//}


#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.answerItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    HomeworkAnswerItem * answerItem  = self.answerItems[indexPath.item];
    AnswerPickerCell * cell;
    if ([answerItem.type isEqualToString:HomeworkAnswerItemTypeVideo])
    {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:AnswerPickerVideoCellId forIndexPath:indexPath];
    }
    else if([answerItem.type isEqualToString:HomeworkAnswerItemTypeImage])
    {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:AnswerPickerImageCellId forIndexPath:indexPath];
    }
    else
    {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:AnswerPickerAudioCellId forIndexPath:indexPath];
    }
    
    
    [cell setContentData:answerItem];
    
    if ([self.selectedAnswers containsObject:answerItem])
    {
        cell.bSelected = YES;
    }
    else
    {
        cell.bSelected = NO;
    }
    
    WeakifySelf;
    cell.didSelectPhotoBlock = ^(BOOL isSelected,HomeworkAnswerItem * item) {
        // 1. cancel select / 取消选择
        if (isSelected) {
            [weakSelf.selectedAnswers addObject:item];
        } else {
            [weakSelf.selectedAnswers removeObject:item];
        }
        
        if (self.selectedAnswers.count == 1)
        {
            weakSelf.preViewBtn.backgroundColor = [UIColor colorWithHex:0x0098FE];
        }
        else
        {
            weakSelf.preViewBtn.backgroundColor = [UIColor colorWithHex:0x7FDFFE];
        }
        
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // preview phote or video / 预览照片或视频
    NSInteger index = indexPath.item;
    HomeworkAnswerItem * item = self.answerItems[index];
    AnswerPickerCell * cell = (AnswerPickerCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if ([self.selectedAnswers containsObject:item])
    {
        [self.selectedAnswers removeObject:item];
        cell.bSelected = NO;
    }
    else
    {
        [self.selectedAnswers addObject:item];
        cell.bSelected = YES;
    }
    
    if (self.selectedAnswers.count == 1)
    {
        self.preViewBtn.backgroundColor = [UIColor colorWithHex:0x0098FE];
    }
    else
    {
        self.preViewBtn.backgroundColor = [UIColor colorWithHex:0x7FDFFE];
    }
    
}

#pragma mark - NEPhotoBrowserDataSource

- (NSInteger)numberOfPhotosInPhotoBrowser:(NEPhotoBrowser *)browser {
    return 1;
}
- (NSURL* __nonnull)photoBrowser:(NEPhotoBrowser * __nonnull)browser imageURLForIndex:(NSInteger)index {
    
    if (self.selectedAnswers.count > 0) {
    
        HomeworkAnswerItem * answerItem = [self.selectedAnswers objectAtIndex:0];
        return [NSURL URLWithString:answerItem.imageUrl];
    }
    return nil;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
