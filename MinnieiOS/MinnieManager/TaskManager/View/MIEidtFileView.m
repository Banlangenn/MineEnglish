//
//  MIEidtFileView.m
//  MinnieManager
//
//  Created by songzhen on 2019/6/2.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "MIEidtFileView.h"

@interface MIEidtFileView ()

// 竖向分布
@property (weak, nonatomic) IBOutlet UIView *verticalView;
@property (weak, nonatomic) IBOutlet UIButton *topButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalLeftConstraint;


// 横向分布
@property (weak, nonatomic) IBOutlet UIView *horizontalView;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *horizontalTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *horizontalLeftContraint;


@property (nonatomic,assign) MIEidtFileViewStyle style;

@end

@implementation MIEidtFileView

- (void)awakeFromNib{
    
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
}

- (void)setupTextColor:(UIColor *)textColor
               bgColor:(UIColor *)bgColor
              oneTitle:(NSString *)oneTitle
              twoTitle:(NSString *)twoTitle
          cornerRadius:(CGFloat)radius
                offset:(CGPoint)offset
                 style:(MIEidtFileViewStyle)style{
    
    if (style == MIEidtFileViewVertical) {
        
        self.verticalView.hidden = NO;
        self.horizontalView.hidden = YES;
        self.verticalView.backgroundColor = bgColor;
        self.verticalView.layer.masksToBounds = YES;
        self.verticalView.layer.cornerRadius = radius;
        [self.topButton setTitle:oneTitle forState:UIControlStateNormal];
        [self.topButton setTitleColor:textColor forState:UIControlStateNormal];
        [self.bottomButton setTitle:twoTitle forState:UIControlStateNormal];
        [self.bottomButton setTitleColor:textColor forState:UIControlStateNormal];
        self.verticalTopConstraint.constant = offset.y;
        self.verticalLeftConstraint.constant = offset.x;
    } else {
       
        self.verticalView.hidden = YES;
        self.horizontalView.hidden = NO;
        self.horizontalView.backgroundColor = bgColor;
        self.horizontalView.layer.masksToBounds = YES;
        self.horizontalView.layer.cornerRadius = radius;
        [self.leftButton setTitle:oneTitle forState:UIControlStateNormal];
        [self.leftButton setTitleColor:textColor forState:UIControlStateNormal];
        [self.rightButton setTitle:twoTitle forState:UIControlStateNormal];
        [self.rightButton setTitleColor:textColor forState:UIControlStateNormal];
        self.horizontalTopConstraint.constant = offset.y;
        self.horizontalLeftContraint.constant = offset.x;
    }
}

- (IBAction)oneButtonAction:(id)sender {
    
    if (self.oneBtnCallback) {
        self.oneBtnCallback();
    }
    if (self.superview) {
        
        [self removeFromSuperview];
    }
}

- (IBAction)twoButtonAction:(id)sender {
    if (self.twoBtnCallBack) {
        self.twoBtnCallBack();
    }
    if (self.superview) {
        
        [self removeFromSuperview];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    if (self.superview) {
        
        [self removeFromSuperview];
    }
}

@end
