//
//  EditContentViewController.m
//  MinnieStudent
//
//  Created by songzhen on 2019/5/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "StudentAwardService.h"
#import "EditContentViewController.h"

@interface EditContentViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet UIButton *saveBtn;

@property (nonatomic, assign) EditContentType editType;

@end

@implementation EditContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.textView becomeFirstResponder];
    self.textView.layer.cornerRadius = 10.0;
    self.textView.layer.masksToBounds = YES;
    self.textView.layer.borderWidth = 1.0;
    self.textView.layer.borderColor = [UIColor colorWithHex:0xECECEC].CGColor;
}
- (IBAction)backAction:(id)sender {
    
    [self.textView resignFirstResponder];
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)saveAction:(id)sender {
    WeakifySelf;
    [self.textView resignFirstResponder];
    
    if (self.editType == EditContentType_StuRemark) {
      
        [StudentAwardService requestStudentRemarkWithStudentId:self.userId stuRemark:self.textView.text callback:^(Result *result, NSError *error) {
            if (error != nil) {
                
                [HUD showErrorWithMessage:@"编辑备注失败"];
                return ;
            }
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }];
    } else {
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [self.textView resignFirstResponder];
}


- (void)setupEditContentType:(EditContentType)editType
                 placeholder:(NSString *)placeholder
                     content:(NSString *)content{
    
    self.editType = editType;
    self.textView.text = content;
    if (self.editType == EditContentType_StuRemark) {
        self.titleLabel.text = @"编辑备注";
        [self.saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    } else {
        self.titleLabel.text = @"问题备注";
        [self.saveBtn setTitle:@"提交" forState:UIControlStateNormal];
    }
    
}
@end
