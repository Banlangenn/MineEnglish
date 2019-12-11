//
//  StudentsWithoutClassViewController.m
//  X5Teacher
//
//  Created by yebw on 2017/12/27.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "Constants.h"
#import "PushManager.h"
#import "SegmentControl.h"
#import <Masonry/Masonry.h>
#import "SearchStudentsViewController.h"
#import "StudentDetailViewController.h"
#import "StudentSelectorViewController.h"
#import "StudentsWithoutClassViewController.h"
#import <WMPageController/WMPageController.h>


@interface StudentsWithoutClassViewController ()<
WMPageControllerDelegate,
WMPageControllerDataSource
>

@property (nonatomic, assign) BOOL ignoreScrollCallback;

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UIView *customTitleView;

@property (nonatomic, assign) NSInteger selectedStudentsCount;

@property (nonatomic, strong) WMPageController *pageController;

@property (nonatomic, strong) NSMutableArray *pages;
@property (nonatomic, strong) NSMutableArray *pageTitles;

@end

@implementation StudentsWithoutClassViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    StudentSelectorViewController *unEnrollVC = [[StudentSelectorViewController alloc] initWithNibName:NSStringFromClass([StudentSelectorViewController class]) bundle:nil];
    unEnrollVC.reviewMode = NO;
    unEnrollVC.classStateMode = YES;
    unEnrollVC.inClass = 0;
    WeakifySelf;
    unEnrollVC.selectCallback = ^(NSInteger count) {
        weakSelf.selectedStudentsCount = count;
    };

    
    StudentSelectorViewController *onHandVC = [[StudentSelectorViewController alloc] initWithNibName:NSStringFromClass([StudentSelectorViewController class]) bundle:nil];
    onHandVC.reviewMode = NO;
    onHandVC.classStateMode = YES;
    onHandVC.inClass = -1;
    onHandVC.selectCallback = ^(NSInteger count) {
        weakSelf.selectedStudentsCount = count;
    };
    
    self.pages = [NSMutableArray arrayWithObjects:unEnrollVC,onHandVC, nil];
    self.pageTitles = [NSMutableArray arrayWithObjects:@"未入学",@"待处理", nil];
    
    [self configureUI];
}

- (void)configureUI{
    
    [self.view addSubview:self.pageController.view];
    [self addChildViewController:self.pageController];
    [self.pageController didMoveToParentViewController:self];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageNamed:@"navbar_close"] forState:UIControlStateNormal];
    [self.view addSubview:closeBtn];
    closeBtn.frame = CGRectMake(10, kNaviBarHeight - 40, 40, 40);
    [closeBtn addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    addBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    addBtn.frame = CGRectMake(ScreenWidth - 45, kNaviBarHeight - 40, 40, 40);
    [addBtn setTitle:@"添加" forState:UIControlStateNormal];
    [addBtn setTitleColor:[UIColor mainColor] forState:UIControlStateNormal];
    [addBtn addTarget:self action:@selector(addButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addBtn];
    
    
    UIButton *searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    searchBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    searchBtn.frame = CGRectMake(ScreenWidth - 90, kNaviBarHeight - 40, 40, 40);
    [searchBtn setTitle:@"搜索" forState:UIControlStateNormal];
    [searchBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [searchBtn addTarget:self action:@selector(searchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:searchBtn];
}

#pragma mark - IBActions
- (void)backButtonPressed:(UIButton *)btn{
 
#if MANAGERSIDE
    [self.navigationController popViewControllerAnimated:YES];
#else
    [self dismissViewControllerAnimated:YES completion:nil];
#endif
}
    
- (void)addButtonPressed:(UIButton *)btn{

    if (self.selectedStudentsCount == 0) {
        return;
    }
    StudentSelectorViewController *vc = (StudentSelectorViewController *)self.pageController.currentViewController;
    NSArray *selectedStudents = vc.selectedStudents;
    
    if ([self.delegate respondsToSelector:@selector(studentsDidSelect:)]) {
        [self.delegate studentsDidSelect:selectedStudents];
    }
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
- (void)searchButtonPressed:(UIButton *)btn{

    SearchStudentsViewController *searchStudents = [[SearchStudentsViewController alloc] initWithNibName:NSStringFromClass([SearchStudentsViewController class]) bundle:nil];
    
    StudentSelectorViewController *vc = (StudentSelectorViewController *)self.pageController.currentViewController;
    searchStudents.students = vc.students;
    WeakifySelf;
    searchStudents.addCallBack = ^(NSArray * _Nonnull array) {
      
        if ([weakSelf.delegate respondsToSelector:@selector(studentsDidSelect:)]) {
            [weakSelf.delegate studentsDidSelect:array];
        }
        NSLog(@"%@",weakSelf.navigationController.viewControllers);
        #if MANAGERSIDE
            [weakSelf.navigationController popViewControllerAnimated:YES];
        #else
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        #endif
    };
    [self.navigationController pushViewController:searchStudents animated:YES];
}

- (WMPageController *)pageController{
    
    if (!_pageController) {
        
        _pageController = [[WMPageController alloc] initWithViewControllerClasses:self.pages andTheirTitles:self.pageTitles];
        
        _pageController.delegate = self;
        _pageController.dataSource = self;
        _pageController.menuViewStyle = WMMenuViewStyleLine;
        _pageController.titleSizeNormal = 16.0;
        _pageController.titleSizeSelected = 16.0;
        _pageController.progressWidth = 25.0;
        _pageController.progressHeight = 4.0;
        _pageController.progressViewCornerRadius = 2.0;
        _pageController.menuItemWidth = 50;
        _pageController.titleColorSelected = [UIColor mainColor];
        _pageController.titleColorNormal = [UIColor detailColor];
        _pageController.progressViewIsNaughty = YES;
        _pageController.view.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    }
    return _pageController;
}

#pragma mark - WMPageControllerDelegate, WMPageControllerDataSource
-(NSInteger)numbersOfTitlesInMenuView:(WMMenuView *)menu{
    return 2;
}

- (UIViewController *)pageController:(WMPageController *)pageController viewControllerAtIndex:(NSInteger)index{
    return self.pages[index];
}

- (NSString *)pageController:(WMPageController *)pageController titleAtIndex:(NSInteger)index{
    return self.pageTitles[index];
}

- (CGRect)pageController:(WMPageController *)pageController preferredFrameForMenuView:(WMMenuView *)menuView{
    
    return CGRectMake((ScreenWidth - 140)/2.0, kNaviBarHeight - 40, 140 , 40);
}

@end

