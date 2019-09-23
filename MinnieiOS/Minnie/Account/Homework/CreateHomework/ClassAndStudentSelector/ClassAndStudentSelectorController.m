//
//  ClassAndStudentSelectorController.m
//  X5Teacher
//
//  Created by yebw on 2017/12/27.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "ClassAndStudentSelectorController.h"
#import "ClassSelectorViewController.h"
#import "StudentSelectorViewController.h"
#import "SegmentControl.h"
#import "Constants.h"
#import "TeacherService.h"
#import "SelectTeacherView.h"
#import "HomeworkService.h"
#import <Masonry/Masonry.h>
#import "PushManager.h"
#import "HomeworkConfirmViewController.h"

@interface ClassAndStudentSelectorController ()

@property (nonatomic, strong) ClassSelectorViewController *classSelectorChildController;
@property (nonatomic, strong) StudentSelectorViewController *studentSelectorChildController;

@property (nonatomic, assign) BOOL ignoreScrollCallback;

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UIScrollView *containerScrollView;
@property (nonatomic, weak) IBOutlet UIView *customTitleView;
@property (nonatomic, weak) IBOutlet UIButton *sendButton;
@property (nonatomic, weak) SegmentControl *segmentControl;

@property (nonatomic, strong) NSArray *teachers;

@property (nonatomic, assign) NSInteger selectedClassesCount;
@property (nonatomic, assign) NSInteger selectedStudentsCount;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightLayoutConstraint;

@end

@implementation ClassAndStudentSelectorController

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sendButton.enabled = NO;
    
    if (isIPhoneX) {
        self.heightLayoutConstraint.constant = -(44 + [UIApplication sharedApplication].statusBarFrame.size.height);
    }
    
    self.segmentControl = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SegmentControl class]) owner:nil options:nil] lastObject];
    self.segmentControl.titles = @[@"班级", @"个人"];
    self.segmentControl.selectedIndex = 0;
    
    __weak typeof(self) weakSelf = self;
    self.segmentControl.indexChangeHandler = ^(NSUInteger selectedIndex) {
        [weakSelf showChildPageViewControllerWithIndex:selectedIndex animated:YES shouldLocate:YES];
    };
    [self.customTitleView addSubview:self.segmentControl];
    [self.segmentControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.customTitleView);
    }];
    
    [self showChildPageViewControllerWithIndex:0 animated:NO shouldLocate:YES];
    
    [self requestTeachers];
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

#pragma mark - IBActions

- (IBAction)backButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendButtonPressed:(id)sender{
    
    if (_isCreateActivityTask) {
        
        if (self.studentSelectorChildController.selectedStudents.count > 0 &&
            [self.delegate respondsToSelector:@selector(studentsDidSelect:)]) {
            [self.delegate studentsDidSelect:self.studentSelectorChildController.selectedStudents];
        }
        
        if (self.classSelectorChildController.selectedClasses.count > 0 &&
            [self.delegate respondsToSelector:@selector(classesDidSelect:)]) {
            [self.delegate classesDidSelect:self.classSelectorChildController.selectedClasses];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        if (self.homeworks.count == 0) { // 说明是发送消息的
            if (self.studentSelectorChildController.selectedStudents.count > 0 &&
                [self.delegate respondsToSelector:@selector(studentsDidSelect:)]) {
                [self.delegate studentsDidSelect:self.studentSelectorChildController.selectedStudents];
            }
            
            if (self.classSelectorChildController.selectedClasses.count > 0 &&
                [self.delegate respondsToSelector:@selector(classesDidSelect:)]) {
                [self.delegate classesDidSelect:self.classSelectorChildController.selectedClasses];
            }
            
            return;
        }
        
        if (self.teachers.count == 0) {
            [self requestTeachers];
            
            return;
        }
        
        WeakifySelf;
        [SelectTeacherView showInSuperView:self.view
                                  teachers:self.teachers
                                  callback:^(Teacher *teacher, NSDate *date) {
                                      
                                      [SelectTeacherView hideAnimated:NO];
                                      
                                      HomeworkConfirmViewController *vc = [[HomeworkConfirmViewController alloc] init];
                                      vc.classes = weakSelf.classSelectorChildController.selectedClasses;
                                      vc.homeworks = weakSelf.homeworks;
                                      vc.students = weakSelf.studentSelectorChildController.selectedStudents;
                                      vc.teacher = teacher;
                                      [weakSelf.navigationController presentViewController:vc animated:YES completion:nil];
                                  } cancelback:nil];
    }
}

#pragma mark - Private Method

- (void)requestTeachers {
    [TeacherService requestTeachersWithCallback:^(Result *result, NSError *error) {
        if (error != nil) {
            [HUD showErrorWithMessage:@"教师获取失败"];
            return;
        }
        
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        
        self.teachers = (NSArray *)(dict[@"list"]);
    }];
}

- (void)showChildPageViewControllerWithIndex:(NSUInteger)index animated:(BOOL)animated shouldLocate:(BOOL)shouldLocate {
    BaseViewController *childPageViewController = nil;
    BOOL existed = YES;
    
    if (index == 0) {
        if (self.classSelectorChildController == nil) {
            self.classSelectorChildController = [[ClassSelectorViewController alloc] initWithNibName:NSStringFromClass([ClassSelectorViewController class]) bundle:nil];
            existed = NO;
            
            WeakifySelf;
            self.classSelectorChildController.selectCallback = ^(NSInteger count) {
                weakSelf.selectedClassesCount = count;
                
                [weakSelf.studentSelectorChildController unselectAll];
                
                if (weakSelf.selectedClassesCount==0 && weakSelf.selectedStudentsCount==0) {
                    weakSelf.sendButton.enabled = NO;
                } else {
                    weakSelf.sendButton.enabled = YES;
                }
            };
        }
        childPageViewController = self.classSelectorChildController;
    } else if (index == 1) {
        if (self.studentSelectorChildController == nil) {
            self.studentSelectorChildController = [[StudentSelectorViewController alloc] initWithNibName:NSStringFromClass([StudentSelectorViewController class]) bundle:nil];
            existed = NO;
            
            WeakifySelf;
            self.studentSelectorChildController.selectCallback = ^(NSInteger count) {
                weakSelf.selectedStudentsCount = count;
                
                [weakSelf.classSelectorChildController unselectAll];
                
                if (weakSelf.selectedClassesCount==0 && weakSelf.selectedStudentsCount==0) {
                    weakSelf.sendButton.enabled = NO;
                } else {
                    weakSelf.sendButton.enabled = YES;
                }
            };
        }
        
        childPageViewController = self.studentSelectorChildController;
    }
    
    if (!existed) {
        [self addChildViewController:childPageViewController];
        
        [self.containerView addSubview:childPageViewController.view];
        [self addContraintsWithX:index*ScreenWidth view:childPageViewController.view superView:self.containerView];
        
        [childPageViewController didMoveToParentViewController:self];
    }
    
    if (shouldLocate) {
        CGPoint offset = CGPointMake(index*ScreenWidth, 0);
        
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

- (void)updateSegmentControlWithOffsetX:(CGFloat)x {
    [self.segmentControl setPersent:x / ScreenWidth];
}

- (void)updateSegmentControlWhenScrollEnded {
    [self.segmentControl setPersent:self.containerScrollView.contentOffset.x / ScreenWidth];
    
    NSInteger index = MAX(0, ceil(2 * self.containerScrollView.contentOffset.x / ScreenWidth) - 1);
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
    NSUInteger leftIndex = (NSInteger)MAX(0, offsetX)/(NSInteger)(ScreenWidth);
    NSUInteger rightIndex = (NSInteger)MAX(0, offsetX+ScreenWidth)/(NSInteger)(ScreenWidth);
    
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

@end


