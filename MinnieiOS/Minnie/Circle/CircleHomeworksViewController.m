//
//  CircleHomeworksViewController.m
//  X5
//
//  Created by yebw on 2017/12/12.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import <Masonry/Masonry.h>
#import "CircleViewController.h"
#import "CircleHomeworksViewController.h"
#import "ClassManagerViewController.h"

@interface CircleHomeworksViewController ()

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, strong) CircleViewController *circleChildController;
@property (weak, nonatomic) IBOutlet UIButton *editBtn;

@end

@implementation CircleHomeworksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.clazz != 0) { // 班级
        self.customTitleLabel.text = self.clazz.name;
#if MANAGERSIDE
        self.editBtn.hidden = NO;
#endif
    } else { // 学生
        if (APP.currentUser.userId == self.userId) {
            self.customTitleLabel.text = @"我发布的";
        }
        else
        {
            self.customTitleLabel.text = self.userName;
        }
    }

    if (self.circleChildController == nil) {
        self.circleChildController = [[CircleViewController alloc] initWithNibName:NSStringFromClass([CircleViewController class]) bundle:nil];
        if (self.clazz == 0)
        {
            self.circleChildController.bSkipAvater = YES;
        }
        self.circleChildController.userId = self.userId;
        self.circleChildController.classId = self.clazz.classId;
    }
    
    [self addChildViewController:self.circleChildController];
    [self.containerView addSubview:self.circleChildController.view];
    [self.circleChildController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    [self.circleChildController didMoveToParentViewController:self];
}
- (IBAction)editBtnAction:(id)sender {
    
#if MANAGERSIDE
        ClassManagerViewController *classManagerVC = [[ClassManagerViewController alloc] initWithNibName:@"ClassManagerViewController" bundle:nil];
        WeakifySelf;
        classManagerVC.successCallBack = ^{
            if (weakSelf.editSuccessCallBack) {
                weakSelf.editSuccessCallBack();
            }
        };
        classManagerVC.classId = self.clazz.classId;
        [self.navigationController pushViewController:classManagerVC animated:YES];
#endif
}

- (void)backButtonPressed:(id)sender{
    
    [self.navigationController popViewControllerAnimated:YES];
    
#if MANAGERSIDE
    if (self.cancelCallBack) {
        self.cancelCallBack();
    }
#endif
}


@end

