//
//  MIPlayerViewController.m
//  Minnie
//
//  Created by songzhen on 2019/9/20.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "AudioPlayer.h"
#import "DownloadVideo.h"
#import "UIView+ViewDesc.h"
#import <Aspects/Aspects.h>
#import "NSObject+BlockObserver.h"
#import "MIPlayerViewController.h"
//#import "VICacheManager.h"
#import "DownloadCacheVideo.h"
//#import "VIResourceLoaderManager.h"

@interface MIPlayerViewController (){
    
    BOOL _statusObserver;
}

//增加两个属性先
//记录音量控制的父控件，控制它隐藏显示的 view
@property (nonatomic, weak)UIView *volumeSuperView;
//记录我们 hook 的对象信息
@property (nonatomic, strong)id<AspectToken>hookAVPlaySingleTap;
//增加一个保存按钮
@property (nonatomic, strong) UIButton *saveButton;

// 当前播放URL
@property (nonatomic,copy) NSString * currentUrl;

// 缓存播放
//@property (nonatomic, strong) VIResourceLoaderManager *resourceLoaderManager;
@property (nonatomic,copy) NSString * extensionName;    // 文件扩展名
@property(nonatomic,strong) DownloadCacheVideo * downloadTask;

@property(nonatomic,strong) UIImageView * coverImageView;

@end

@implementation MIPlayerViewController


- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    [self.hookAVPlaySingleTap remove];
    [self.downloadTask cancelDownload];
    
    if (_statusObserver) {
          _statusObserver = NO;
          [self.player.currentItem removeObserver:self forKeyPath:@"status"];
          [self.player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
          [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    [self.player pause];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - 保存视频
- (void)setShowSaveBtn:(BOOL)showSaveBtn{
   
    _showSaveBtn = showSaveBtn;
    if (!self.hookAVPlaySingleTap && _showSaveBtn) {
        
        [self addSaveVideoButton];
    }
}

- (void)addSaveVideoButton {
        
        Class UIGestureRecognizerTarget = NSClassFromString(@"UIGestureRecognizerTarget");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        _hookAVPlaySingleTap = [UIGestureRecognizerTarget aspect_hookSelector:@selector(_sendActionWithGestureRecognizer:) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo>info,UIGestureRecognizer *gest){
            if (gest.numberOfTouches == 1) {
                //AVVolumeButtonControl
                if (!self.volumeSuperView) {
                    UIView *view = [gest.view findViewByClassName:@"AVVolumeButtonControl"];
                    if (view) {
                        while (view.superview) {
                            view = view.superview;
                            if ([view isKindOfClass:[NSClassFromString(@"AVTouchIgnoringView") class]]) {
                                self.volumeSuperView = view;
                                
                                [view HF_addObserverForKeyPath:@"hidden" block:^(__weak id object, id oldValue, id newValue) {
                                    
                                    BOOL isHidden = [(NSNumber *)newValue boolValue];
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        
                                        [self.saveButton setHidden:isHidden];
                                    });
                                    
                                }];
                                break;
                            }
                        }
                    }
                }
            }
            
        } error:nil];
#pragma clang diagnostic pop
        //这里必须监听到准备好开始播放了，才把按钮添加上去（系统控件的懒加载机制，我们才能获取到合适的 view 去添加），不然很突兀！
        [self.player HF_addObserverForKeyPath:@"status" block:^(__weak id object, id oldValue, id newValue) {
            AVPlayerStatus status = [newValue integerValue];
            if (status == AVPlayerStatusReadyToPlay) {
                UIView *avTouchIgnoringView = self.view;
                [avTouchIgnoringView addSubview:self.saveButton];
                
                CGFloat margin = isIPhoneX ? 110 : 89;
                [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.right.mas_equalTo(avTouchIgnoringView).offset(-margin);
                    make.top.mas_equalTo(avTouchIgnoringView).offset(isIPhoneX ? 50 : 26);
                    make.width.mas_equalTo(44);
                    make.height.mas_equalTo(44);
                }];
                [avTouchIgnoringView setNeedsLayout];
            }
        }];
}

- (UIButton *)saveButton{
    if (!_saveButton) {
        
        _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_saveButton setImage:[UIImage imageNamed:@"default_save_image"] forState:UIControlStateNormal];
        [_saveButton addTarget:self action:@selector(saveVideoClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveButton;
}

- (void)showSaveVideo:(NSString *)url{
    
    self.currentUrl = url;
}

- (void)saveVideoClicked:(UIButton *)btn{
  

    if (self.currentUrl.length > 0) {
        
        DownloadVideo *download = [[DownloadVideo alloc] init];
        WeakifySelf;
        download.successCallBack = ^(BOOL success) {
            weakSelf.saveButton.selected = NO;
            [HUD hideAnimated:YES];
        };
        download.progressCallBack = ^(CGFloat progress) {
            
            NSInteger current = progress * 100;
            if (current % 5 == 0) {
                [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在保存视频%ld%%...",(long)current]];
            }
            if (progress >= 1) {
                [HUD hideAnimated:YES];
            }
        };
        [download startDownloadVedioWithUrl:self.currentUrl];
    } else {
        [HUD showErrorWithMessage:@"视频地址错误"];
    }
}


#pragma 播放状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if (object == self.player.currentItem && [keyPath isEqualToString:@"status"]) {
        switch (self.player.currentItem.status) {
            case AVPlayerItemStatusUnknown:     // 未知状态，此时不能播放
            NSLog(@"AVPlayerItemStatusUnknown");
                break;
            case AVPlayerItemStatusReadyToPlay: // 准备完毕，可以播放
                [self.player play];
                break;
            case AVPlayerItemStatusFailed:      // 加载失败，网络或者服务器出现问题

                NSLog(@"AVPlayerItemStatusFailed");
                break;
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {

       NSLog(@"playbackBufferEmpty");
        if (!self.player.currentItem.isPlaybackBufferEmpty) {
             [self.player play];
         }
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        NSLog(@"playbackLikelyToKeepUp");
        if (!self.player.currentItem.isPlaybackLikelyToKeepUp) {
             [self.player play];
         }
    }
}

#pragma mark - 封面

- (void)setOverlyViewCoverUrl:(NSString *)cover
{
    if (!self.coverImageView) {
        
        self.coverImageView = [[UIImageView alloc] init];
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.coverImageView.backgroundColor = [UIColor blackColor];
        [self.contentOverlayView addSubview:self.coverImageView];
        [self.coverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentOverlayView);
        }];
    }
    [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:cover]];
}


- (void)playVideoWithUrl:(NSString *)videoUrl {
   
    self.extensionName = @"mp4";
    [self playWithUrl:videoUrl];
}


- (void)playAudioWithUrl:(NSString *)audioUrl coverUrl:(NSString *)cover{
   
    self.extensionName = @"mp3";
    [self playWithUrl:audioUrl];
    [self setOverlyViewCoverUrl:cover];
}

- (void)playAudioWithUrl:(NSString *)audioUrl {
    
}

#pragma mark - 播放视频
- (void)playWithUrl:(NSString *)url{
    
    self.currentUrl = url;
    [[AudioPlayer sharedPlayer] stop];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    NSInteger playMode = [[Application sharedInstance] playMode];
    
    AVPlayer *player;
    if (playMode == 1)// 在线播放
    {
        // 在线播放
        player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:url]];
    }
    else
    {// 缓存播放

        
        NSString *videoPath = [DownloadCacheVideo cachedFilePathForURL:[NSURL URLWithString:url] extensionName:self.extensionName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {// 判断是否有缓存文件
            
            AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:videoPath]];
            [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
            [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
            [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
            _statusObserver = YES;
            
            player = [AVPlayer playerWithPlayerItem:item];
            NSLog(@"缓存播放");
        } else {// 在线播放
            
             AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]];
             [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
             [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
             [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
             _statusObserver = YES;
            player = [AVPlayer playerWithPlayerItem:item];

            NSLog(@"在线播放");
            [self performSelector:@selector(startDownload) withObject:nil afterDelay:5.0];
        }
    }
    
    self.player = player;
    self.view.frame = [UIScreen mainScreen].bounds;
    [self.player play];
}

- (void)startDownload{
    
    [self.downloadTask startDownloadWithUrl:self.currentUrl extensionName:self.extensionName];
}

- (DownloadCacheVideo *)downloadTask{
  
    if (!_downloadTask) {
        _downloadTask = [[DownloadCacheVideo alloc] init];
    }
    return _downloadTask;
}

#pragma mark - VIResourceLoaderManagerDelegate
//- (void)resourceLoaderManagerLoadURL:(NSURL *)url didFailWithError:(NSError *)error
//{
//    [VICacheManager cleanCacheForURL:url error:nil];
//    // 适配ipad版本
////    UIAlertControllerStyle alertStyle;
////    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
////        alertStyle = UIAlertControllerStyleActionSheet;
////    } else {
////        alertStyle = UIAlertControllerStyleAlert;
////    }
////    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil
////                                                                     message:@"播放失败"
////                                                              preferredStyle:alertStyle];
////    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定"
////                                                           style:UIAlertActionStyleCancel
////                                                         handler:^(UIAlertAction * _Nonnull action) {
////                                                             [self.tabBarController dismissViewControllerAnimated:YES completion:^{
////
////                                                             }];
////                                                         }];
////
////    [alertVC addAction:cancelAction];
////
////    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
////    [self presentViewController:alertVC
////                       animated:YES
////                     completion:nil];
////
//}


@end
