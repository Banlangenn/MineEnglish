//
//  EnrollTrialClassView.h
//  X5Teacher
//
//  Created by yebw on 2018/1/7.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "EnrollTrialClassView.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface EnrollTrialClassView()

@property (nonatomic, weak) IBOutlet UIView *backgroundView;
@property (nonatomic, weak) IBOutlet UIView *contentView;

@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UITextField *genderTextField;
@property (nonatomic, weak) IBOutlet UITextField *gradeTextField;

@property (nonatomic, weak) IBOutlet UIButton *confirmButton;
@property (nonatomic, copy) EnrollTrialViewConfirmCallback confirmCallback;

@end

@implementation EnrollTrialClassView

+ (instancetype)sharedInstance {
    static EnrollTrialClassView *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([EnrollTrialClassView class]) owner:nil options:nil] lastObject];
    });
    
    return instance;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.confirmButton.backgroundColor = nil;
    self.confirmButton.layer.cornerRadius = 12.f;
    self.confirmButton.layer.masksToBounds = YES;
    [self.confirmButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithHex:0x0098FE]] forState:UIControlStateNormal];
    [self.confirmButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithHex:0x0098FE alpha:0.8]] forState:UIControlStateHighlighted];
    
    self.contentView.layer.cornerRadius = 12.f;
    self.contentView.layer.masksToBounds = YES;
    
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.contentView addGestureRecognizer:gr];
}

- (IBAction)tap:(UIGestureRecognizer *)gr {
    [self.nameTextField resignFirstResponder];
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (void)showInSuperView:(UIView *)superView
               callback:(EnrollTrialViewConfirmCallback)callback {
    EnrollTrialClassView *view = [EnrollTrialClassView sharedInstance];
    if (view.superview != nil) {
        [view removeFromSuperview];
    }
    
    view.nameTextField.text = APP.currentUser.nickname;
    view.gradeTextField.text = APP.currentUser.grade;
    
    NSString *gender = nil;
    if (APP.currentUser.gender == -1) {
        gender = @"女";
    } else {
        gender = @"男";
    }
    view.genderTextField.text = gender;

    view.confirmCallback = callback;
    
    [superView addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(superView);
    }];
    
    [view showWithAnimation];
}

- (void)showWithAnimation {
    self.hidden = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hidden = NO;
        
        CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.duration = .3f;
        scaleAnimation.values = @[@0, @1];
        scaleAnimation.keyTimes = @[@0, @.3];
        scaleAnimation.repeatCount = 1;
        scaleAnimation.fillMode = kCAFillModeForwards;
        scaleAnimation.removedOnCompletion = NO;
        scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.contentView.layer addAnimation:scaleAnimation forKey:@"scaleAnimation"];
        
        self.backgroundView.alpha = 0.f;
        [UIView animateWithDuration:0.3 animations:^{
            self.backgroundView.alpha = 1.f;
        } completion:^(BOOL finished) {
        }];
    });
}

+ (void)hideAnimated:(BOOL)animated {
    EnrollTrialClassView *enrollView = [EnrollTrialClassView sharedInstance];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.duration = .3f;
        scaleAnimation.values = @[@1, @0];
        scaleAnimation.keyTimes = @[@0, @.3];
        scaleAnimation.repeatCount = 1;
        scaleAnimation.fillMode = kCAFillModeForwards;
        scaleAnimation.removedOnCompletion = NO;
        scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [enrollView.contentView.layer addAnimation:scaleAnimation forKey:@"scaleAnimation"];
        
        enrollView.backgroundView.alpha = 1.f;
        [UIView animateWithDuration:0.3 animations:^{
            enrollView.backgroundView.alpha = 0.f;
        } completion:^(BOOL finished) {
            [enrollView removeFromSuperview];
        }];
    });
}

- (IBAction)genderButtonPressed:(id)sender {
    
    // 适配ipad版本
    UIAlertControllerStyle alertStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        alertStyle = UIAlertControllerStyleActionSheet;
    } else {
        alertStyle = UIAlertControllerStyleAlert;
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil
                                                  message:nil
                                           preferredStyle:alertStyle];
    UIAlertAction *maleAction = [UIAlertAction actionWithTitle:@"男"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           self.genderTextField.text = @"男";
                                                       }];
    
    UIAlertAction *femaleAction = [UIAlertAction actionWithTitle:@"女"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             self.genderTextField.text = @"女";
                                                         }];
    
    [alertVC addAction:maleAction];
    [alertVC addAction:femaleAction];
    
    UIViewController *vc = (UIViewController *)(self.nextResponder.nextResponder);

    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [vc presentViewController:alertVC
                     animated:YES
                   completion:nil];
}

- (IBAction)gradeButtonPressed:(id)sender {
    // 适配ipad版本
    UIAlertControllerStyle alertStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        alertStyle = UIAlertControllerStyleActionSheet;
    } else {
        alertStyle = UIAlertControllerStyleAlert;
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil
                                                                     message:nil
                                                              preferredStyle:alertStyle];
    UIAlertAction *action0 = [UIAlertAction actionWithTitle:@"学前"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        self.gradeTextField.text = action.title;
                                                    }];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"小学一年级"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        self.gradeTextField.text = action.title;
                                                    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"小学二年级"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        self.gradeTextField.text = action.title;
                                                    }];
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"小学三年级"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        self.gradeTextField.text = action.title;
                                                    }];
    UIAlertAction *action4 = [UIAlertAction actionWithTitle:@"小学四年级"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        self.gradeTextField.text = action.title;
                                                    }];
    UIAlertAction *action5 = [UIAlertAction actionWithTitle:@"小学五年级"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        self.gradeTextField.text = action.title;
                                                    }];
    UIAlertAction *action6 = [UIAlertAction actionWithTitle:@"小学六年级"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        self.gradeTextField.text = action.title;
                                                    }];
    
    UIAlertAction *action7 = [UIAlertAction actionWithTitle:@"初中一年级"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        self.gradeTextField.text = action.title;
                                                    }];
    
    UIAlertAction *action8 = [UIAlertAction actionWithTitle:@"初中二年级"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        self.gradeTextField.text = action.title;
                                                    }];
    
    UIAlertAction *action9 = [UIAlertAction actionWithTitle:@"初中三年级"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        self.gradeTextField.text = action.title;
                                                    }];
    
    
    [alertVC addAction:action0];
    [alertVC addAction:action1];
    [alertVC addAction:action2];
    [alertVC addAction:action3];
    [alertVC addAction:action4];
    [alertVC addAction:action5];
    [alertVC addAction:action6];
    [alertVC addAction:action7];
    [alertVC addAction:action8];
    [alertVC addAction:action9];
    
    UIViewController *vc = (UIViewController *)(self.nextResponder.nextResponder);

    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [vc presentViewController:alertVC
                     animated:YES
                   completion:nil];
}

- (IBAction)closeButtonPressed:(id)sender {
    [EnrollTrialClassView hideAnimated:YES];
}

- (IBAction)confirmButtonPressed:(id)sender {
    NSString *name = [self.nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (name.length == 0) {
        [HUD showErrorWithMessage:@"请输入姓名"];
        
        return;
    }
    
    NSString *grade = [self.gradeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (grade.length == 0) {
        [HUD showErrorWithMessage:@"请选择年级"];
        
        return;
    }
    
    NSInteger gender = 0;
    if ([self.genderTextField.text isEqualToString:@"男"]) {
        gender = 1;
    } else if ([self.genderTextField.text isEqualToString:@"女"]) {
        gender = -1;
    }

    if (self.confirmCallback != nil) {
        self.confirmCallback(name, grade, gender);
    }
}

@end

