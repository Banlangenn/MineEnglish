//
//  MICampusManagerViewController.m
//  MinnieManager
//
//  Created by songzhen on 2019/7/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "WMPageController.h"
#import "MIClassDetailViewController.h"
#import "MICampusManagerViewController.h"

@interface MICampusManagerViewController ()<
WMPageControllerDelegate,
WMPageControllerDataSource,
MIClassDetailViewControllerDelegate
>

@property (nonatomic, strong) UIView *rightLineView;

@property (nonatomic, strong) NSArray *subPageTitleArray;
@property (nonatomic, strong) NSMutableArray *subPageVCArray;


@property (nonatomic, strong) WMPageController *pageController;


@end

@implementation MICampusManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];

    self.subPageVCArray = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
      
        MIClassDetailViewController *classVC = [[MIClassDetailViewController alloc] init];
        classVC.delegate = self;
        [self.subPageVCArray addObject:classVC];
    }
    self.subPageTitleArray = @[@"武义校区", @"金华校区",@"杭州校区",@"武义校区", @"金华校区",@"杭州校区",@"武义校区", @"金华校区",@"杭州校区",@"杭州校区"];
    self.pageController = [[WMPageController alloc] initWithViewControllerClasses:self.subPageVCArray andTheirTitles:self.subPageTitleArray];
    self.pageController.delegate = self;
    self.pageController.dataSource = self;
    self.pageController.menuViewStyle = WMMenuViewStyleLine;
    self.pageController.titleSizeNormal = 14.0;
    self.pageController.titleSizeSelected = 14.0;
    self.pageController.progressWidth = 25.0;
    self.pageController.progressHeight = 4.0;
    self.pageController.progressViewCornerRadius = 2.0;
    self.pageController.menuItemWidth = 70;
    self.pageController.titleColorSelected = [UIColor mainColor];
    self.pageController.titleColorNormal = [UIColor detailColor];
    
    self.view.frame = CGRectMake(0, 0, (ScreenWidth - kRootModularWidth)/2.0, ScreenHeight);
    self.pageController.view.frame = CGRectMake(0, 20, (ScreenWidth - kRootModularWidth)/2.0, ScreenHeight - 20);
    [self.view addSubview:self.pageController.view];
    [self addChildViewController:self.pageController];
    [self.pageController didMoveToParentViewController:self];
    
    self.pageController.menuView.layoutMode = WMMenuViewLayoutModeCenter;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.titleLabel.font = [UIFont systemFontOfSize:14];
    [btn setTitleColor:[UIColor mainColor] forState:UIControlStateNormal];
    [btn setTitle:@"新建" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(createAction) forControlEvents:UIControlEventTouchUpInside];
    btn.frame = CGRectMake(0, 0, 40, 44);
    [self.pageController.menuView setRightView:btn];
    
    self.rightLineView = [[UIView alloc] initWithFrame:CGRectMake((ScreenWidth - kRootModularWidth)/2.0 - 0.5, 0, 0.5, ScreenHeight)];
    self.rightLineView.backgroundColor = [UIColor separatorLineColor];
    [self.view addSubview:self.rightLineView];
}


#pragma mark - WMPageControllerDelegate, WMPageControllerDataSource
-(NSInteger)numbersOfTitlesInMenuView:(WMMenuView *)menu{
    return self.subPageVCArray.count;
}

- (UIViewController *)pageController:(WMPageController *)pageController viewControllerAtIndex:(NSInteger)index{
    return self.subPageVCArray[index];
}

- (NSString *)pageController:(WMPageController *)pageController titleAtIndex:(NSInteger)index{
    return self.subPageTitleArray[index];
}
- (CGRect)pageController:(WMPageController *)pageController preferredFrameForMenuView:(WMMenuView *)menuView{
    
    return CGRectMake(0, 0, (ScreenWidth - kRootModularWidth)/2.0, 44);
}

- (void)pageController:(WMPageController *)pageController willEnterViewController:(__kindof UIViewController *)viewController withInfo:(NSDictionary *)info{
    
    NSLog(@"%@",viewController);
}

#pragma mark - MIClassDetailViewControllerDelegate 
- (void)classDetailViewControllerClickedIndex:(NSInteger)index clazz:(Clazz *)clazz{
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(campusManagerViewControllerEditClazz:)]) {
        [self.delegate campusManagerViewControllerEditClazz:clazz];
    }
}

- (IBAction)createClassAction:(id)sender {
 
    if (self.delegate && [self.delegate respondsToSelector:@selector(campusManagerViewControllerEditClazz:)]) {
        [self.delegate campusManagerViewControllerEditClazz:nil];
    }
}

- (void)createAction{
   
    if (self.delegate && [self.delegate respondsToSelector:@selector(campusManagerViewControllerEditClazz:)]) {
        [self.delegate campusManagerViewControllerEditClazz:nil];
    }
}
@end
