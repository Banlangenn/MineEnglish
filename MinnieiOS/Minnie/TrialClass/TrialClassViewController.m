//
//  TrialClassViewController.m
//  MinnieStudent
//
//  Created by yebw on 2018/4/12.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import "IMManager.h"
#import "AlertView.h"
#import "PushManager.h"
#import "AuthService.h"
#import "AppDelegate.h"
#import "ManagerServce.h"
#import "TrialClassService.h"
#import "LoginViewController.h"
#import "EnrollTrialClassView.h"
#import "AppDelegate+ConfigureUI.h"
#import "TrialClassViewController.h"
#import "PortraitNavigationController.h"
#import <SDWebImage/UIImageView+WebCache.h>


@interface TrialClassViewController ()

@property (nonatomic, weak) IBOutlet UIButton *nextButton;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *grade;
@property (nonatomic, assign) NSInteger gender;
@property (weak, nonatomic) IBOutlet UIImageView *firstImageView;
@property (weak, nonatomic) IBOutlet UIImageView *secondImageView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *image1ViewHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *image2ViewHeight;

@property (nonatomic, assign) BOOL bFirstDown;
@property (nonatomic, assign) BOOL bSecondDown;

@property (nonatomic, strong) NSArray *images;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger contentHeight;
@property (nonatomic, strong) NSMutableArray *imageViews;

@end

@implementation TrialClassViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    UIImage *image1 = [UIImage imageNamed:@"首页1.png"];
//    UIImage *image2 = [UIImage imageNamed:@"首页2.png"];
    
    [self requestImages];
//
//    [self.firstImageView sd_setImageWithURL:[NSURL URLWithString:@"http://api.minniedu.com:8888/main.png"] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
//        if (image.size.width > 0) {
//
//            self.image1ViewHeight.constant = ScreenWidth * image.size.height / image.size.width;
//        }
//        self.bFirstDown = YES;
//        [self checkDownloadFinish];
//    }];
//
//    [self.secondImageView sd_setImageWithURL:[NSURL URLWithString:@"http://api.minniedu.com:8888/main_detail.png"] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
//        if (image.size.width > 0) {
//            self.image2ViewHeight.constant = ScreenWidth * image.size.height / image.size.width;
//        }
//        self.bSecondDown = YES;
//        [self checkDownloadFinish];
//    }];
//

    self.nextButton.layer.cornerRadius = 6.f;
    self.nextButton.layer.masksToBounds = YES;
    self.nextButton.backgroundColor = nil;
    [self.nextButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:1.f]] forState:UIControlStateNormal];
    [self.nextButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0 green:0x98/255.f blue:0xFE/255.f alpha:.8f]] forState:UIControlStateHighlighted];
    [self.nextButton setBackgroundImage:[Utils imageWithColor:[UIColor colorWithRed:0xDD/255.f green:0xDD/255.f blue:0xDD/255.f alpha:1.f]] forState:UIControlStateDisabled];
    
    Student *user = APP.currentUser;
    if (user.enrollState == 1) {
        [self.nextButton setTitle:@"报名审核中，请耐心等待..." forState:UIControlStateNormal];
    }
}

- (void)checkDownloadFinish
{
    if (self.bFirstDown && self.bSecondDown)
    {
        self.contentViewHeight.constant = self.image1ViewHeight.constant + self.image2ViewHeight.constant + 100;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    Student *user = APP.currentUser;
    if (user.enrollState == 1) {
        [self showEnrolledAlertView];
    }
}

- (void)showEnrolledAlertView {
    [self.nextButton setTitle:@"报名审核中，请耐心等待..." forState:UIControlStateNormal];
    
    [AlertView showInView:self.view
                withImage:[UIImage imageNamed:@"pop_img_welcome"]
                    title:@"欢迎加入minnie英文教室"
                  message:@"你目前已报名, 请等待教师回复"
                   action:@"知道啦"
           actionCallback:^{
           }];
}

- (void)dealloc {
}

- (IBAction)exitButtonPressed:(id)sender {

    AppDelegate * app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [app logout];
}

- (IBAction)nextButtonPressed:(id)sender {
    Student *user = APP.currentUser;
    if (user.enrollState == 1)
    {
        return;
    }
    
    [EnrollTrialClassView showInSuperView:self.view
                                 callback:^(NSString *name,
                                            NSString *grade,
                                            NSInteger gender) {
                                     self.name = name;
                                     self.grade = grade;
                                     self.gender = gender;
                                     
                                     [HUD showProgressWithMessage:@"正在报名..."];
                                     [TrialClassService enrollWithName:self.name
                                                                 grade:self.grade
                                                                gender:self.gender
                                                              callback:^(Result *result, NSError *error) {
                                                                  if (error != nil) {
                                                                      [HUD showErrorWithMessage:@"报名失败"];
                                                                  } else {
                                                                      [HUD showWithMessage:@"报名成功"];
                                                                      
                                                                      NSString *gender = self.gender==1?@"男孩":@"女孩";
                                                                      NSString *text = [NSString stringWithFormat:@"%@的%@ %@(%@) 报名", self.grade, gender, self.name, APP.currentUser.username];
                                                                      
                                                                      [PushManager pushText:text
                                                                                    toUsers:@[]
                                                                                addChannels:@[@"SuperManager"]];
                                                                      
                                                                      [EnrollTrialClassView hideAnimated:YES];
                                                                      
                                                                      Student *user = APP.currentUser;
                                                                      user.clazz = nil;
                                                                      user.enrollState = 1;
                                                                      APP.currentUser = user;
                                                                      
                                                                      [self showEnrolledAlertView];
                                                                  }
                                                              }];
                                     
                                    // [self showEnrollAlert];
                                 }];
}

- (void)showEnrollAlert {
    NSString *message = @"是否报名？确认后我们将通过电话联系您，请保持电话畅通";
    
    [AlertView showInView:self.view
                withImage:[UIImage imageNamed:@"pop_img_welcome"]
                    title:@"确认"
                  message:message
                  action1:@"取消"
          action1Callback:^{
          }
                  action2:@"确认"
          action2Callback:^{
              [HUD showProgressWithMessage:@"正在报名..."];
              [TrialClassService enrollWithName:self.name
                                          grade:self.grade
                                         gender:self.gender
                                       callback:^(Result *result, NSError *error) {
                                           if (error != nil) {
                                               [HUD showErrorWithMessage:@"报名失败"];
                                           } else {
                                               [HUD showWithMessage:@"报名成功"];
                                               
                                               NSString *gender = self.gender==1?@"男孩":@"女孩";
                                               NSString *text = [NSString stringWithFormat:@"%@的%@ %@(%@) 报名", self.grade, gender, self.name, APP.currentUser.username];

                                               [PushManager pushText:text
                                                             toUsers:@[]
                                                         addChannels:@[@"SuperManager"]];
                                               
                                               [EnrollTrialClassView hideAnimated:YES];
                                               
                                               Student *user = APP.currentUser;
                                               user.clazz = nil;
                                               user.enrollState = 1;
                                               APP.currentUser = user;
                                               
                                               [self showEnrolledAlertView];
                                           }
                                       }];
          }];
}


- (void)requestImages{
    
    [ManagerServce getWelcomesImagesWithType:0 callback:^(Result *result, NSError *error) {
        
        if (error) {
            
            UIImage *image = [UIImage imageNamed:@"首页1.png"];
            UIImageView *imageV = [[UIImageView alloc] initWithImage:image];
            [self.contentView addSubview:imageV];
            
            CGFloat imageHeight = ScreenWidth * image.size.height / image.size.width;
            imageV.frame = CGRectMake(0,0, ScreenWidth, imageHeight);
            self.contentViewHeight.constant = imageHeight;
            return ;
        }
        
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *list = (NSArray *)(dict[@"urls"]);
        
        self.images = list;
        self.currentIndex = 0;
        self.contentHeight = 0;
        [self updateContentImage];
    }];
}

- (void)updateContentImage{
    
    if (self.currentIndex >= self.images.count) {
        return;
    }
    NSString * imageUrl = self.images[self.currentIndex];
    
    UIImageView *imageV = [[UIImageView alloc] init];
    [self.contentView addSubview:imageV];

    [imageV sd_setImageWithURL:[NSURL URLWithString:imageUrl] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
       
        if (image.size.width > 0) {
            
            CGFloat imageHeight = ScreenWidth * image.size.height / image.size.width;
            CGRect rect = CGRectMake(0, self.contentHeight , ScreenWidth, imageHeight);
            imageV.frame = rect;
            self.contentHeight = self.contentHeight + imageHeight;
            self.contentViewHeight.constant = self.contentHeight;
        }
        self.currentIndex++;
        [self updateContentImage];
    }];
}




@end



