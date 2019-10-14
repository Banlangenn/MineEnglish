//
//  CSCustomSplitViewController.m
//  CSCustomSplitViewController-Demo
//
//  Created by Huang Chusheng on 16/11/23.
//  Copyright © 2016年 Aaron. All rights reserved.
//

#import "CSCustomSplitViewController.h"
#import "Masonry.h"

#define k_DefaultPrimaryCloumnScale (kRootModularWidth + kColumnSecondWidth) // 默认的主控制器宽度（同时显示时）
#define k_AnimatedTimeInterval 0.25 // 动画时长

@interface CSCustomSplitViewController ()

- (void)addMyChildViewControllers;

@end

@implementation CSCustomSplitViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initializerData];
    }
    return self;
}
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initializerData];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializerData];
    }
    return self;
}
- (void)initializerData {
    _primaryCloumnScale = k_DefaultPrimaryCloumnScale;
    _displayMode = CSSplitDisplayModeDisplayPrimaryAndSecondary;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addMyChildViewControllers];
}
- (void)viewWillLayoutSubviews {
    [self setDisplayMode:self.displayMode withAnimated:NO];
}
#pragma mark - setter
- (void)setPrimaryCloumnScale:(CGFloat)primaryCloumnScale {
    
    _primaryCloumnScale = primaryCloumnScale;
    if (primaryCloumnScale < kRootModularWidth) {
        _primaryCloumnScale = kRootModularWidth;
    }
}
- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    
    if (_viewControllers) {
        // 移除旧的vc
        for (UIViewController *vc in _viewControllers) {
            [vc.view removeFromSuperview];
            [vc removeFromParentViewController];
        }
        _viewControllers = nil;
    }
    
    // 当入参为nil或数组个数小于2时，不做处理
    if ((viewControllers == nil) || viewControllers.count < 2) {
        return;
    }
    
    _viewControllers = viewControllers;
    
    // 若self已加载, 则直接添加viewControllers
    if (self.isViewLoaded) {
        [self addMyChildViewControllers];
    }
}

#pragma mark - private methods
- (void)addMyChildViewControllers {
    
    for (UIViewController *vc in _viewControllers) {
        [self addChildViewController:vc];
        [self.view addSubview:vc.view];
    }
    [self setDisplayMode:self.displayMode withAnimated:NO];
}
#pragma mark - optional methods
- (void)setDisplayMode:(CSSplitDisplayMode)displayMode withAnimated:(BOOL)animated {
    if ((self.viewControllers == nil) || self.viewControllers.count < 2) {
        return;
    }
    // self还未加载时直接赋值属性
    if (NO == self.isViewLoaded) {
        _displayMode = displayMode;
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(customSplitViewController:willChangeToDisplayMode:)]) {
        [self.delegate customSplitViewController:self willChangeToDisplayMode:displayMode];
    }
    
    CGFloat viewWidth = self.view.frame.size.width;
    CGFloat primaryWidth = self.primaryCloumnScale;
    CGFloat secondaryWidth = viewWidth - primaryWidth;
    
    UIViewController *primaryVC = self.viewControllers[0];
    UIViewController *secondaryVC = self.viewControllers[1];
    UIViewController *additionalVC = (self.viewControllers.count > 2) ? self.viewControllers[2] : nil;
    
    switch (displayMode) {
        case CSSplitDisplayModeDisplayPrimaryAndSecondary:{
            [primaryVC.view mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(@0);
                make.left.equalTo(@0);
                make.bottom.equalTo(@0);
                make.width.equalTo(@(primaryWidth));
            }];
            [secondaryVC.view mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(@0);
                make.right.equalTo(@(0));
                make.bottom.equalTo(@0);
                make.width.equalTo(@(secondaryWidth));
            }];
            if (additionalVC) {
                [additionalVC.view mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(@0);
                    make.left.equalTo(@(viewWidth));
                    make.bottom.equalTo(@0);
                    make.width.equalTo(@(primaryWidth));
                }];
            }
        }
            break;
        case CSSplitDisplayModeDisplaySecondaryAndAdditional:{
            [primaryVC.view mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(@0);
                make.left.equalTo(@(-primaryWidth));
                make.bottom.equalTo(@0);
                make.width.equalTo(@(primaryWidth));
            }];
            [secondaryVC.view mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(@0);
                make.left.equalTo(@(0));
                make.bottom.equalTo(@0);
                make.width.equalTo(@(secondaryWidth));
            }];
            if (additionalVC) {
                [additionalVC.view mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(@0);
                    make.right.equalTo(@0);
                    make.bottom.equalTo(@0);
                    make.width.equalTo(@(primaryWidth));
                }];
            }
        }
            break;
        case CSSplitDisplayModeOnlyDisplayPrimary:{
            [primaryVC.view mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(@0);
                make.left.equalTo(@0);
                make.bottom.equalTo(@0);
                make.width.equalTo(@(viewWidth));
            }];
            [secondaryVC.view mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(@0);
                make.left.equalTo(@(viewWidth));
                make.bottom.equalTo(@0);
                make.width.equalTo(@(secondaryWidth));
            }];
            if (additionalVC) {
                [additionalVC.view mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(@0);
                    make.left.equalTo(@(viewWidth + secondaryWidth));
                    make.bottom.equalTo(@0);
                    make.width.equalTo(@(primaryWidth));
                }];
            }
        }
            break;
    }
    
    _displayMode = displayMode;
    
    if (animated) {
        [UIView animateWithDuration:k_AnimatedTimeInterval animations:^{
            [self.view setNeedsUpdateConstraints];
            [self.view updateConstraintsIfNeeded];
            [self.view layoutIfNeeded];
        }];
    } else {
        [self.view setNeedsUpdateConstraints];
        [self.view updateConstraintsIfNeeded];
        [self.view layoutIfNeeded];
    }
}

@end


@implementation UIViewController (CSCustomSplitViewController)

- (CSCustomSplitViewController *)customSplitViewController {
    
    UIViewController *splitVC = self;
    do {
        splitVC = splitVC.parentViewController;
    } while ((splitVC != nil) && (NO == [[splitVC class] isSubclassOfClass:[CSCustomSplitViewController class]]));
    ;
    return (CSCustomSplitViewController *)splitVC;
}

@end
