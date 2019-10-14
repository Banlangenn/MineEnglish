//
//  HomeworkSessionsContainerViewController.m
//  X5
//
//  Created by yebw on 2017/8/21.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "HomeworkSessionsContainerViewController.h"
#import "CalendarViewController.h"
#import "SegmentControl.h"
#import "IMManager.h"
#import "AlertView.h"
#import "Clazz.h"
#import "PublicService.h"
#import "AppVersion.h"
#import "FilterAlertView.h"
#import "AppDelegate.h"

#if TEACHERSIDE || MANAGERSIDE

#import "HomeworkSearchNameViewController.h"
#import <FileProviderUI/FileProviderUI.h>
#import <FileProvider/FileProvider.h>
#else
#import "CircleService.h"
#import "CircleHomeworkFlag.h"
#import "AchieverListViewController.h"
#import "AchieverService.h"
//#import "UserMedalDto.h"

#endif

@interface HomeworkSessionsContainerViewController ()

// 未完成
@property (nonatomic, strong) HomeworkSessionsViewController *unfinishedClassesChildController;
// 已完成
@property (nonatomic, strong) HomeworkSessionsViewController *finishedClassesChildController;

@property (nonatomic, assign) NSInteger  currentFliterType;  //教师端： 0 按时间 1 按作业 2 按人 学生端： 0星~6星
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) HomeworkSessionsViewController * currentViewController;
@property (nonatomic ,strong) NSArray * fliterTitles;
#if TEACHERSIDE || MANAGERSIDE
//未提交
@property (nonatomic, strong) HomeworkSessionsViewController *uncommitClassesChildController;

#else
#endif

@property (nonatomic, assign) BOOL ignoreScrollCallback;

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UIScrollView *containerScrollView;
@property (nonatomic, weak) IBOutlet UIView *customTitleView;
@property (nonatomic, weak) IBOutlet UIButton * rightFuncButton;
@property (nonatomic, weak) IBOutlet UIButton * leftFuncButton;
@property (nonatomic, weak) SegmentControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIView *redIncoinView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerContentY;
@property (weak, nonatomic) IBOutlet UIView *rightLineView;

@property (nonatomic, assign) BOOL everAppeared;

@property (nonatomic, assign) CGFloat screenWidth;

@property (nonatomic, strong) Teacher *teacher;

#if MANAGERSIDE

@property (nonatomic, assign) BOOL unfinishedNeedUpdate;
@property (nonatomic, assign) BOOL finishedNeedUpdate;
@property (nonatomic, assign) BOOL uncommitNeedUpdate;

#endif

@end

@implementation HomeworkSessionsContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentIndex = 0;
    self.screenWidth = ScreenWidth;
#if MANAGERSIDE
    self.screenWidth = kColumnThreeWidth;
    self.rightLineView.hidden = NO;
#else
    self.rightLineView.hidden = YES;
#endif
    [self checkAppVersion];

#if TEACHERSIDE || MANAGERSIDE
    
    self.containerContentY.constant = 3 * self.screenWidth;
    self.fliterTitles = @[@"按时间",@"按任务",@"按人"];
    [self.leftFuncButton setImage:[UIImage imageNamed:@"navbar_search"] forState:UIControlStateNormal];
    [self.rightFuncButton setImage:[UIImage imageNamed:@"navbar_screen"] forState:UIControlStateNormal];
    [self.rightFuncButton setImageEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
#else
    
    self.fliterTitles = @[@"全部",@"0星",@"1星",@"2星",@"3星",@"4星",@"5星"];
    [self.leftFuncButton setImage:[UIImage imageNamed:@"navbar_medal"] forState:UIControlStateNormal];
    [self.rightFuncButton setImage:[UIImage imageNamed:@"navbar_calendar"] forState:UIControlStateNormal];
    [self.rightFuncButton setImageEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
#endif
    
    if (isIPhoneX) {
        self.heightLayoutConstraint.constant = -(44 + [UIApplication sharedApplication].statusBarFrame.size.height);
    }
    
    
#if TEACHERSIDE || MANAGERSIDE
    self.segmentControl = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SegmentControl class]) owner:nil options:nil] firstObject];
    self.segmentControl.titles = @[@"待批改", @"已完成",@"未提交"];
#else
    self.segmentControl = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SegmentControl class]) owner:nil options:nil] lastObject];
    self.segmentControl.titles = @[@"未完成", @"已完成"];
#endif
    self.segmentControl.selectedIndex = 0;
    
    __weak HomeworkSessionsContainerViewController *weakSelf = self;
    self.segmentControl.indexChangeHandler = ^(NSUInteger selectedIndex) {
#if TEACHERSIDE || MANAGERSIDE
#else
        if (selectedIndex == 0)
        {
            [self.rightFuncButton setTitle:@"" forState:UIControlStateNormal];
            [self.rightFuncButton setImage:[UIImage imageNamed:@"navbar_calendar"] forState:UIControlStateNormal];
            [self.rightFuncButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
            [self.rightFuncButton setImageEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
        }
        else
        {
            if (self.currentFliterType < self.fliterTitles.count) {
                
                [self.rightFuncButton setTitle:[self.fliterTitles objectAtIndex: self.currentFliterType] forState:UIControlStateNormal];
            }
            [self.rightFuncButton setImage:[UIImage imageNamed:@"icon_drop_small"] forState:UIControlStateNormal];
            [self.rightFuncButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -35, 0, 0)];
            [self.rightFuncButton setImageEdgeInsets:UIEdgeInsetsMake(0, 35, 0, 0)];
            
        }
#endif
        [weakSelf showChildPageViewControllerWithIndex:selectedIndex animated:YES shouldLocate:YES];
    };
    [self.customTitleView addSubview:self.segmentControl];
    [self.segmentControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.customTitleView);
    }];
    
    [self showChildPageViewControllerWithIndex:0 animated:NO shouldLocate:YES];
}

- (void)checkAppVersion
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    
    [PublicService requestAppUpgradeWithVersion:app_Version callback:^(Result *result, NSError *error) {
        if (error == nil && result)
        {
            AppVersion * appUpgraud = (AppVersion *)(result.userInfo);
            NSInteger currentVerIndex = [[app_Version stringByReplacingOccurrencesOfString:@"." withString:@""] integerValue];
            NSInteger newVerIndex =  [[appUpgraud.appVersion stringByReplacingOccurrencesOfString:@"." withString:@""] integerValue];
            if (newVerIndex > currentVerIndex)
            {
                [self createUpgraudAlert:appUpgraud];
            }
            
        }
    }];
}

- (void)createUpgraudAlert:(AppVersion *)appinfo
{

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"升级提示" message:appinfo.upgradeDes preferredStyle:UIAlertControllerStyleAlert];
    if (appinfo.upgradeType == 1)
    {
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"点击取消");
        }]];
    }
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSLog(@"点击确认");
        if (@available(iOS 10.0, *)) {
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appinfo.appUrl] options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appinfo.appUrl]];
        }
    }]];

    alertController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#if TEACHERSIDE || MANAGERSIDE
#else
    //处理朋友圈的小红点
    [CirlcleService requestCircleHomeworkFlagWithcallback:^(Result *result, NSError *error) {
        if (error == nil)
        {
            CircleHomeworkFlag * circleFlag = (CircleHomeworkFlag *)result.userInfo;
            
            if (circleFlag.schoolNotice > 0 || circleFlag.classNotice > 0)
            {
                AppDelegate * appDel = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDel showTabBarBadgeNum:-1 atIndex:1];
            }
        }
    }];
    
    //处理勋章小红点
    [AchieverService requestMedalNoticeFlagWithCallback:^(Result *result, NSError *error) {
        //只处理成功的情况
        if (error == nil)
        {
            MedalFlag * medel = (MedalFlag *)(result.userInfo);
            if (medel.metalFlag == 1)
            {
                self.redIncoinView.layer.cornerRadius = 4.0;
                self.redIncoinView.hidden = NO;
            }
            else
            {
                self.redIncoinView.hidden = YES;
            }
        }
    }];
#endif
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.everAppeared) {
#if TEACHERSIDE || MANAGERSIDE
#else
        if (APP.classIdAlertShown != APP.currentUser.clazz.classId) {
            NSString *message = [NSString stringWithFormat:@"你目前在\"%@\"", APP.currentUser.clazz.name];
            
            [AlertView showInView:self.tabBarController.view
                        withImage:[UIImage imageNamed:@"pop_img_welcome"]
                            title:@"欢迎加入minnie英文教室"
                          message:message
                           action:@"知道啦"
                   actionCallback:^{
                       [APP setClassIdAlertShown:APP.currentUser.clazz.classId];
                       
                       self.everAppeared = YES;
                   }];
        }
        
#endif
        
        self.everAppeared = YES;
    }
}

- (IBAction)leftFuncClick:(id)sender {
    
#if MANAGERSIDE
    // 重置选中任务状态
    if (self.popDetailVCCallBack) {
        self.popDetailVCCallBack();
    }
    [self.currentViewController resetCurrentSelectIndex];
#endif
    
#if TEACHERSIDE || MANAGERSIDE
    HomeworkSearchNameViewController * searchVc = [[HomeworkSearchNameViewController alloc] initWithNibName:NSStringFromClass([HomeworkSearchNameViewController class]) bundle:nil];
    searchVc.finished = self.currentIndex;
    [searchVc setHidesBottomBarWhenPushed:YES];
    searchVc.pushVCCallBack = self.pushVCCallBack;
    searchVc.cancelCallBack  = self.popDetailVCCallBack;
    searchVc.teacher = self.teacher;
    [self.navigationController pushViewController:searchVc animated:YES];
    
#else
    
    //点击勋章主动把小红点隐藏
    [AchieverService updateMedalNoticeFlagWithCallback:^(Result *result, NSError *error) {
        if (error == nil)
        {}
    }];
    AchieverListViewController * achiverVc = [[AchieverListViewController alloc] initWithNibName:NSStringFromClass([AchieverListViewController class]) bundle:nil];
    [achiverVc setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:achiverVc animated:YES];
#endif
    
}


- (IBAction)rightFuncClick:(id)sender {
    
#if MANAGERSIDE
    WeakifySelf;
    [FilterAlertView showInView:self.view atFliterType:self.currentFliterType forFliterArray:self.fliterTitles withAtionBlock:^(NSInteger index) {
        StrongifySelf;
        strongSelf.currentFliterType = index;
        [strongSelf.currentViewController requestSearchForSorceAtIndex:index];
    }];
    
    // 重置选中任务状态
    if (self.popDetailVCCallBack) {
        self.popDetailVCCallBack();
    }
    [self.currentViewController resetCurrentSelectIndex];
#elif TEACHERSIDE
    //显示搜索
    WeakifySelf;
    [FilterAlertView showInView:self.tabBarController.view atFliterType:self.currentFliterType forFliterArray:self.fliterTitles withAtionBlock:^(NSInteger index) {
        StrongifySelf;
        strongSelf.currentFliterType = index;
        [strongSelf.currentViewController requestSearchForSorceAtIndex:index];
    }];
#else
    
    if(self.segmentControl.selectedIndex == 0)
    {
        CalendarViewController *vc = [[CalendarViewController alloc] initWithNibName:@"CalendarViewController" bundle:nil];
        vc.clazz = APP.currentUser.clazz;
        [vc setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else
    {
        
        WeakifySelf;
        [FilterAlertView showInView:self.tabBarController.view atFliterType:self.currentFliterType forFliterArray:self.fliterTitles withAtionBlock:^(NSInteger index) {
            StrongifySelf;
            if (index < self.fliterTitles.count) {
            
                [strongSelf.rightFuncButton setTitle:[self.fliterTitles objectAtIndex:index] forState:UIControlStateNormal];
            }
            [strongSelf.rightFuncButton setImage:[UIImage imageNamed:@"icon_drop_small"] forState:UIControlStateNormal];
            [strongSelf.rightFuncButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -35, 0, 0)];
            [strongSelf.rightFuncButton setImageEdgeInsets:UIEdgeInsetsMake(0, 35, 0, 0)];
            strongSelf.currentFliterType = index;
            [strongSelf.finishedClassesChildController requestSearchForSorceAtIndex:index];
        }];
    }
#endif
}


#pragma mark - Private Method

- (void)showChildPageViewControllerWithIndex:(NSUInteger)index animated:(BOOL)animated shouldLocate:(BOOL)shouldLocate {
    
    HomeworkSessionsViewController *childPageViewController = nil;
    BOOL existed = YES;
#if MANAGERSIDE
    BOOL exchangedSession = NO;
    if (index != self.currentIndex) {
        exchangedSession = YES;
    }
#endif
    if (index == 0) {
        if (self.unfinishedClassesChildController == nil) {
            self.unfinishedClassesChildController = [[HomeworkSessionsViewController alloc] initWithNibName:NSStringFromClass([HomeworkSessionsViewController class]) bundle:nil];
            self.unfinishedClassesChildController.isUnfinished = YES;
            self.unfinishedClassesChildController.bLoadConversion = YES;
            self.unfinishedClassesChildController.searchFliter = self.currentFliterType;
            existed = NO;
        }
        self.unfinishedClassesChildController.teacher = self.teacher;
        self.unfinishedClassesChildController.pushVCCallBack = self.pushVCCallBack;
        childPageViewController = self.unfinishedClassesChildController;
    } else if (index == 1) {
        if (self.finishedClassesChildController == nil) {
            self.finishedClassesChildController = [[HomeworkSessionsViewController alloc] initWithNibName:NSStringFromClass([HomeworkSessionsViewController class]) bundle:nil];
            self.finishedClassesChildController.isUnfinished = NO;
            self.finishedClassesChildController.bLoadConversion = NO;
            self.finishedClassesChildController.searchFliter = self.currentFliterType;
            existed = NO;
        }
        self.finishedClassesChildController.teacher = self.teacher;
        self.finishedClassesChildController.pushVCCallBack = self.pushVCCallBack;
        childPageViewController = self.finishedClassesChildController;
    }
    else
    {
#if TEACHERSIDE || MANAGERSIDE
        if (self.uncommitClassesChildController == nil) {
            self.uncommitClassesChildController = [[HomeworkSessionsViewController alloc] initWithNibName:NSStringFromClass([HomeworkSessionsViewController class]) bundle:nil];
            self.uncommitClassesChildController.isUnfinished = YES;
            self.uncommitClassesChildController.bLoadConversion = NO;
            self.uncommitClassesChildController.searchFliter = self.currentFliterType;
            existed = NO;
        }
        
        self.uncommitClassesChildController.teacher = self.teacher;
        self.uncommitClassesChildController.pushVCCallBack = self.pushVCCallBack;
        childPageViewController = self.uncommitClassesChildController;
#else
#endif
    }
    
    self.currentViewController = childPageViewController;
    self.currentIndex = index;
    if (!existed) {
        [self addChildViewController:childPageViewController];
        
        [self.containerView addSubview:childPageViewController.view];
        [self addContraintsWithX:index*self.screenWidth view:childPageViewController.view superView:self.containerView];
        
        [childPageViewController didMoveToParentViewController:self];
    }
    
    if (shouldLocate) {
        CGPoint offset = CGPointMake(index*self.screenWidth, 0);
        
        if (animated) {
            self.ignoreScrollCallback = YES;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 [self.containerScrollView setContentOffset:offset];
                             } completion:^(BOOL finished) {
                                 self.ignoreScrollCallback = NO;
                             }];
        } else {
            // 说明：不使用dispatch_async的话viewDidLoad中直接调用[self.containerScrollView setContentOffset:offset];
            // 会导致contentoffset并未设置的问题
            dispatch_async(dispatch_get_main_queue(), ^{
                self.ignoreScrollCallback = YES;
                [self.containerScrollView setContentOffset:offset];
                self.ignoreScrollCallback = NO;
            });
        }
    }
    
#if MANAGERSIDE
    if (exchangedSession) {
     
        if (self.popDetailVCCallBack) {
            self.popDetailVCCallBack();
        }
        [childPageViewController resetCurrentSelectIndex];
    }
    [self updateChildPageViewControllerDataWithIndex:_currentIndex];
#endif
}

- (void)addContraintsWithX:(CGFloat)offsetX view:(UIView *)view superView:(UIView *)superView {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                         attribute:NSLayoutAttributeLeading
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:superView
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1
                                                                          constant:offsetX];
    
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1
                                                                        constant:self.screenWidth];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:superView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1
                                                                      constant:0];
    
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:superView
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1
                                                                         constant:0];
    
    [superView addConstraints:@[leadingConstraint, widthConstraint, topConstraint, bottomConstraint]];
}

- (void)updateSegmentControlWithOffsetX:(CGFloat)x {
    [self.segmentControl setPersent:x / self.screenWidth];
}

- (void)updateSegmentControlWhenScrollEnded {
    [self.segmentControl setPersent:self.containerScrollView.contentOffset.x / self.screenWidth];
    
    NSInteger index = MAX(0, ceil(self.segmentControl.titles.count * self.containerScrollView.contentOffset.x / self.screenWidth) - 1);
    [self indexDidChange:index];
}

- (void)indexDidChange:(NSInteger)index {
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.ignoreScrollCallback) {
        return;
    }
    CGFloat offsetX = scrollView.contentOffset.x;
    
    NSUInteger leftIndex = (NSInteger)MAX(0, offsetX)/(NSInteger)(self.screenWidth);
    NSUInteger rightIndex = (NSInteger)MAX(0, offsetX+self.screenWidth)/(NSInteger)(self.screenWidth);
    
    [self showChildPageViewControllerWithIndex:leftIndex animated:NO shouldLocate:NO];
    if (leftIndex != rightIndex) {
        [self showChildPageViewControllerWithIndex:rightIndex animated:NO shouldLocate:NO];
    }
    
    [self updateSegmentControlWithOffsetX:offsetX];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.ignoreScrollCallback) {
        return;
    }
    
    if (!decelerate) {
        [self updateSegmentControlWhenScrollEnded];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.ignoreScrollCallback) {
        return;
    }
    
    [self updateSegmentControlWhenScrollEnded];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (self.ignoreScrollCallback) {
        return;
    }
    
    [self updateSegmentControlWhenScrollEnded];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
#if TEACHERSIDE || MANAGERSIDE
    if (scrollView.contentOffset.x >= self.screenWidth * 2) {
        [scrollView setContentOffset:CGPointMake(self.screenWidth *2, 0) animated:YES];
        [self updateSegmentControlWhenScrollEnded];
    }
#endif
}
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
#if TEACHERSIDE || MANAGERSIDE
    if (scrollView.contentOffset.x >= self.screenWidth * 2) {
        [scrollView setContentOffset:CGPointMake(self.screenWidth *2, 0) animated:YES];
        [self updateSegmentControlWhenScrollEnded];
    }
#endif
}

#pragma mark - 管理端切换教师更新作业
- (void)updateHomeworkSessionWithTeacher:(Teacher *)teacher{
#if MANAGERSIDE
    
    _unfinishedNeedUpdate = YES;
    _finishedNeedUpdate = YES;
    _uncommitNeedUpdate = YES;
    
    self.teacher = teacher;
    [self showChildPageViewControllerWithIndex:_currentIndex animated:YES shouldLocate:YES];
#endif
}

- (void)updateChildPageViewControllerDataWithIndex:(NSInteger)index{

#if MANAGERSIDE
    if (index == 0) {
        if (_unfinishedNeedUpdate) {
            
            [self.unfinishedClassesChildController updateSessionList];
            _unfinishedNeedUpdate = NO;
        }
    } else if (index == 1) {
        
        if (_finishedNeedUpdate) {
            
            [self.finishedClassesChildController updateSessionList];
            _finishedNeedUpdate = NO;
        }
    }
    else
    {
        if (_uncommitNeedUpdate) {
            
            [self.uncommitClassesChildController updateSessionList];
            _uncommitNeedUpdate = NO;
        }
    }
#endif
}
@end




