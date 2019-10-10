//
//  MIPlayerViewController.m
//  Minnie
//
//  Created by songzhen on 2019/9/20.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "DownloadVideo.h"
#import "UIView+ViewDesc.h"
#import <Aspects/Aspects.h>
#import "NSObject+BlockObserver.h"
#import "MIPlayerViewController.h"

@interface MIPlayerViewController ()

@property (nonatomic,copy) NSString * currentUrl;

//增加两个属性先
//记录音量控制的父控件，控制它隐藏显示的 view
@property (nonatomic, weak)UIView *volumeSuperView;
//记录我们 hook 的对象信息
@property (nonatomic, strong)id<AspectToken>hookAVPlaySingleTap;
//增加一个保存按钮
@property (nonatomic, strong) UIButton *saveButton;

@end

@implementation MIPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.currentUrl.length > 0) {
        
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
                                    NSLog(@"newValue ==%@",newValue);
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
            
            [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在保存视频%.f%%...", progress * 100]];
        };
        [download startDownloadVedioWithUrl:self.currentUrl];
    } else {
        [HUD showErrorWithMessage:@"视频地址错误"];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    [self.hookAVPlaySingleTap remove];
}

@end
