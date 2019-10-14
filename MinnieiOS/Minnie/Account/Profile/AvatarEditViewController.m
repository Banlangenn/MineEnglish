//
//  AvatarEditViewController.m
//  X5
//
//  Created by yebw on 2017/9/13.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "AvatarEditViewController.h"
#import "UIColor+HEX.h"
#import "ProfileService.h"
#import "Application.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "FileUploader.h"

@interface AvatarEditViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, weak) IBOutlet UIButton *changeButton;

@end

@implementation AvatarEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.avatarImageView.layer.cornerRadius = 12.f;
    self.avatarImageView.layer.masksToBounds = YES;
    
    self.changeButton.layer.cornerRadius = 12.f;
    self.changeButton.layer.masksToBounds = YES;
    self.changeButton.layer.borderWidth = 0.5;
    self.changeButton.layer.borderColor = [UIColor colorWithHex:0x0098FE].CGColor;
    
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:APP.currentUser.avatarUrl]];
}

- (void)dealloc {
    
}

#pragma mark - IBActions

- (IBAction)changeButtonPressed {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    NSData *imageData = UIImageJPEGRepresentation(image, .8f);
    
    [picker dismissViewControllerAnimated:YES completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [HUD showProgressWithMessage:@"正在上传图片..."];
            QNUploadOption * option = [[QNUploadOption alloc] initWithProgressHandler:^(NSString *key, float percent) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传图片%.f%%...", percent * 100]];
                });
                
            }];
            
            [[FileUploader shareInstance] qn_uploadData:imageData type:UploadFileTypeImage option:option completionBlock:^(NSString * _Nullable avatarUrl, NSError * _Nullable error) {
                if (avatarUrl.length == 0) {
                    [HUD showErrorWithMessage:@"图片上传失败"];
                    
                    return;
                }
                
                [HUD showProgressWithMessage:@"正在修改头像..."];
                [ProfileService updateAvatar:avatarUrl
                                    callback:^(Result *result, NSError *error) {
                                        if (error != nil) {
                                            [HUD showErrorWithMessage:@"头像修改失败"];
                                        } else {
                                            [HUD showWithMessage:@"头像修改成功"];
                                            
#if TEACHERSIDE
                                            Teacher *teacher = APP.currentUser;
                                            teacher.avatarUrl = avatarUrl;
                                            APP.currentUser = teacher;
#else
                                            Student *student = APP.currentUser;
                                            student.avatarUrl = avatarUrl;
                                            APP.currentUser = student;
#endif
                                            
                                            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfProfileUpdated object:nil];
                                            
                                            [self backButtonPressed:nil];
                                        }
                                    }];
            }];
            
//            [[FileUploader shareInstance] uploadData:imageData
//                                type:UploadFileTypeImage
//                       progressBlock:^(NSInteger number) {
//                           [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传图片%@%%...", @(number)]];
//                       }
//                     completionBlock:^(NSString * _Nullable avatarUrl, NSError * _Nullable error) {
//                         if (avatarUrl.length == 0) {
//                             [HUD showErrorWithMessage:@"图片上传失败"];
//                             
//                             return;
//                         }
//                         
//                         [HUD showProgressWithMessage:@"正在修改头像..."];
//                         [ProfileService updateAvatar:avatarUrl
//                                             callback:^(Result *result, NSError *error) {
//                                                 if (error != nil) {
//                                                     [HUD showErrorWithMessage:@"头像修改失败"];
//                                                 } else {
//                                                     [HUD showWithMessage:@"头像修改成功"];
//                                                     
//#if TEACHERSIDE
//                                                     Teacher *teacher = APP.currentUser;
//                                                     teacher.avatarUrl = avatarUrl;
//                                                     APP.currentUser = teacher;
//#else
//                                                     Student *student = APP.currentUser;
//                                                     student.avatarUrl = avatarUrl;
//                                                     APP.currentUser = student;
//#endif
//                                                     
//                                                     [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfProfileUpdated object:nil];
//                                                     
//                                                     [self backButtonPressed:nil];
//                                                 }
//                                             }];
//                     }];
        });
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end


