//
//  MIPlayerViewController.m
//  Minnie
//
//  Created by songzhen on 2019/9/20.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "DownloadVideo.h"
#import "MIPlayerViewController.h"

@interface MIPlayerViewController ()

@property (nonatomic,strong) UIButton * saveBtn;

@property (nonatomic,copy) NSString * currentUrl;
@end

@implementation MIPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (UIButton *)saveBtn{
    if (!_saveBtn) {
        
        _saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _saveBtn.frame = CGRectMake(ScreenWidth - 140,25, 44, 44);
        [_saveBtn setImage:[UIImage imageNamed:@"default_save_image"] forState:UIControlStateNormal];
        [_saveBtn addTarget:self action:@selector(saveVideoBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveBtn;
}

- (void)showSaveVideo:(NSString *)url{
    
    self.currentUrl = url;
    [self.view addSubview:self.saveBtn];
}

- (void)saveVideoBtnClicked:(UIButton *)btn{
    
    if (self.currentUrl.length > 0) {
        
        DownloadVideo *download = [[DownloadVideo alloc] init];
//        @"http://file.zhengminyi.com/XMXRmyGqqtLroHp43oJgAXD.mp4"
        [download startDownloadVedioWithUrl:self.currentUrl];
    } else {
        [HUD showErrorWithMessage:@"视频地址错误"];
    }
}

@end
