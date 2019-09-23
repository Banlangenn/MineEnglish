//
//  EditContentViewController.m
//  MinnieStudent
//
//  Created by songzhen on 2019/5/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "StudentService.h"
#import "StudentAwardService.h"
#import "EditContentViewController.h"

@interface EditContentViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet UIButton *saveBtn;

@property (nonatomic, assign) EditContentType editType;

// 转发
@property (nonatomic, assign) NSInteger hometaskId;
@property (nonatomic, assign) NSInteger homeworkId;
@property (nonatomic, assign) NSInteger teacherId;

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
    
    
    if (self.editType == EditContentType_StuRemark) {
        self.titleLabel.text = @"编辑备注";
        [self.saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    } else {
        self.titleLabel.text = @"问题备注";
        [self.saveBtn setTitle:@"提交" forState:UIControlStateNormal];
    }
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
        
        [StudentService requestTroubleTaskWithHomeaskId:self.hometaskId
                                             homeworkId:self.homeworkId
                                                 userId:self.userId
                                              teacherId:self.teacherId
                                                content:self.textView.text
                                               callback:^(Result *result, NSError *error) {
            if (error != nil) {
                
                [HUD showErrorWithMessage:@"转发问题作业失败"];
                return ;
            }
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }];
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
}

- (void)setupWithHometaskId:(NSInteger)hometaskId
                 homeworkId:(NSInteger)homeworkId
                     userId:(NSInteger)userId
                  teacherId:(NSInteger)teacherId{
    
    self.hometaskId = hometaskId;
    self.homeworkId = homeworkId;
    self.userId = userId;
    self.teacherId = teacherId;
}
@end
