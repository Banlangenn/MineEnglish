//
//  CreateAwardViewController.m
//  X5Teacher
//
//  Created by yebw on 2017/12/26.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "CreateAwardViewController.h"
#import "AwardsService.h"
#import "FileUploader.h"
#import "Constants.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface CreateAwardViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UITextField *countTextField;
@property (nonatomic, weak) IBOutlet UITextField *priceTextField;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *scrollViewBottomConstraint;

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;
@property (nonatomic, weak) IBOutlet UIView *addImageView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (nonatomic, assign) BOOL imageChanged;

@end

@implementation CreateAwardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView.userInteractionEnabled = YES;
    self.addImageView.userInteractionEnabled = YES;
    if (self.award != nil) {
        self.customTitleLabel.text = @"编辑礼品";
        self.nameTextField.text = self.award.name;
        self.countTextField.text = [NSString stringWithFormat:@"%@", @(self.award.count)];
        self.priceTextField.text = [NSString stringWithFormat:@"%@", @(self.award.price)];

        CGFloat scrWidth = ScreenWidth;
#if MANAGERSIDE
        scrWidth = 375.0;
#endif
        self.imageViewHeightConstraint.constant = scrWidth;
        [self.imageView sd_setImageWithURL:[self.award.imageUrl imageURLWithWidth:scrWidth]];
    } else {
        self.customTitleLabel.text = @"新建礼品";
        self.imageViewHeightConstraint.constant = 0.f;
    }
#if MANAGERSIDE
    [self.closeButton setImage:[UIImage imageNamed:@"navbar_close"] forState:UIControlStateNormal];
#else
    [self.closeButton setImage:[UIImage imageNamed:@"navbar_back"] forState:UIControlStateNormal];
#endif
}

- (void)dealloc {
  
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}

#pragma mark - IBAction
- (void)backButtonPressed:(id)sender{

#if MANAGERSIDE
    if(self.closeViewCallBack) {
        self.closeViewCallBack();
    }
#else
    [self.navigationController popViewControllerAnimated:YES];
#endif
}
- (IBAction)addImageButtonPressed:(id)sender {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
#if MANAGERSIDE
    [self.view.window.rootViewController presentViewController:imagePickerController animated:YES completion:nil];
#else
    
    [self.navigationController presentViewController:imagePickerController animated:YES completion:nil];
#endif
}

- (IBAction)saveButtonPressed:(id)sender {
    NSString *name = [self.nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (name.length == 0) {
        [TIP showText:@"请输入礼物名称" inView:self.navigationController.view];
        return;
    }
    
    NSString *count = [self.countTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (count.length == 0) {
        [TIP showText:@"请输入礼物数量" inView:self.navigationController.view];
        return;
    }
    
    NSString *price = [self.priceTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (price.length == 0) {
        [TIP showText:@"请输入礼物价格" inView:self.navigationController.view];
        return;
    }
    
    UIImage *image = self.imageView.image;
    if (image == nil && self.award == nil) {
        [TIP showText:@"请添加礼物图片" inView:self.navigationController.view];
        return;
    }

    if (self.award==nil || self.imageChanged) {
        [HUD showProgressWithMessage:@"正在上传图片..."];
        NSData *imageData = UIImageJPEGRepresentation(image, .8f);
        QNUploadOption * option = [[QNUploadOption alloc] initWithProgressHandler:^(NSString *key, float percent) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传图片%.f%%...", percent * 100]];
            });
            
        }];
        [[FileUploader shareInstance] qn_uploadData:imageData type:UploadFileTypeImage option:option completionBlock:^(NSString * _Nullable imageUrl, NSError * _Nullable error) {
            if (imageUrl.length == 0) {
                [HUD showErrorWithMessage:@"图片上传失败"];
                return;
            }
            
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            if (self.award != nil) {
                info[@"id"] = @(self.award.awardId);
            }
            info[@"imageUrl"] = imageUrl;
            info[@"name"] = name;
            info[@"count"] = @([count integerValue]);
            info[@"price"] = @([price integerValue]);
            
            [self addAwardWithInfo:info];
        }];
    } else {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        if (self.award != nil) {
            info[@"id"] = @(self.award.awardId);
        }
        info[@"name"] = name;
        info[@"count"] = @([count integerValue]);
        info[@"price"] = @([price integerValue]);
        
        [self addAwardWithInfo:info];
    }
}

- (void)addAwardWithInfo:(NSDictionary *)info {
    [HUD showProgressWithMessage:@"正在新建礼物..."];
    
    [AwardsService addAward:info
                         callback:^(Result *result, NSError *error) {
                             if (error != nil) {
                                 [HUD showErrorWithMessage:@"创建礼物失败"];
                             } else {
                                 [HUD showWithMessage:@"礼物创建成功"];
                                 
                                 [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfAddAward object:nil];
                                 
                                 [self backButtonPressed:nil];
                             }
                         }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    self.imageChanged = YES;
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    self.imageView.image = image;
    
    CGFloat height = 0;
    CGFloat scrWidth = ScreenWidth;
#if MANAGERSIDE
    scrWidth = 375.0;
#endif
    
    if (image.size.width > 0) {
      height = scrWidth * image.size.height / image.size.width;
    }
    self.imageViewHeightConstraint.constant = height;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end


