//
//  StudentsWithoutClassViewController.m
//  X5Teacher
//
//  Created by yebw on 2017/12/27.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "StudentsWithoutClassViewController.h"
#import "StudentSelectorViewController.h"
#import "SegmentControl.h"
#import "Constants.h"
#import "StudentDetailViewController.h"
#import <Masonry/Masonry.h>
#import "PushManager.h"

@interface StudentsWithoutClassViewController ()

@property (nonatomic, strong) StudentSelectorViewController *studentsSelectorChildController;

@property (nonatomic, assign) BOOL ignoreScrollCallback;

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UIView *customTitleView;

@property (nonatomic, assign) NSInteger selectedStudentsCount;

@end

@implementation StudentsWithoutClassViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addChildPageViewController];
}

- (void)dealloc {
    
}

#pragma mark - IBActions

- (IBAction)backButtonPressed:(id)sender {
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)addButtonPressed:(id)sender {
    if (self.selectedStudentsCount == 0) {
        return;
    }
    
    NSArray *selectedStudents = self.studentsSelectorChildController.selectedStudents;
    
    if ([self.delegate respondsToSelector:@selector(studentsDidSelect:)]) {
        [self.delegate studentsDidSelect:selectedStudents];
    }
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)addChildPageViewController {
    BaseViewController *childPageViewController = nil;
    
    if (self.studentsSelectorChildController == nil) {
        self.studentsSelectorChildController = [[StudentSelectorViewController alloc] initWithNibName:NSStringFromClass([StudentSelectorViewController class]) bundle:nil];
        self.studentsSelectorChildController.reviewMode = NO;
        self.studentsSelectorChildController.classStateMode = YES;
        self.studentsSelectorChildController.inClass = 0;

        WeakifySelf;
        self.studentsSelectorChildController.selectCallback = ^(NSInteger count) {
            weakSelf.selectedStudentsCount = count;
        };
        
        self.studentsSelectorChildController.previewCallback = ^(NSInteger userId) {
            StudentDetailViewController *vc = [[StudentDetailViewController alloc] initWithNibName:@"StudentDetailViewController" bundle:nil];
            vc.userId = userId;
            
            [weakSelf.navigationController pushViewController:vc animated:YES];
        };
    }
    
    childPageViewController = self.studentsSelectorChildController;
    [self addChildViewController:childPageViewController];
    
    [self.containerView addSubview:childPageViewController.view];
    [self addContraintsWithX:0 view:childPageViewController.view superView:self.containerView];
    
    [childPageViewController didMoveToParentViewController:self];
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
                                                                        constant:ScreenWidth];
    
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

@end

