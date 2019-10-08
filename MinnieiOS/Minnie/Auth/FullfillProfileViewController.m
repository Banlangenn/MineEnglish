//
//  FullfillProfileViewController.m
//  X5
//
//  Created by yebw on 2017/9/17.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "FullfillProfileViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "AuthService.h"
#import "ProfileService.h"
#import "FileUploader.h"
#import "Student.h"
#import "Teacher.h"

@interface FullfillProfileViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, strong) UIImage *avatarImage;

@property (nonatomic, weak) IBOutlet UIButton *confirmButton;

@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UITextField *genderTextField;
@property (nonatomic, weak) IBOutlet UITextField *gradeTextField;

@end

@implementation FullfillProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.avatarImageView.layer.cornerRadius = 40.f;
    self.avatarImageView.layer.masksToBounds = YES;
    
    self.confirmButton.layer.cornerRadius = 6.f;
    self.confirmButton.layer.masksToBounds = YES;
    
    User *user = APP.currentUser;

    if (user.avatarUrl != nil) {
        [self.avatarImageView sd_setImageWithURL:[user.avatarUrl imageURLWithWidth:80.f]];
    }

    if ([user.nickname isEqual:user.username] || user.nickname.length==0) {
        self.nameTextField.text = nil;
    } else {
        self.nameTextField.text = user.nickname;
    }

    if (user.gender == 1) {
        self.genderTextField.text = @"男";
    } else if (user.gender == -1) {
        self.genderTextField.text = @"女";
    }
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

- (IBAction)backButtonPressed:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认退出编辑"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"退出"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self.navigationController popViewControllerAnimated:YES];
                                                          }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];

    alertController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)hideKeyboard:(id)sender {
    [self.nameTextField resignFirstResponder];
}

- (IBAction)changeAvatarButtonPressed:(id)sender {
    [self.nameTextField resignFirstResponder];
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:imagePickerController animated:YES completion:nil];
}

- (IBAction)changeGenderButtonPressed:(id)sender {
    [self.nameTextField resignFirstResponder];
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

    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:alertVC
                                            animated:YES
                                          completion:nil];
}

- (IBAction)changeGradeButtonPressed:(id)sender {
    [self.nameTextField resignFirstResponder];
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

    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:alertVC
                                            animated:YES
                                          completion:nil];
}

- (IBAction)confirmButtonPressed:(id)sender {
    if (APP.currentUser.avatarUrl.length == 0 && self.avatarImage==nil) {
        [HUD showErrorWithMessage:@"请设置头像"];
        return;
    }
    
    NSString *nickname = [self.nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (nickname.length == 0) {
        [HUD showErrorWithMessage:@"请填写姓名"];
        return;
    } else if (nickname.length > 10) {
        [HUD showErrorWithMessage:@"姓名最多10个字"];
        return;
    }
    
    NSString *genderText = [self.genderTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (genderText.length == 0) {
        [HUD showErrorWithMessage:@"请选择性别"];
        return;
    }
    
    NSString *gradeText = nil;
#if TEACHERSIDE | MANAGERSIDE
#else
    gradeText = [self.gradeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (gradeText.length == 0) {
        [HUD showErrorWithMessage:@"请选择年级"];
        return;
    }
#endif
    
    if (self.avatarImage != nil) {
        [self uploadAvatarImage];
    } else {
        NSMutableDictionary *profileDict = [NSMutableDictionary dictionary];
        profileDict[@"id"] = @(APP.currentUser.userId);
        profileDict[@"nickname"] = nickname;
        profileDict[@"gender"] = [genderText isEqualToString:@"男"] ? @(1) : @(-1);
        if (gradeText.length > 0) {
            profileDict[@"grade"] = gradeText;
        }
        
        [ProfileService updateProfile:profileDict
                             callback:^(Result *result, NSError *error) {
                                 if (error != nil) {
                                     [HUD showErrorWithMessage:@"更新失败"];
                                 } else {
                                     User *user = APP.currentUser;
                                     user.nickname = nickname;
                                     user.gender = [genderText isEqualToString:@"男"] ? 1 : -1;
                                     
#if TEACHERSIDE | MANAGERSIDE
                                     APP.currentUser = (Teacher *)user;
#else
                                     Student *student = (Student *)user;
                                     student.grade = gradeText;
                                     APP.currentUser = student;
#endif
                                     
                                     [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfLoginSuccess
                                                                                         object:nil];
                                     
                                 }
                             }];
    }
}

#pragma mark - Upload Avatar Image

- (void)uploadAvatarImage {
    NSData *imageData = UIImageJPEGRepresentation(self.avatarImage, .8f);
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
            
            [HUD showProgressWithMessage:@"正在修改信息..."];
            
            NSString *nickname = [self.nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *genderText = [self.genderTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *gradeText = [self.gradeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            NSMutableDictionary *profileDict = [NSMutableDictionary dictionary];
            profileDict[@"id"] = @(APP.currentUser.userId);
            profileDict[@"nickname"] = nickname;
            profileDict[@"gender"] = [genderText isEqualToString:@"男"] ? @(1) : @(-1);
            profileDict[@"avatarUrl"] = avatarUrl;
            if (gradeText.length > 0) {
                profileDict[@"grade"] = gradeText;
            }
            
            [ProfileService updateProfile:profileDict
                                 callback:^(Result *result, NSError *error) {
                                     if (error != nil) {
                                         [HUD showErrorWithMessage:@"更新失败"];
                                     } else {
                                         // 登录
                                         User *user = APP.currentUser;
                                         user.avatarUrl = avatarUrl;
                                         user.nickname = nickname;
                                         user.gender = [genderText isEqualToString:@"男"] ? 1 : -1;
                                         
#if TEACHERSIDE | MANAGERSIDE
                                         APP.currentUser = (Teacher *)user;
#else
                                         Student *student = (Student *)user;
                                         student.grade = gradeText;
                                         APP.currentUser = student;
#endif
                                         
                                         [HUD hideAnimated:NO];
                                         [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfLoginSuccess
                                                                                             object:nil];
                                     }
                                 }];
        }];
        
//        [[FileUploader shareInstance] uploadData:imageData
//                            type:UploadFileTypeImage
//                   progressBlock:^(NSInteger number) {
//                       [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传图片%@%%...", @(number)]];
//                   }
//                 completionBlock:^(NSString * _Nullable avatarUrl, NSError * _Nullable error) {
//                     if (avatarUrl.length == 0) {
//                         [HUD showErrorWithMessage:@"图片上传失败"];
//                         return;
//                     }
//
//                     [HUD showProgressWithMessage:@"正在修改信息..."];
//
//                     NSString *nickname = [self.nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//                     NSString *genderText = [self.genderTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//                     NSString *gradeText = [self.gradeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//
//                     NSMutableDictionary *profileDict = [NSMutableDictionary dictionary];
//                     profileDict[@"id"] = @(APP.currentUser.userId);
//                     profileDict[@"nickname"] = nickname;
//                     profileDict[@"gender"] = [genderText isEqualToString:@"男"] ? @(1) : @(-1);
//                     profileDict[@"avatarUrl"] = avatarUrl;
//                     if (gradeText.length > 0) {
//                         profileDict[@"grade"] = gradeText;
//                     }
//
//                     [ProfileService updateProfile:profileDict
//                                          callback:^(Result *result, NSError *error) {
//                                              if (error != nil) {
//                                                  [HUD showErrorWithMessage:@"更新失败"];
//                                              } else {
//                                                  // 登录
//                                                  User *user = APP.currentUser;
//                                                  user.avatarUrl = avatarUrl;
//                                                  user.nickname = nickname;
//                                                  user.gender = [genderText isEqualToString:@"男"] ? 1 : -1;
//
//#if TEACHERSIDE
//                                                  APP.currentUser = (Teacher *)user;
//#else
//                                                  Student *student = (Student *)user;
//                                                  student.grade = gradeText;
//                                                  APP.currentUser = student;
//#endif
//
//                                                  [HUD hideAnimated:NO];
//                                                  [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfLoginSuccess
//                                                                                                      object:nil];
//                                              }
//                                          }];
//                 }];
    });
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        self.avatarImageView.image = image;
        self.avatarImage = image;
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
}


@end



