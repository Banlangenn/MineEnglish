//
//  MessagesViewController.m
//  X5
//
//  Created by yebw on 2017/9/12.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "MessagesViewController.h"
#import "NoticeMessagesViewController.h"
#import "CommentMessagesViewController.h"
#if TEACHERSIDE
#import "MessageEditorViewController.h"
#endif
#import "SegmentControl.h"
#import "Constants.h"
#import <Masonry/Masonry.h>

@interface MessagesViewController ()

@property (nonatomic, strong) NoticeMessagesViewController *noticeMessagesChildController;
@property (nonatomic, strong) CommentMessagesViewController *commentMessagesChildController;

@property (nonatomic, assign) BOOL ignoreScrollCallback;

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UIScrollView *containerScrollView;
@property (nonatomic, weak) IBOutlet UIView *customTitleView;
@property (nonatomic, weak) IBOutlet UIButton *createButton;
@property (nonatomic, weak) SegmentControl *segmentControl;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightLayoutConstraint;

@end

@implementation MessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if TEACHERSIDE
    self.createButton.hidden = !APP.currentUser.canCreateNoticeMessage;
#else
    self.createButton.hidden = YES;
#endif
    
    if (isIPhoneX) {
        self.heightLayoutConstraint.constant = -(44 + [UIApplication sharedApplication].statusBarFrame.size.height);
    }
    
    self.segmentControl = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SegmentControl class]) owner:nil options:nil] lastObject];
    self.segmentControl.titles = @[@"通知", @"评论"];
    self.segmentControl.selectedIndex = 0;
    
    __weak MessagesViewController *weakSelf = self;
    self.segmentControl.indexChangeHandler = ^(NSUInteger selectedIndex) {
        [weakSelf showChildPageViewControllerWithIndex:selectedIndex animated:YES shouldLocate:YES];
        
        [weakSelf indexDidChange:selectedIndex];
    };
    [self.customTitleView addSubview:self.segmentControl];
    [self.segmentControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.customTitleView);
    }];
    
    [self showChildPageViewControllerWithIndex:0 animated:NO shouldLocate:YES];
}

- (void)dealloc {
    
}

#pragma mark - IBActions

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)createButtonPressed:(id)sender {
#if TEACHERSIDE
    if (!APP.currentUser.canCreateNoticeMessage) {
        [HUD showErrorWithMessage:@"误操作权限"];
        
        return;
    }
    
    MessageEditorViewController *editorVC = [[MessageEditorViewController alloc] initWithNibName:@"MessageEditorViewController" bundle:nil];
    [self.navigationController pushViewController:editorVC animated:YES];
#endif
}

#pragma mark - Private Method

- (void)showChildPageViewControllerWithIndex:(NSUInteger)index animated:(BOOL)animated shouldLocate:(BOOL)shouldLocate {
    BaseViewController *childPageViewController = nil;
    BOOL existed = YES;
    
    if (index == 0) {
        if (self.noticeMessagesChildController == nil) {
            self.noticeMessagesChildController = [[NoticeMessagesViewController alloc] initWithNibName:NSStringFromClass([NoticeMessagesViewController class]) bundle:nil];
            existed = NO;
        }
        
        childPageViewController = self.noticeMessagesChildController;
    } else if (index == 1) {
        if (self.commentMessagesChildController == nil) {
            self.commentMessagesChildController = [[CommentMessagesViewController alloc] initWithNibName:NSStringFromClass([CommentMessagesViewController class]) bundle:nil];
            existed = NO;
        }
        
        childPageViewController = self.commentMessagesChildController;
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
#if TEACHERSIDE
    self.createButton.hidden = index!=0 || !APP.currentUser.canCreateNoticeMessage;
#endif
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



