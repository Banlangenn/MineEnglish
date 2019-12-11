//
//  EntranceClassView.m
//  MinnieManager
//
//  Created by songzhen on 2019/12/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "EntranceClassView.h"

@interface EntranceClassView ()

@property (weak, nonatomic) IBOutlet UIView *inputBgView;

@property (weak, nonatomic) IBOutlet UITextField *inputTextField;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (nonatomic, copy) InviteCodeCallback callback;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;

@end


@implementation EntranceClassView


- (void)awakeFromNib {
   
    [super awakeFromNib];
    
    self.confirmButton.layer.cornerRadius = 12.f;
    self.confirmButton.layer.masksToBounds = YES;
    
    self.contentView.layer.cornerRadius = 12.f;
    self.contentView.layer.masksToBounds = YES;
    
    self.inputBgView.layer.cornerRadius = 5.f;
    self.inputBgView.layer.masksToBounds = YES;
}

+ (instancetype)sharedInstance {
    
    static EntranceClassView *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([EntranceClassView class]) owner:nil options:nil] lastObject];
    });
    
    return instance;
}


+ (void)showInSuperView:(UIView *)superView
               callback:(InviteCodeCallback)callback {
   
    EntranceClassView *view = [EntranceClassView sharedInstance];
    view.callback = callback;
    [view.inputTextField becomeFirstResponder];
    
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
    
    EntranceClassView *enrollView = [EntranceClassView sharedInstance];
    [enrollView.inputTextField resignFirstResponder];
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



- (IBAction)closeBtnPressed:(id)sender {
    
    [EntranceClassView hideAnimated:YES];
}

- (IBAction)entranceBtnPressed:(id)sender {
    
    if (self.inputTextField.text.length > 0) {

        if (self.callback) {
            self.callback(self.inputTextField.text);
        }
    }
}

- (IBAction)textFieldValueChanged:(id)sender {
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [self.inputTextField resignFirstResponder];
}

@end
