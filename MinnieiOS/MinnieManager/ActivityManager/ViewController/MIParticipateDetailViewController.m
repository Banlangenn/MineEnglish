//
//  MIParticipateDetailViewController.m
//  MinnieManager
//
//  Created by songzhen on 2019/5/31.
//  Copyright © 2019 minnieedu. All rights reserved.
//


#import "Result.h"
#import <AVKit/AVKit.h>
#import "NEPhotoBrowser.h"
#import "VICacheManager.h"
#import "UIScrollView+Refresh.h"
#import "VIResourceLoaderManager.h"
#import "MIParticipateDetailTableViewCell.h"
#import "MIParticipateDetailViewController.h"

#import "ManagerServce.h"

@interface MIParticipateDetailViewController ()<
UITableViewDelegate,
UITableViewDataSource,
VIResourceLoaderManagerDelegate
>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *uploadArray;

@property (nonatomic, strong) VIResourceLoaderManager *resourceLoaderManager;
@end

@implementation MIParticipateDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self configureUI];
    [self requestactLogs];
}

- (void)configureUI{
    
    self.view.backgroundColor = [UIColor bgColor];
    UIView *footrView = [[UIView alloc] init];
    footrView.backgroundColor = [UIColor clearColor];
    _tableView.tableFooterView = footrView;
    _tableView.cellLayoutMarginsFollowReadableWidth = NO;
}
- (IBAction)backAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
    
    if (self.cancelCallBack) {
        self.cancelCallBack();
    }
}

#pragma mark -
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.uploadArray.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return MIParticipateDetailTableViewCellHeight;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MIParticipateDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MIParticipateDetailTableViewCellId];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIParticipateDetailTableViewCell class]) owner:nil options:nil] lastObject];
    }
    WeakifySelf;
    cell.playVideoCallback = ^(NSString * _Nullable videoUrl) {
        if (videoUrl.length) {
           
            [weakSelf showVideoWithUrl:videoUrl];
        } else {
            [HUD showErrorWithMessage:@"数据错误"];
        }
    };
    cell.qualifiedCallback = ^(NSInteger isOk, ActLogsInfo *logInfo) {
        [weakSelf requestCorrectWithLogInfo:logInfo isOk:isOk];
    };
    [cell setupWithModel:self.uploadArray[indexPath.row] index:indexPath.row + 1];
    return cell;
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

#pragma mark - 视频审阅
- (void)requestCorrectWithLogInfo:(ActLogsInfo *)logInfo isOk:(NSInteger)isOk{
    WeakifySelf;
    [ManagerServce requestCorrectActVideoId:logInfo.logId isOk:isOk actId:logInfo.actId callback:^(Result *result, NSError *error) {
        if (error) return ;
        [HUD showWithMessage:@"审核成功"];
        [weakSelf requestactLogs];
        if (weakSelf.correctCallBack) {
            weakSelf.correctCallBack();
        }
    }];
}
#pragma mark - 获取上传列表

- (void)requestactLogs{
    
    WeakifySelf;
    if (self.uploadArray.count == 0) {
        
        self.tableView.hidden = YES;
        [self.view showLoadingView];
    }
    [ManagerServce requestactLogsActivityId:self.rankInfo.actId stuId:self.rankInfo.userId callback:^(Result *result, NSError *error) {
        
        [weakSelf.view hideAllStateView];
        if (error) {
            if (weakSelf.uploadArray.count == 0) {
             
                [weakSelf.view showFailureViewWithRetryCallback:^{
                    [weakSelf requestactLogs];
                }];
            }
            return;
        }
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *folderList = (NSArray *)(dict[@"list"]);
        weakSelf.uploadArray = folderList;
        
        if (weakSelf.uploadArray.count) {
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
@end
