//
//  MIStuUploadVideoViewController.m
//  MinnieStudent
//
//  Created by songzhen on 2019/6/9.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "Result.h"
#import "ManagerServce.h"

#import "MISutActDetailTableViewCell.h"
#import "MIStuUploadVideoViewController.h"


#import "AudioPlayer.h"
#import <objc/runtime.h>
#import <AVKit/AVKit.h>
#import "VICacheManager.h"
#import "VIResourceLoaderManager.h"
#import "AudioPlayerViewController.h"

@interface MIStuUploadVideoViewController ()
<
VIResourceLoaderManagerDelegate
>

@property (strong,nonatomic) NSArray *uploadList;

@property (nonatomic, strong) VIResourceLoaderManager *resourceLoaderManager;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end


@implementation MIStuUploadVideoViewController

- (void)viewDidLoad {
   
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundColor = [UIColor bgColor];
    UIView *footerView = [[UIView alloc] init];
    footerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = footerView;
    
    [self requestactLogsActivity];
}

- (IBAction)backAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - UITableViewDataSource && UITableViewDelagete
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return MISutActDetailTableViewCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return self.uploadList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    MISutActDetailTableViewCell *contentCell = [tableView dequeueReusableCellWithIdentifier:MISutActDetailTableViewCellId];
    if (contentCell == nil) {
        contentCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MISutActDetailTableViewCell class]) owner:nil options:nil] lastObject];
   
    }
    WeakifySelf;
    contentCell.videoCallback = ^(NSString * _Nullable videUrl) {
      
        [weakSelf playerVideoWithURL:videUrl];
    };
    [contentCell setupRanInfo:self.uploadList[indexPath.row]];
    return contentCell;
}

#pragma mark - 获取上传列表
- (void)requestactLogsActivity{
    
    WeakifySelf;
    self.tableView.hidden = YES;
    [self.view showLoadingView];
    [ManagerServce requestactLogsActivityId:self.actId stuId:APP.currentUser.userId callback:^(Result *result, NSError *error) {
        
        [weakSelf.view hideAllStateView];
        if (error) {
            
            [weakSelf.view showFailureViewWithRetryCallback:^{
                [weakSelf requestactLogsActivity];
            }];
            return;
        }
        [weakSelf.view hideAllStateView];
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *folderList = (NSArray *)(dict[@"list"]);
        weakSelf.uploadList = folderList;
        
        if (weakSelf.uploadList.count) {
            weakSelf.tableView.hidden = NO;
            [weakSelf.tableView reloadData];
        } else {
            [weakSelf.view showEmptyViewWithImage:nil
                                                 title:@"列表为空"
                                         centerYOffset:0
                                             linkTitle:nil
                                     linkClickCallback:nil
                                         retryCallback:^{
                                             
                                         }];
        }
    }];
}

#pragma mark - 播放视频
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

@end
