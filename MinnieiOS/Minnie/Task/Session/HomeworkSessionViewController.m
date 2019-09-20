//
//  HomeworkSessionViewController.m
// X5
//
//  Created by yebw on 2017/8/24.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "HomeworkSessionViewController.h"
#import "FileUploader.h"
#import "IMManager.h"
#import "User.h"
#import "PushManager.h"
#import "NEPhotoBrowser.h"
#import "TextMessageTableViewCell.h"
#import "ImageMessageTableViewCell.h"
#import "MessageTimeTableViewCell.h"
#import "EmojiMessageTableViewCell.h"
#import "VideoMessageTableViewCell.h"
#import "AudioMessageTableViewCell.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVKit/AVKit.h>
#import <Bugly/Bugly.h>
#import "HomeworkSessionService.h"
#import "NSDate+X5.h"
#import "IMManager.h"
#import "SessionHomeworkTableViewCell.h"
#import "EmojiInputView.h"
#import "RecordStateView.h"
#import "RecordButton.h"
#import "WBGImageEditorViewController.h"
#import "AlertView.h"
#import "StudentDetailViewController.h"
#import "AudioPlayer.h"
#import "VIResourceLoaderManager.h"
#import "AudioPlayerViewController.h"
#import "CorrectHomeworkViewController.h"
#import "TZImagePickerController.h"
#import "VICacheManager.h"
#import "HomeworkAnswersPickerViewController.h"
#import "MICheckWordsViewController.h"
#import "MIFollowUpViewController.h"
#import "MIPlayerViewController.h"

#if MANAGERSIDE
#else

#import "MReadWordsViewController.h"

#endif

#if TEACHERSIDE || MANAGERSIDE
#import "HomeworkService.h"
#endif
static NSString * const kKeyOfCreateTimestamp = @"createTimestamp";
static NSString * const kKeyOfAudioDuration = @"audioDuration";
static NSString * const kKeyOfVideoDuration = @"videoDuration";

@interface HomeworkSessionViewController()<
UITableViewDataSource,
UITableViewDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
UITextViewDelegate,
EmojiInputViewDelegate,
UINavigationControllerDelegate,
VIResourceLoaderManagerDelegate,
HomeworkAnswersPickerViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *messagesTableView;
@property (nonatomic, weak) IBOutlet UIButton *audioButton;
@property (nonatomic, weak) IBOutlet UIButton *emojiButton;
@property (nonatomic, weak) IBOutlet UITextView *inputTextView;
@property (nonatomic, weak) IBOutlet UIView *inputTextBgView;
@property (nonatomic, weak) IBOutlet RecordButton *recordButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *inputTextViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *inputViewBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *operationsViewBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *emojiViewBottomLayoutConstraint;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *answerViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *warnViewWidthConstraint;

@property (nonatomic, weak) IBOutlet UIView *loadingContainerView;
@property (nonatomic, weak) IBOutlet UIButton *correctButton;

@property (nonatomic, strong) UIView *teremarkView;
@property (nonatomic, strong) UILabel *teremarkLabel;

@property (nonatomic, strong) NSMutableArray<AVIMTypedMessage *> *messages;
@property (nonatomic, strong) NSMutableDictionary *sortedMessages;
@property (nonatomic, strong) NSArray *sortedKeys;

@property (nonatomic, readonly) AVIMClient *client;
@property (nonatomic, readonly) AVIMConversation *conversation;

@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) NSDate *startTime;

@property (nonatomic, copy) NSString *tempText;

@property (nonatomic, weak) RecordStateView *recordStateView;

@property (nonatomic, weak) IBOutlet UIView *resultView;
@property (nonatomic, weak) IBOutlet UIView *resultContentView;
@property (nonatomic, weak) IBOutlet UIView *resultPaddingView;
@property (nonatomic, weak) IBOutlet UILabel *scoreLabel;
@property (nonatomic, weak) IBOutlet UIImageView *start1ImageView;
@property (nonatomic, weak) IBOutlet UIImageView *start2ImageView;
@property (nonatomic, weak) IBOutlet UIImageView *start3ImageView;
@property (nonatomic, weak) IBOutlet UIImageView *start4ImageView;
@property (nonatomic, weak) IBOutlet UIImageView *start5ImageView;
@property (nonatomic, weak) IBOutlet UIButton *retryButton;

@property (nonatomic, strong) NSArray<UIImageView *> * currentImageViews;
@property (nonatomic, strong)NSMutableArray * homeworkImages;    //作业详情所

@property (nonatomic, assign) BOOL isCommitingHomework;

@property (nonatomic, assign) BOOL dontScrollWhenAppeard;
@property (nonatomic, assign) BOOL isViewAppeard;
@property (nonatomic, assign) BOOL bFailReSendFlag;
@property (nonatomic, strong) VIResourceLoaderManager *resourceLoaderManager;
@property (nonatomic, strong) MBProgressHUD * mHud;


@end

@implementation HomeworkSessionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.messages = [NSMutableArray array];
    self.sortedMessages = [NSMutableDictionary dictionary];
    self.currentImageViews = [NSMutableArray array];
    
    //从作业中提取
    self.homeworkImages = [NSMutableArray array];
    for (int i = 0; i < self.homeworkSession.homework.items.count; i++)
    {
        HomeworkItem * items = [self.homeworkSession.homework.items objectAtIndex:i];
        if ([items.type isEqualToString:HomeworkItemTypeImage])
        {
            [self.homeworkImages addObject:items.imageUrl];
        }
    }
    APP.currentIMHomeworkSessionId = self.homeworkSession.homeworkSessionId;
    
    [self addNotification];
    [self configureUI];
    [self requestHomeworkDetail];
}

- (void)addNotification{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameDidChange:)
                                                 name:UIKeyboardDidChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageDidReceive:)
                                                 name:kIMManagerContentMessageDidReceiveNotification
                                               object:nil];
    
    // 老师批改作业
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(homeworkDidFinishCorrect:)
                                                 name:kNotificationKeyOfCorrectHomework
                                               object:nil];
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.isViewAppeard = YES;
    
    if (!self.dontScrollWhenAppeard && self.sortedMessages.count>0) {
        [self scrollMessagesTableViewToBottom:NO];
        self.dontScrollWhenAppeard = NO;
    }
    
//    for (UIGestureRecognizer *gr in self.view.window.gestureRecognizers) {
//        if (gr.delaysTouchesBegan) {
//            gr.delaysTouchesBegan = NO;
//        }
//    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[AudioPlayer sharedPlayer] stop];
}

- (IBAction)backButtonPressed:(id)sender {
#if MANAGERSIDE
    if (self.dissCallBack) {
        self.dissCallBack();
    }
#endif
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Notification

- (void)keyboardFrameWillChange:(NSNotification *)notification {
    NSValue *endValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect kbFrame = [endValue CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:nil];
    
    if (kbFrame.origin.y >= self.view.bounds.size.height) { // 键盘隐藏
        if (self.emojiViewBottomLayoutConstraint.constant == 0) {
            self.inputViewBottomConstraint.constant = 216.f;
        } else if (self.operationsViewBottomConstraint.constant == 0) {
            self.inputViewBottomConstraint.constant = 80.f;
        } else {
            self.inputViewBottomConstraint.constant = 0.f;
        }
    } else { // 键盘显示
        self.inputViewBottomConstraint.constant = kbFrame.size.height - (isIPhoneX?39:0);
    }
    
    [UIView animateWithDuration:0.3f
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                     }];
}

- (void)keyboardFrameDidChange:(NSNotification *)notification {
    NSValue *endValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect kbFrame = [endValue CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:nil];
    
    if (kbFrame.origin.y >= self.view.bounds.size.height) { // 键盘隐藏
    } else { // 键盘显示
        [self scrollMessagesTableViewToBottom:YES];
    }
}

- (void)messageDidReceive:(NSNotification *)notification {
    AVIMTypedMessage *message = notification.userInfo[@"message"];
    if (![self.conversation.conversationId isEqualToString:message.conversationId]) {
        return;
    }
    
    if (self.conversation != nil) {
        [self.conversation readInBackground];
    }
    
    NSDictionary *attributes = message.attributes;
    if (attributes[@"score"] != nil && [attributes[@"score"] integerValue]>=0) {
        self.homeworkSession.score = [attributes[@"score"] integerValue];
        self.homeworkSession.reviewText = attributes[@"reviewText"];
        self.homeworkSession.isRedo = [attributes[@"isRedo"] integerValue];
#if TEACHERSIDE || MANAGERSIDE
#else
        NSInteger star = MIN(5, self.homeworkSession.score);
        APP.currentUser.starCount += star;
#endif
        
        if ([self.inputView isFirstResponder] && [self isViewLoaded]) {
            [self.inputTextView resignFirstResponder];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self setupResultView];
                
                self.resultView.hidden = NO;
                self.inputView.hidden = YES;
                
                self.emojiViewBottomLayoutConstraint.constant = -216.f - (isIPhoneX?39:0);
                self.operationsViewBottomConstraint.constant = -80.f - (isIPhoneX?39:0);
                self.inputViewBottomConstraint.constant = 0.f;
            });
        } else {
            [self setupResultView];
            
            self.resultView.hidden = NO;
            self.inputView.hidden = YES;
            
            self.emojiViewBottomLayoutConstraint.constant = -216.f - (isIPhoneX?39:0);
            self.operationsViewBottomConstraint.constant = -80.f - (isIPhoneX?39:0);
            self.inputViewBottomConstraint.constant = 0.f;
        }
    }
    
    [self.messages addObject:message];
    [self sortMessages];
    
    [self reloadDataAndScrollToBottom];
}

- (void)homeworkDidFinishCorrect:(NSNotification *)notification {
#if TEACHERSIDE || MANAGERSIDE
#else
    return ;
#endif
    NSDictionary *data = notification.userInfo;
    HomeworkSession *session = data[@"HomeworkSession"];
    NSLog(@"correct:%@",session.conversation.conversationId);
    if (session.conversation.conversationId != self.conversation.conversationId) {
        
        NSLog(@"correct:not correct");
        return;
    }
    
    NSString *text = nil;
    if (self.homeworkSession.score == 0){
        text = [@"0星 " stringByAppendingString:self.homeworkSession.reviewText];
    }else if (self.homeworkSession.score == 1) {
        text = [@"1星 " stringByAppendingString:self.homeworkSession.reviewText];
    } else if (self.homeworkSession.score == 2) {
        text = [@"2星 " stringByAppendingString:self.homeworkSession.reviewText];
    } else if (self.homeworkSession.score == 3) {
        text = [@"3星 " stringByAppendingString:self.homeworkSession.reviewText];
    } else if (self.homeworkSession.score == 4) {
        text = [@"4星 " stringByAppendingString:self.homeworkSession.reviewText];
    } else if (self.homeworkSession.score == 5) {
        text = [@"5星 " stringByAppendingString:self.homeworkSession.reviewText];
    } else if (self.homeworkSession.score == 6) {
        text = [@"5星 " stringByAppendingString:self.homeworkSession.reviewText];
    }
    else
    {
        //text = @"报错";
        return;
    }
    
    if (self.homeworkSession.reviewText.length == 0)
    {
        self.homeworkSession.reviewText = @"";
    }
    
    [self sendTextMessage:text attributes:@{@"score":@(self.homeworkSession.score), @"reviewText":self.homeworkSession.reviewText,@"isRedo":@(self.homeworkSession.isRedo)}];
    [self.conversation setObject:@(YES) forKey:@"taskfinished"];
    WeakifySelf;
    [self.conversation updateWithCallback:^(BOOL succeeded, NSError * _Nullable error) {
        if (!succeeded) {
            StrongifySelf;
            [strongSelf.conversation updateWithCallback:^(BOOL succeeded, NSError * _Nullable error) {
            }];
        }
    }];
    [PushManager pushText:@"你有作业已通过" toUsers:@[@(self.homeworkSession.student.userId)]];
}

#pragma mark - IBActions

- (IBAction)audioButtonPressed:(id)sender {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                                 completionHandler:^(BOOL granted) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         if (granted) {
                                             [self audioButtonPressed:nil];
                                         } else {
                                             [HUD showErrorWithMessage:@"麦克风使用权限未授权"];
                                         }
                                     });
                                 }];
        
        return ;
    } else if (authStatus != AVAuthorizationStatusAuthorized) {
        [HUD showErrorWithMessage:@"麦克风使用权限未授权"];
        
        return ;
    }
    
    // 表情相关重置
    self.emojiViewBottomLayoutConstraint.constant = -216.f - (isIPhoneX?39:0);
    [self.emojiButton setImage:[UIImage imageNamed:@"icon_Emoji"] forState:UIControlStateNormal];
    
    // 操作按钮相关的重置
    self.operationsViewBottomConstraint.constant = -80.f - (isIPhoneX?39:0);
    
    // 根据录音按钮判断是否需要显示录音按钮
    if (self.recordButton.hidden) { // 需要显示 按住录音 文字
        self.tempText = self.inputTextView.text;
        self.inputTextView.text = @"minnie";
        [self resizeInputTextView];
        
        self.recordButton.hidden = NO;
        [self.audioButton setImage:[UIImage imageNamed:@"btn_keyboard"] forState:UIControlStateNormal];
        
        if (!self.inputTextView.isFirstResponder) {
            self.inputViewBottomConstraint.constant = 0;
            
            [UIView animateWithDuration:0.3f
                             animations:^{
                                 [self.view layoutIfNeeded];
                             }];
        } else {
            [self.inputTextView resignFirstResponder];
        }
    } else { // 显示键盘
        self.inputTextView.text = self.tempText;
        [self resizeInputTextView];
        
        self.recordButton.hidden = YES;
        [self.audioButton setImage:[UIImage imageNamed:@"icon_Voice"] forState:UIControlStateNormal];
        
        [self.inputTextView becomeFirstResponder];
    }
    
    [self disableControlsForAWhile];
}

- (IBAction)emojiButtonPressed:(id)sender {
    // 录音相关重置
    if (!self.recordButton.hidden) {
        self.inputTextView.text = self.tempText;
        [self resizeInputTextView];
    }
    
    self.recordButton.hidden = YES;
    [self.audioButton setImage:[UIImage imageNamed:@"icon_Voice"] forState:UIControlStateNormal];
    
    // 操作按钮相关的重置
    self.operationsViewBottomConstraint.constant = -80.f - (isIPhoneX?39:0);
    
    [self.view layoutIfNeeded];
    
    // 显示emoji键盘
    if (self.emojiViewBottomLayoutConstraint.constant < 0) { // 隐藏状态，需要显示emoji
        self.emojiViewBottomLayoutConstraint.constant = 0;
        [self.emojiButton setImage:[UIImage imageNamed:@"btn_keyboard"] forState:UIControlStateNormal];
        
        if ([self.inputTextView isFirstResponder]) {
            [self.inputTextView resignFirstResponder];
        } else {
            self.inputViewBottomConstraint.constant = 216.f;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 [self.view layoutIfNeeded];
                             } completion:^(BOOL finished) {
                                 [self scrollMessagesTableViewToBottom:YES];
                             }];
        }
    } else { // 显示键盘
        self.emojiViewBottomLayoutConstraint.constant = -216.f - (isIPhoneX?39:0);
        [self.emojiButton setImage:[UIImage imageNamed:@"icon_Emoji"] forState:UIControlStateNormal];
        
        [self.inputTextView becomeFirstResponder];
    }
    
    [self disableControlsForAWhile];
}

- (IBAction)addButtonPressed:(id)sender {
    if (!self.recordButton.hidden) {
        self.inputTextView.text = self.tempText;
        [self resizeInputTextView];
    }
    
    self.recordButton.hidden = YES;
    [self.audioButton setImage:[UIImage imageNamed:@"icon_Voice"] forState:UIControlStateNormal];
    
    self.emojiViewBottomLayoutConstraint.constant = -216.f - (isIPhoneX?39:0);
    [self.emojiButton setImage:[UIImage imageNamed:@"icon_Emoji"] forState:UIControlStateNormal];
    
    if (self.operationsViewBottomConstraint.constant < 0) { // 显示操作栏
        self.operationsViewBottomConstraint.constant = 0.f;
        
        if (self.inputTextView.isFirstResponder) {
            [self.inputTextView resignFirstResponder];
        } else {
            self.inputViewBottomConstraint.constant = 80.f;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 [self.view layoutIfNeeded];
                             }
                             completion:^(BOOL finished) {
                                 [self scrollMessagesTableViewToBottom:YES];
                             }];
        }
    } else {
        self.operationsViewBottomConstraint.constant = -80.f - (isIPhoneX?39:0);
        
        [self.inputTextView becomeFirstResponder];
    }
    
    [self disableControlsForAWhile];
}

- (IBAction)photoButtonPressed:(id)sender {
#if TEACHERSIDE || MANAGERSIDE
    self.isCommitingHomework = NO;
    UIImagePickerController *photoPicker = [[UIImagePickerController alloc] init];
    
    photoPicker.delegate = self;
    photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    photoPicker.mediaTypes = @[(NSString *)kUTTypeImage];
    
    [self.navigationController presentViewController:photoPicker animated:YES completion:nil];
#else
    self.isCommitingHomework = YES;
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:9 columnNumber:4 delegate:nil pushPhotoPickerVc:YES];
#pragma mark - 五类个性化设置，这些参数都可以不传，此时会走默认设置
    imagePickerVc.naviBgColor = [UIColor whiteColor];
    imagePickerVc.barItemTextColor = [UIColor colorWithHex:0x333333];
    imagePickerVc.naviTitleColor = [UIColor colorWithHex:0x333333];
    imagePickerVc.isSelectOriginalPhoto = YES;
    imagePickerVc.allowTakePicture = NO; // 在内部显示拍照按钮
    imagePickerVc.allowTakeVideo = NO;   // 在内部显示拍视频按
    [imagePickerVc setUiImagePickerControllerSettingBlock:^(UIImagePickerController *imagePickerController) {
        imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    }];
    
    imagePickerVc.iconThemeColor = [UIColor colorWithRed:31 / 255.0 green:185 / 255.0 blue:34 / 255.0 alpha:1.0];
    imagePickerVc.showPhotoCannotSelectLayer = YES;
    imagePickerVc.cannotSelectLayerColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    [imagePickerVc setPhotoPickerPageUIConfigBlock:^(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine) {
        [doneButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }];

    imagePickerVc.allowPickingVideo = NO;
    imagePickerVc.allowPickingImage = YES;
    imagePickerVc.allowPickingOriginalPhoto = NO;
    imagePickerVc.allowPickingGif = NO;
    imagePickerVc.allowPickingMultipleVideo = NO; // 是否可以多选视频
    
  
    imagePickerVc.showSelectBtn = NO;
    imagePickerVc.allowCrop = NO;
    imagePickerVc.needCircleCrop = NO;
    // 设置竖屏下的裁剪尺寸
   
    imagePickerVc.statusBarStyle = UIStatusBarStyleDefault;
    
    // 设置是否显示图片序号
    imagePickerVc.showSelectedIndex = NO;
    
    WeakifySelf;
    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        StrongifySelf;
        [strongSelf sendImageMessageWithImages:photos withSendIndex:0];

    }];
    
    [self presentViewController:imagePickerVc animated:YES completion:nil];
 #endif
}

- (IBAction)videoButtonPressed:(id)sender {
#if TEACHERSIDE || MANAGERSIDE
    self.isCommitingHomework = NO;
#else
    self.isCommitingHomework = YES;
#endif
    UIImagePickerController *videoPicker = [[UIImagePickerController alloc] init];
    videoPicker.allowsEditing = YES;
    videoPicker.videoMaximumDuration = self.homeworkSession.homework.limitTimes;
    videoPicker.delegate = self;
    videoPicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    videoPicker.mediaTypes =  @[(NSString *)kUTTypeMovie];
    
    [self.navigationController presentViewController:videoPicker animated:YES completion:nil];
}

- (IBAction)sendAnswerButtonPressed:(id)sender {
   
    if (self.homeworkSession.homework.answerItems.count == 0) {
        [HUD showWithMessage:@"当前作业没有设置答案"];

        return;
    }
    //跳转到
    HomeworkAnswersPickerViewController *answerPickerVc = [[HomeworkAnswersPickerViewController alloc] init];
    answerPickerVc.delegate = self;
    answerPickerVc.columnNumber = 4;
    answerPickerVc.answerItems = self.homeworkSession.homework.answerItems;
    [self.navigationController pushViewController:answerPickerVc animated:YES];
}

- (void)sendAnswer:(NSArray *)answers
{
    for (HomeworkAnswerItem *item in answers) {
        if ([item.type isEqualToString:HomeworkAnswerItemTypeImage]) {
            [self sendImageMessageWithURL:[NSURL URLWithString:item.imageUrl]];
        } else if ([item.type isEqualToString:HomeworkAnswerItemTypeVideo]) {
            [self sendVideoMessage:[NSURL URLWithString:item.videoUrl] duration:1.0];
        }
        else
        {
            
        }
    }
}

- (IBAction)sendWarningButtonPressed:(id)sender {
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"确定要发送警告吗？"
                                                                     message:nil
                                                              preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * cancleAction = [UIAlertAction actionWithTitle:@"取消"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           
                                                       }];
    
    UIAlertAction * confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             
                                                             [self sendImageMessageWithImage:[UIImage imageNamed:@"警告图片"]];
#if TEACHERSIDE || MANAGERSIDE
                                                             [HomeworkService sendWarnForStudent:self.homeworkSession.student.userId callback:^(Result *result, NSError *error) {
                                                                 if (error)
                                                                 {
                                                                     
                                                                 }
                                                             }];
#endif
                                                         }];
    
    [alertVC addAction:cancleAction];
    [alertVC addAction:confirmAction];
    
    [self presentViewController:alertVC
                     animated:YES
                   completion:nil];
   
}


- (IBAction)correctButtonPressed:(id)sender {
    CorrectHomeworkViewController *vc = [[CorrectHomeworkViewController alloc] initWithNibName:@"CorrectHomeworkViewController" bundle:nil];
    vc.homeworkSession = self.homeworkSession;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)retryButtonPressed:(id)sender {
    [AlertView showInView:self.navigationController.view
                withImage:[UIImage imageNamed:@"pop_img_return"]
                    title:@"重做这个作业？"
                  message:@"少年，很有个性哦！你确认要这么做？"
                  action1:@"放弃"
          action1Callback:^{
          }
                  action2:@"确定"
          action2Callback:^{
              [HomeworkSessionService redoHomeworkSessionWithId:self.homeworkSession.homeworkSessionId
                                                       callback:^(Result *result, NSError *error) {
                                                           if (error != nil) {
                                                               [HUD showErrorWithMessage:@"请求失败"];
                                                               return;
                                                           }
                                                           
#if TEACHERSIDE || MANAGERSIDE
#else
                                                           NSInteger star = MIN(5, self.homeworkSession.score);
                                                           if (APP.currentUser.starCount > star) {
                                                               APP.currentUser.starCount -= star;
                                                           } else {
                                                               APP.currentUser.starCount = 0;
                                                           }
                                                           
                                                           [PushManager pushText:@"你有重做的作业"
                                                                         toUsers:@[@(self.homeworkSession.correctTeacher.userId)]];
#endif
                                                           
                                                           self.homeworkSession.score = 0;
                                                           self.homeworkSession.reviewText = nil;
                                                           
                                                           self.resultView.hidden = YES;
                                                           self.inputView.hidden = NO;
                                                           
                                                           [self sendTextMessage:@"为了更多的星星而奋斗"];
                                                           
                                                           [self.conversation setObject:@(NO) forKey:@"taskfinished"];
                                                           WeakifySelf;
                                                           [self.conversation updateWithCallback:^(BOOL succeeded, NSError * _Nullable error) {
                                                               if (!succeeded) {
                                                                   StrongifySelf;
                                                                   [strongSelf.conversation updateWithCallback:^(BOOL succeeded, NSError * _Nullable error) {
                                                                   }];
                                                               }
                                                           }];
                                                           
                                                           [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfRedoHomework object:nil];
                                                       }];
          }];
}

- (IBAction)studentButtonPressed:(id)sender {
#if TEACHERSIDE || MANAGERSIDE
    StudentDetailViewController *vc = [[StudentDetailViewController alloc] initWithNibName:@"StudentDetailViewController" bundle:nil];
    vc.userId = self.homeworkSession.student.userId;
    [self.navigationController pushViewController:vc animated:YES];
#endif
}

#pragma mark - Private

- (AVIMClient *)client {
    return [IMManager sharedManager].client;
}

- (AVIMConversation *)conversation {
    return self.homeworkSession.conversation;
}

- (void)updateHomeworkSessionModifiedTime {
    WeakifySelf;
    [HomeworkSessionService updateHomeworkSessionModifiedTimeWithId:self.homeworkSession.homeworkSessionId
                                                           callback:^(Result *result, NSError *error) {
                                                               if (error == nil) {
                                                                 //  [weakSelf reUpdateModeifyTime];
                                                                   weakSelf.bFailReSendFlag = NO;
                                                               }
                                                               else
                                                               {
                                                                   weakSelf.bFailReSendFlag = YES;
                                                               }
                                                           }];
}


#pragma mark - 设置会话
- (void)setupConversation {
  
    NSString *teacherId = [NSString stringWithFormat:@"%@", @(self.homeworkSession.correctTeacher.userId)];
    NSString *studentId = [NSString stringWithFormat:@"%@", @(self.homeworkSession.student.userId)];
    
    [self.loadingContainerView showLoadingView];
    
    NSString *name = [NSString stringWithFormat:@"%@", @(self.homeworkSession.homeworkSessionId)];
    if (self.conversation == nil) {
       
        AVIMConversationQuery *query = [self.client conversationQuery];
        [query whereKey:@"name" equalTo:name];
        [query findConversationsWithCallback:^(NSArray * _Nullable conversations, NSError * _Nullable error) {

            if (error == nil)
            {
                if (conversations.count > 0) {
                    
                    self.homeworkSession.conversation = conversations[0];
                    [self loadMessagesHistory];
                } else {
                    
                    [self.client createConversationWithName:name
                                                  clientIds:@[teacherId, studentId]
                                                 attributes:nil
                                                    options:AVIMConversationOptionNone
                                                   callback:^(AVIMConversation * conversation, NSError * error) {
                                                       if (error == nil) {
                                                           self.homeworkSession.conversation = conversation;
                                                           
                                                           [self loadMessagesHistory];
                                                       } else {
                                                           BLYLogError(@"会话页面加载失败(创建IM会话失败): %@", error);
                                                           
                                                           [self.loadingContainerView showFailureViewWithRetryCallback:^{
                                                               [self setupConversation];
                                                           }];
                                                       }
                                                   }];
                }
            }
            else
            {
                BLYLogError(@"会话页面加载失败(创建IM会话失败): %@", error);
                [self.loadingContainerView showFailureViewWithRetryCallback:^{
                    [self setupConversation];
                }];
            }
        }];
    } else {

        [self loadMessagesHistory];
    }
}

- (void)sendTextMessage:(NSString *)text {
  
    if (text.length > 0) {
        
        [self sendTextMessage:text attributes:nil];
    }
}

- (void)sendTextMessage:(NSString *)text attributes:(NSDictionary *)attributes {
    self.inputTextView.text = nil;
    [self resizeInputTextView];
    
    int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (attributes.count > 0) {
        [dict addEntriesFromDictionary:attributes];
    }
    dict[kKeyOfCreateTimestamp] = @(timestamp);

    [NSMutableDictionary dictionaryWithDictionary:attributes];
    AVIMTextMessage *message = [AVIMTextMessage messageWithText:text attributes:dict];
    [self sendMessage:message];
}

- (void)sendEmojiMessage:(NSString *)text {
    int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    AVIMTextMessage *message = [AVIMTextMessage messageWithText:text attributes:@{@"isEmoji":@(1), kKeyOfCreateTimestamp:@(timestamp)}];
    
    [self sendMessage:message];
}

- (UIImage *)editedImageWithImage:(UIImage *)originalImage {
    // 先看确定尺寸
    CGFloat width = originalImage.size.width;
    CGFloat height = originalImage.size.height;
    if (originalImage.size.width>=720.f || originalImage.size.height>=2160.f) {
        CGFloat ratio = originalImage.size.width / originalImage.size.height;
        if (ratio >= 1/3.f) {
            width = MIN(originalImage.size.width, 720.f);
            height = width / ratio;
        }
        else {
            width = MIN(originalImage.size.width, 480.f);
            height = width / ratio;
        }
    }
    
    UIImage *image = originalImage;
    if (ABS(width-originalImage.size.width) > 1.f) {
        CGSize imageSize = CGSizeMake(width, height);
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 1.f);
        [originalImage drawInRect:CGRectMake(0.f, 0.f, width, height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return image;
}

- (void)sendImageMessageWithImages:(NSArray *)images withSendIndex:(NSInteger)index
{
    if (index == images.count)
    {
        return;
    }
    NSInteger nextIndex = index+1;
    [HUD showProgressWithMessage:@"正在压缩图片..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *editedImage;
        if (index < images.count) {
            editedImage = [self editedImageWithImage:[images objectAtIndex:index]];
        }
        NSData *data = UIImageJPEGRepresentation(editedImage, 0.4f);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [HUD showProgressWithMessage:@"正在上传图片..."];
            WeakifySelf;
            
            QNUploadOption * option = [[QNUploadOption alloc] initWithProgressHandler:^(NSString *key, float percent) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传图片%.f%%...", percent * 100]];
                });
                
            }];
            
            [[FileUploader shareInstance] qn_uploadData:data type:UploadFileTypeImage option:option completionBlock:^(NSString * _Nullable imageUrl, NSError * _Nullable error) {
                StrongifySelf;
                if (imageUrl.length > 0) {
                    [HUD hideAnimated:YES];
                    
                    [self sendImageMessageWithURL:[NSURL URLWithString:imageUrl]];
                } else {
                    [HUD showErrorWithMessage:@"图片上传失败"];
                }
                
                [strongSelf sendImageMessageWithImages:images withSendIndex:nextIndex];
            }];
        });
    });
}


- (void)sendImageMessageWithImage:(UIImage *)image {
    
    [HUD showProgressWithMessage:@"正在压缩图片..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *editedImage = [self editedImageWithImage:image];
        NSData *data = UIImageJPEGRepresentation(editedImage, 0.7f);

        dispatch_async(dispatch_get_main_queue(), ^{
            [HUD showProgressWithMessage:@"正在上传图片..."];
            
            QNUploadOption * option = [[QNUploadOption alloc] initWithProgressHandler:^(NSString *key, float percent) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传图片%.f%%...", percent * 100]];
                });

            }];
            [[FileUploader shareInstance] qn_uploadData:data type:UploadFileTypeImage option:option completionBlock:^(NSString * _Nullable imageUrl, NSError * _Nullable error) {
                if (imageUrl.length > 0) {
                    [HUD hideAnimated:YES];
                    
                    [self sendImageMessageWithURL:[NSURL URLWithString:imageUrl]];
                } else {
                    [HUD showErrorWithMessage:@"图片上传失败"];
                }
            }];
        });
    });
}

- (void)playSendAudio{
    
    [[AudioPlayer sharedPlayer] playURL:[NSURL URLWithString:@"sendMessage.mp3"]];
}

- (void)sendImageMessageWithURL:(NSURL *)imageURL {
    
    //重置底部状态
    self.emojiViewBottomLayoutConstraint.constant = -216.f - (isIPhoneX?39:0);
    self.operationsViewBottomConstraint.constant = -80.f - (isIPhoneX?39:0);
    self.inputViewBottomConstraint.constant = 0.f;
    
    
    if (self.isCommitingHomework) {
        [HUD showProgressWithMessage:@"正在提交作业..."];
        
        [HomeworkSessionService commitHomeworkWithId:self.homeworkSession.homeworkSessionId
                                            imageUrl:imageURL.absoluteString
                                            videoUrl:nil
                                            callback:^(Result *result, NSError *error) {
                                                
                                                
                                                if (error == nil) {
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfCommitHomework object:nil];
                                                    
                                                    [self playSendAudio];
                                                    
                                                    
                                                    [HUD showWithMessage:@"作业提交成功"];
                                                    
                                                    [PushManager pushText:@"[图片]"
                                                                  toUsers:@[@(self.homeworkSession.correctTeacher.userId)] withPushType:PushManagerMessage];
                                                    
                                                    int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
                                                    AVFile *file = [AVFile fileWithRemoteURL:imageURL];
                                                    AVIMImageMessage *message = [AVIMImageMessage messageWithText:@"image" file:file attributes:@{kKeyOfCreateTimestamp:@(timestamp)}];
                                                    
                                                    [self sendMessage:message];
                                                    
                                                    
                                                } else {
                                                    [HUD showErrorWithMessage:@"作业提交失败"];
                                                }
                                                self.isCommitingHomework = NO;
                                            }];
    } else {
        int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
        AVFile *file = [AVFile fileWithRemoteURL:imageURL];
        AVIMImageMessage *message = [AVIMImageMessage messageWithText:@"image" file:file attributes:@{kKeyOfCreateTimestamp:@(timestamp)}];
        
        [self sendMessage:message];
    }
}

- (void)sendAudioMessage:(NSURL *)audioURL duration:(CGFloat)duration {
    int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    AVFile *file = [AVFile fileWithRemoteURL:audioURL];
    NSInteger d = (NSInteger)duration;
    AVIMAudioMessage *message = [AVIMAudioMessage messageWithText:@"audio"
                                                             file:file
                                                       attributes:@{kKeyOfCreateTimestamp:@(timestamp),
                                                                    kKeyOfAudioDuration:@(d)}];
    [self sendMessage:message];
}

- (void)send{

}

- (void)sendVideoMessageForPath:(NSString *)path
{
    NSString *userId;
    NSString *clientId = [IMManager sharedManager].client.clientId;
    AVIMClientStatus status = [IMManager sharedManager].client.status;
#if MANAGERSIDE
    userId = [NSString stringWithFormat:@"%@", @(self.teacher.userId)];
    if (userId.integerValue != APP.currentUser.userId) {// 非当前不能发送消息
        return;
    }
    
#else
    userId = [NSString stringWithFormat:@"%@", @(APP.currentUser.userId)];
#endif
    if ([userId isEqualToString:clientId] && status == AVIMClientStatusOpened) {
    } else {
        [[IMManager sharedManager] setupWithClientId:userId callback:^(BOOL success,  NSError * error) {
            if (!success) return ;
        }];
    }
    if (status != AVIMClientStatusOpened) {
//        [HUD showErrorWithMessage:@"IM服务暂不可用，请稍后再试"];
        return;
    }
    
    AVFile *file = [AVFile fileWithLocalPath:path error:nil];
    int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    AVIMVideoMessage *message = [AVIMVideoMessage messageWithText:@"video"
                                                             file:file
                                                       attributes:@{kKeyOfCreateTimestamp:@(timestamp)}];
     BOOL isResend = message.status == AVIMMessageStatusFailed;
    [self.conversation sendMessage:message progressBlock:^(NSInteger progress) {
        [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传视频%@%%...", @(progress)] cancelCallback:^{
            [file cancelUploading];
        }];
    } callback:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded)
        {
          //  [HUD hideAnimated:YES];
            
            if (file.url.length == 0)
            {
                [HUD showErrorWithMessage:@"视频上传失败"];
                return;
            }
            
#if TEACHERSIDE || MANAGERSIDE
#else
            if (self.messages.count==0)
            {
                [self updateHomeworkSessionModifiedTime];
            }
            
            if (self.bFailReSendFlag)
            {
                [self updateHomeworkSessionModifiedTime];
            }
#endif
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kIMManagerContentMessageDidSendNotification object:nil userInfo:@{@"message": message}];
            
            if (!isResend) {
                [self.messages addObject:(AVIMTypedMessage *)message];
            }
            
            [self sortMessages];
            [self reloadDataAndScrollToBottom];
            
            
            if (self.isCommitingHomework)
            {
                [HUD showProgressWithMessage:@"正在提交作业..."];
                
                [HomeworkSessionService commitHomeworkWithId:self.homeworkSession.homeworkSessionId
                                                    imageUrl:nil
                                                    videoUrl:file.url
                                                    callback:^(Result *result, NSError *error) {
                                                        self.isCommitingHomework = NO;
                                                        
                                                        if (error == nil) {
                                                            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfCommitHomework object:nil];
                                                            [self playSendAudio];
                                                            [HUD showWithMessage:@"作业提交成功"];
                                                            [PushManager pushText:@"[视频]"
                                                                          toUsers:@[@(self.homeworkSession.correctTeacher.userId)] withPushType:PushManagerMessage];
                                                            
                                                    
                                                        } else {
                                                            [HUD showErrorWithMessage:@"作业提交失败"];
                                                        }
                                                    }];
                
            }
        }
        else
        {
            [HUD showErrorWithMessage:@"视频上传失败"];
        }
    }];
    
}

- (void)sendVideoMessage:(NSURL *)videoURL duration:(CGFloat)duration{
    
    self.emojiViewBottomLayoutConstraint.constant = -216.f - (isIPhoneX?39:0);
    self.operationsViewBottomConstraint.constant = -80.f - (isIPhoneX?39:0);
    self.inputViewBottomConstraint.constant = 0.f;
    
    if (self.isCommitingHomework) {
        [HUD showProgressWithMessage:@"正在提交作业..."];
        
        [HomeworkSessionService commitHomeworkWithId:self.homeworkSession.homeworkSessionId
                                            imageUrl:nil
                                            videoUrl:videoURL.absoluteString
                                            callback:^(Result *result, NSError *error) {
                                                
                                                
                                                if (error == nil) {
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfCommitHomework object:nil];
                                                    
                                                    [self playSendAudio];
                                                    [HUD showWithMessage:@"作业提交成功"];
                                                    [PushManager pushText:@"[视频]"
                                                                  toUsers:@[@(self.homeworkSession.correctTeacher.userId)] withPushType:PushManagerMessage];
                                                    
                                                    int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
                                                    NSInteger d = (NSInteger)duration;
                                                    AVFile *file = [AVFile fileWithRemoteURL:videoURL];
                                                    AVIMVideoMessage *message = [AVIMVideoMessage messageWithText:@"video"
                                                                                                             file:file
                                                                                                       attributes:@{kKeyOfCreateTimestamp:@(timestamp),kKeyOfVideoDuration:@(d)}];
                                                    
                                                    [self sendMessage:message];
                                                } else {
                                                    [HUD showErrorWithMessage:@"作业提交失败"];
                                                }
                                                self.isCommitingHomework = NO;
                                            }];
    } else {
        int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
        AVFile *file = [AVFile fileWithRemoteURL:videoURL];
        AVIMVideoMessage *message = [AVIMVideoMessage messageWithText:@"video"
                                                                 file:file
                                                           attributes:@{kKeyOfCreateTimestamp:@(timestamp)}];
        
        [self sendMessage:message];
    }
}

- (void)sendMessage:(AVIMMessage *)message {
    
    //发送消息之前进行IM服务判断
    NSString *userId;
    NSString *clientId = [IMManager sharedManager].client.clientId;
    AVIMClientStatus status = [IMManager sharedManager].client.status;
#if MANAGERSIDE
    userId = [NSString stringWithFormat:@"%@", @(self.teacher.userId)];
    if (userId.integerValue != APP.currentUser.userId) {// 非当前不能发送消息
        return;
    }
#else
    userId = [NSString stringWithFormat:@"%@", @(APP.currentUser.userId)];
#endif
    if ([userId isEqualToString:clientId] && status == AVIMClientStatusOpened) {
    } else {
        [[IMManager sharedManager] setupWithClientId:userId callback:^(BOOL success,  NSError * error) {
            if (!success) return ;
        }];
    }
    if (status != AVIMClientStatusOpened) {
//        [HUD showErrorWithMessage:@"IM服务暂不可用，请稍后再试"];
        return;
    }
    
    [self playSendAudio];
    BOOL isResend = message.status == AVIMMessageStatusFailed;
    
    //发送消息，区分学生端和客户端
    NSString * text = @"您有一条消息";
    if (message.mediaType == kAVIMMessageMediaTypeText)
    {
        AVIMTextMessage * textMessage = (AVIMTextMessage *)message;
        if (textMessage.text.length > 0) {
            text = textMessage.text;
        }
    }
    else if (message.mediaType == kAVIMMessageMediaTypeImage)
    {
        if (!self.isCommitingHomework)
        {
            text = @"[图片]";
        }
    }
    else if (message.mediaType == kAVIMMessageMediaTypeAudio)
    {
        text = @"[语音]";
    }
    else if (message.mediaType == kAVIMMessageMediaTypeVideo)
    {
        if (!self.isCommitingHomework)
        {
            text = @"[视频]";
        }
    }
    
    AVIMMessageOption *option = [[AVIMMessageOption alloc] init];
    option.pushData = @{@"alert":@{@"body":text,@"action-loc-key":@"com.minine.push",@"loc-key":@(PushManagerMessage)}, @"badge":@"Increment",@"pushType" :@(PushManagerMessage),@"action":@"com.minine.push"};
    
    [self.conversation sendMessage:message
                            option:option
                          callback:^(BOOL succeeded, NSError * _Nullable error) {
#if TEACHERSIDE || MANAGERSIDE
#else
                              if (succeeded && self.messages.count==0)
                              {
                                  [self updateHomeworkSessionModifiedTime];
                              }
                              
                              if (self.bFailReSendFlag)
                              {
                                  [self updateHomeworkSessionModifiedTime];
                              }
#endif
                              [[NSNotificationCenter defaultCenter] postNotificationName:kIMManagerContentMessageDidSendNotification object:nil userInfo:@{@"message": message}];
                              
                              if (!isResend) {
                                  [self.messages addObject:(AVIMTypedMessage *)message];
                              }

                              [self sortMessages];
                              [self reloadDataAndScrollToBottom];
#if TEACHERSIDE || MANAGERSIDE
#else
                              [self correctNotifyHomeworkSession];
#endif
                          }];
}

#pragma mark - 通知类学生端发送任意消息，自动批改
- (void)correctNotifyHomeworkSession{
    
    if (![self.homeworkSession.homework.typeName isEqualToString:kHomeworkTaskNotifyName]) {
        return;
    }
    // -1表示未批改过
    if (self.homeworkSession.score != -1)  return;
    NSMutableArray *studentMessages = [NSMutableArray array];
    for (NSString *key in self.sortedKeys) {
        
        NSArray *messages = self.sortedMessages[key];
        for (AVIMTypedMessage *message in messages) {
         
            if (message.ioType==AVIMMessageIOTypeOut) {
                [studentMessages addObject:message];
            };
        }
    }
    // 通知类型作业自动通过
    if (studentMessages.count == 1) {
#if MANAGERSIDE
        if (self.dissCallBack) {
            self.dissCallBack();
        }
#endif
        [self.navigationController popViewControllerAnimated:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfCorrectHomework object:nil userInfo:@{@"HomeworkSession":self.homeworkSession}];// 更新作业列表
    }
}

- (void)handlePhotoPickerResult:(UIImagePickerController *)picker
  didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (image.size.width==0 || image.size.height==0) {
            [HUD showErrorWithMessage:@"图片选择失败"];
            return;
        }
#if TEACHERSIDE || MANAGERSIDE
        WBGImageEditorViewController *editVC = [[WBGImageEditorViewController alloc] init];
        [editVC setOnlyForSend:YES];
        [editVC setThumbnailImages:@[image]];
        [editVC setSendCallback:^(UIImage *image) {
            [self sendImageMessageWithImage:image];
        }];
        [self.navigationController presentViewController:editVC animated:YES completion:nil];
#endif
    }];
}

- (void)handleVideoPickerResult:(UIImagePickerController *)picker
  didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
   
    [picker dismissViewControllerAnimated:YES completion:^{
        NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
        
        NSTimeInterval durationInSeconds = 0.0;
        if (asset != nil) {
            durationInSeconds = CMTimeGetSeconds(asset.duration);
        }
        
#if TEACHERSIDE || MANAGERSIDE
#else
        if (durationInSeconds > 5*60) {
         
            [HUD showErrorWithMessage:@"视频时长不能超过5分钟"];
            return;
        }
#endif
        
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld_compressedVideo.mp4",time(NULL)]];

        AVURLAsset *avAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
        NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
        if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
            AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPreset960x540];
            exportSession.outputURL = [NSURL fileURLWithPath:path];
            exportSession.shouldOptimizeForNetworkUse = true;
            exportSession.outputFileType = AVFileTypeMPEG4;
            
            [HUD showProgressWithMessage:@"正在压缩视频..."];
            
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                        WeakifySelf;
                        __block BOOL flag = NO;
                        QNUploadOption * option = [[QNUploadOption alloc] initWithMime:nil progressHandler:^(NSString *key, float percent) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (!weakSelf.mHud)
                                {
                                    weakSelf.mHud = [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传视频%.f%%...", percent * 100] cancelCallback:^{
                                        flag = YES;
                                    }];
                                }
                                else
                                {
                                    UILabel * label = [weakSelf.mHud.customView viewWithTag:99];
                                    
                                    label.text = [NSString stringWithFormat:@"正在上传视频%.f%%...", percent * 100];
                                }
                            });
                        } params:nil checkCrc:NO cancellationSignal:^BOOL{
                            return flag;
                        }];
                        
                        [[FileUploader shareInstance] qn_uploadFile:path type:UploadFileTypeVideo option:option completionBlock:^(NSString * _Nullable videoUrl, NSError * _Nullable error) {
                            weakSelf.mHud = nil;
                            if (videoUrl.length > 0) {
                                [HUD hideAnimated:YES];
                                
                                [weakSelf sendVideoMessage:[NSURL URLWithString:videoUrl] duration:durationInSeconds];
                                
                                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                            } else {
                                [HUD showErrorWithMessage:@"视频上传失败"];
                            }
                        }];
                    } else{
                        NSLog(@"当前压缩进度:%f",exportSession.progress);
                    }
                    
                    NSLog(@"%@",exportSession.error);
                });
            }];
        }
    }];
}

- (void)playerVideoWithURL:(NSString *)url showSave:(BOOL)showSave{
    [self.inputTextView resignFirstResponder];
    
    [[AudioPlayer sharedPlayer] stop];
    AVAudioSession *session =[AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSInteger playMode = [[Application sharedInstance] playMode];

    MIPlayerViewController *playerViewController = [[MIPlayerViewController alloc]init];
    if (showSave) {
        [playerViewController showSaveVideo:url];
    }
    AVPlayer *player;
    if (playMode == 1) // 在线播放
    {
        [VICacheManager cleanCacheForURL:[NSURL URLWithString:url] error:nil];
        player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:url]];
    }
    else
    {
        VIResourceLoaderManager *resourceLoaderManager = [VIResourceLoaderManager new];
        resourceLoaderManager.delegate = self;
        self.resourceLoaderManager = resourceLoaderManager;
        AVPlayerItem *playerItem = [resourceLoaderManager playerItemWithURL:[NSURL URLWithString:url]];
        player = [AVPlayer playerWithPlayerItem:playerItem];
    }
    
    playerViewController.player = player;
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.view.frame = self.view.frame;
    [playerViewController.player play];
    
    self.dontScrollWhenAppeard = YES;
}

- (void)playAudioWithURL:(NSString *)url withCoverURL:(NSString *)coverUrl
{
    [self.inputTextView resignFirstResponder];
    
    [[AudioPlayer sharedPlayer] stop];
    AVAudioSession *session =[AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    AudioPlayerViewController *playerViewController = [[AudioPlayerViewController alloc]init];
    NSInteger playMode = [[Application sharedInstance] playMode];
    AVPlayer *player;
    if (playMode == 1) // 在线播放
    {
        [VICacheManager cleanCacheForURL:[NSURL URLWithString:url] error:nil];
        player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:url]];
    }
    else
    {
        VIResourceLoaderManager *resourceLoaderManager = [VIResourceLoaderManager new];
        resourceLoaderManager.delegate = self;
        self.resourceLoaderManager = resourceLoaderManager;
        AVPlayerItem *playerItem = [resourceLoaderManager playerItemWithURL:[NSURL URLWithString:url]];
        player = [AVPlayer playerWithPlayerItem:playerItem];
    }
    playerViewController.player = player;
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.view.frame = self.view.frame;
    [playerViewController.player play];
    [playerViewController setOverlyViewCoverUrl:coverUrl];
    
    self.dontScrollWhenAppeard = YES;
}

- (void)resizeInputTextView {
    
    NSInteger lines = 0;
    if (self.inputTextView.font.lineHeight) {
        lines = [self.inputTextView sizeThatFits:self.inputTextView.frame.size].height / self.inputTextView.font.lineHeight;
    }

    CGFloat height = lines * self.inputTextView.font.lineHeight;
    self.inputTextViewHeightConstraint.constant = MIN(height, self.inputTextView.font.lineHeight * 4);
    
    [self.inputView layoutIfNeeded];
}

#pragma mark - 加载历史消息
- (void)loadMessagesHistory {
    
    NSLog(@"loadMessagesHistory %@  %@",[IMManager sharedManager].client.clientId,self.conversation.description);
    WeakifySelf;
    [self.conversation queryMessagesWithLimit:1000 callback:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        StrongifySelf;
        if (error != nil) {
            BLYLogError(@"会话页面加载失败(加载历史小时失败): %@", error);

            [strongSelf.loadingContainerView showFailureViewWithRetryCallback:^{
                strongSelf.homeworkSession.conversation = nil;
                [strongSelf setupConversation];
            }];

            return;
        }

        if (strongSelf.conversation != nil) {
            [strongSelf.conversation readInBackground];
        }

        strongSelf.loadingContainerView.hidden = YES;

        if (objects.count > 0) {
            strongSelf.messagesTableView.hidden = YES;

            [strongSelf.messages addObjectsFromArray:objects];

            [strongSelf sortMessages];
            dispatch_async(dispatch_get_main_queue(), ^{
               
                [strongSelf.messagesTableView reloadData];
                [strongSelf scrollMessagesTableViewToBottom:NO];
                strongSelf.messagesTableView.hidden = NO;
            });
        }
    }];
}

- (void)sortMessages {
    self.sortedKeys = nil;
    [self.sortedMessages removeAllObjects];
    
    NSArray *orderedMessages = [self.messages sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        AVIMTypedMessage *message1 = (AVIMTypedMessage *)obj1;
        AVIMTypedMessage *message2 = (AVIMTypedMessage *)obj2;
        
        int64_t time1 = message1.sendTimestamp>0?message1.sendTimestamp:[message1.attributes[kKeyOfCreateTimestamp] longLongValue];
        int64_t time2 = message2.sendTimestamp>0?message2.sendTimestamp:[message2.attributes[kKeyOfCreateTimestamp] longLongValue];
        
        if (time1 < time2) {
            return NSOrderedAscending;
        } else if (time1 > time2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    NSTimeInterval timeKey = 0;
    NSMutableArray *groupMessages = nil;
    for (NSInteger index=0; index<orderedMessages.count; index++) {
        AVIMMessage *message = orderedMessages[index];
        
        NSLog(@"message: %@ ",((AVIMTextMessage *)message).text);
        if ([message isKindOfClass:[AVIMTextMessage class]] &&
            ((AVIMTextMessage *)message).text.length == 0) {
            if (index == orderedMessages.count-1) {
                NSString *key = [NSString stringWithFormat:@"%.f", timeKey];
                self.sortedMessages[key] = groupMessages;
            }
            continue;
        }
        
        if (timeKey == 0) {
            timeKey = message.sendTimestamp;
            groupMessages = [NSMutableArray array];
        }
        
        if (message.sendTimestamp - timeKey > 2 * 50 * 1000) { // 5分钟内是连续的
            NSString *key = [NSString stringWithFormat:@"%.f", timeKey];
            self.sortedMessages[key] = groupMessages;
            
            timeKey = message.sendTimestamp;
            groupMessages = [NSMutableArray array];
        }
        
        BOOL exists = NO;
        for (AVIMMessage *m in groupMessages) {
            if ([m.messageId isEqualToString:message.messageId]) {
                exists = YES;
                break;
            }
        }

        if (!exists) {
            [groupMessages addObject:message];
        }
        
        if (index == orderedMessages.count-1) {
            NSString *key = [NSString stringWithFormat:@"%.f", timeKey];
            self.sortedMessages[key] = groupMessages;
        }
//
//        NSLog(@"message:%lld %f, %@ ",message.sendTimestamp,timeKey,((AVIMTextMessage *)message).text);
//        NSLog(@"message:1 %@",self.sortedMessages);
//        NSLog(@"message:2 %@",groupMessages);
        
    }
    
    self.sortedKeys = [self.sortedMessages.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return
        [(NSString *)obj1 compare:(NSString *)obj2];
    }];
}

- (void)scrollMessagesTableViewToBottom:(BOOL)animated {
    CGFloat height = self.messagesTableView.contentSize.height - self.messagesTableView.frame.size.height;
    if (height > 0) {
        [self.messagesTableView setContentOffset:CGPointMake(0, height) animated:animated];
    }
}

- (void)disableControlsForAWhile {
    self.view.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.view.userInteractionEnabled = YES;
    });
}

- (void)reloadDataAndScrollToBottom {
    AVIMMessage *message = self.conversation.lastMessage;
    if ([message isKindOfClass:[AVIMTextMessage class]]) {
        self.homeworkSession.lastSessionContent = ((AVIMTextMessage *)message).text;
    } else if ([message isKindOfClass:[AVIMAudioMessage class]]) {
        self.homeworkSession.lastSessionContent = @"[音频]";
    } else if ([message isKindOfClass:[AVIMVideoMessage class]]) {
        self.homeworkSession.lastSessionContent = @"[视频]";
    } else if ([message isKindOfClass:[AVIMImageMessage class]]) {
        self.homeworkSession.lastSessionContent = @"[图片]";
    }
    
    if (message.ioType == AVIMMessageIOTypeOut) {
        //        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfLastIMMessageDidChange
        //                                                            object:nil
        //                                                          userInfo:@{@"message":message}];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messagesTableView reloadData];
        [self scrollMessagesTableViewToBottom:YES];
    });
}

- (void)startRecord {
    [[AudioPlayer sharedPlayer] stop];

    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(
                                                            NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir
                               stringByAppendingPathComponent:@"sample.aac"];
    [[NSFileManager defaultManager] removeItemAtPath:soundFilePath
                                               error:nil];
    
    NSURL *url = [NSURL fileURLWithPath:soundFilePath];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    NSError *error = nil;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:[self audioRecordingSettings] error:&error];
    self.audioRecorder.meteringEnabled = YES;
    if ([self.audioRecorder prepareToRecord]){
        self.audioRecorder.meteringEnabled = YES;
        [self.audioRecorder record];

        self.startTime = [NSDate date];
    }
}

- (void)stopRecord:(BOOL)shouldSend {
    [self.audioRecorder stop];
    self.audioRecorder = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];

    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
    if (duration < 1.f) { // 小于1s直接忽略
        return ;
    }
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sample.aac"];
    
    if (!shouldSend) {
        [[NSFileManager defaultManager] removeItemAtPath:soundFilePath
                                                   error:nil];
        
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:soundFilePath];
    if (data.length == 0) {
        [HUD showErrorWithMessage:@"语音录制失败"];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [HUD showProgressWithMessage:@"正在上传语音..."];
        
        [[FileUploader shareInstance] uploadData:data
                            type:UploadFileTypeAudio
                   progressBlock:^(NSInteger number) {
                       [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传语音%@%%...", @(number)]];
                   }
                 completionBlock:^(NSString * _Nullable audioUrl, NSError * _Nullable error) {
                     if (audioUrl.length > 0) {
                         [[NSFileManager defaultManager] removeItemAtPath:soundFilePath
                                                                    error:nil];
                         
                         [HUD hideAnimated:YES];
                         [self sendAudioMessage:[NSURL URLWithString:audioUrl] duration:duration];
                     } else {
                         [HUD showErrorWithMessage:@"音频上传失败"];
                     }
                 }];
    });
}

- (NSDictionary *)audioRecordingSettings{
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
                              [NSNumber numberWithFloat:16000], AVSampleRateKey,
                              [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                              [NSNumber numberWithInt:AVAudioQualityMedium], AVSampleRateConverterAudioQualityKey,
                              [NSNumber numberWithInt:64000], AVEncoderBitRateKey,
                              [NSNumber numberWithInt:8], AVEncoderBitDepthHintKey,
                              nil];
    
    return settings;
}

- (void)showCurrentSelectedImage:(NSInteger)index {
    WeakifySelf;
    WBGImageEditorViewController *editVC = [[WBGImageEditorViewController alloc] init];
    [editVC setOriginalImageUrls:self.homeworkImages];
    editVC.selectIndex = index;
    [editVC setSendCallback:^(UIImage *image) {
        if (weakSelf.homeworkSession.score > 0) {
            [HUD showErrorWithMessage:@"作业已完成，不能发送"];
        } else {
            [weakSelf sendImageMessageWithImage:image];
        }
    }];
    [weakSelf.navigationController presentViewController:editVC animated:YES completion:nil];
    
    self.dontScrollWhenAppeard = YES;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self resizeInputTextView];
    
    if (textView.text.length > 0) {
        [textView scrollRangeToVisible:NSMakeRange(textView.text.length - 1, 1)];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self sendTextMessage:textView.text];
        return NO;
    }
    return YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.movie"]) {
        [self handleVideoPickerResult:picker didFinishPickingMediaWithInfo:info];
    } else {
        [self handlePhotoPickerResult:picker didFinishPickingMediaWithInfo:info];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    self.isCommitingHomework = NO;
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sortedKeys.count + 1; // 第一个是作业信息
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    
    NSString *key = self.sortedKeys[section-1];
    NSArray *messages = self.sortedMessages[key];
    
    return messages.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {// 作业内容
        NSString *nibName =  @"SessionHomeworkTableViewCell";;
        
        SessionHomeworkTableViewCell *cell = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] lastObject];
        
        [cell setupWithHomeworkSession:self.homeworkSession];
        WeakifySelf;
        [cell setStartTaskCallback:^(void) { // 开始任务
            
            NSString *typeName = self.homeworkSession.homework.typeName;
            if ([typeName isEqualToString:kHomeworkTaskFollowUpName]) {
                
                if (weakSelf.homeworkSession.score != -1)  return;
   
                MIFollowUpViewController *followUpVC = [[MIFollowUpViewController alloc] initWithNibName:NSStringFromClass([MIFollowUpViewController class]) bundle:nil];
                followUpVC.isChecking = NO;
                followUpVC.teacher = weakSelf.teacher;
                followUpVC.conversation = weakSelf.conversation;
                followUpVC.homework = weakSelf.homeworkSession.homework;
                followUpVC.finishCallBack = ^(AVIMAudioMessage *message){
                    
                    [weakSelf.messages addObject:message];
                    [weakSelf sortMessages];
                    [weakSelf reloadDataAndScrollToBottom];
                };
                [weakSelf.navigationController pushViewController:followUpVC animated:YES];
            } else if ([typeName isEqualToString:kHomeworkTaskWordMemoryName]) {
              
#if MANAGERSIDE
#else
                if (weakSelf.homeworkSession.score != -1)  return;
                MReadWordsViewController * words = [[MReadWordsViewController alloc] init];
                words.teacher = weakSelf.teacher;
                words.conversation = weakSelf.conversation;
                words.homework =  weakSelf.homeworkSession.homework;
                words.finishCallBack = ^(AVIMAudioMessage *message){
                    
                    [weakSelf.messages addObject:message];
                    [weakSelf sortMessages];
                    [weakSelf reloadDataAndScrollToBottom];
                };
                [weakSelf.navigationController pushViewController:words animated:YES];
#endif
            }
        }];
        
        [cell setVideoCallback:^(NSString *videoUrl) {
            [weakSelf playerVideoWithURL:videoUrl showSave:NO];
        }];
        
        [cell setImageCallback:^(NSString * imageUrl, UIImageView *currentImage, NSInteger index) {

            NSInteger selectIndex = [weakSelf.homeworkImages indexOfObject:imageUrl];
            [weakSelf showCurrentSelectedImage:selectIndex];
        }];
        
        [cell setAudioCallback:^(NSString * audioUrl, NSString * audioCoverUrl) {
            [weakSelf playAudioWithURL:audioUrl withCoverURL:audioCoverUrl];
        }];
        
        return cell;
    }
    // 会话内容
    if (indexPath.row == 0) { // 时间
        MessageTimeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MessageTimeTableViewCellId];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MessageTimeTableViewCell" owner:nil options:nil] lastObject];
        }
        
        NSTimeInterval time = [self.sortedKeys[indexPath.section-1] floatValue]/1000;
        NSString *timeString = [[NSDate dateWithTimeIntervalSince1970:time] timeDescription];
        
        cell.timeLabel.text = timeString;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
    
    NSString *key = self.sortedKeys[indexPath.section-1];
    NSArray *messages = self.sortedMessages[key];
    AVIMTypedMessage *message = messages[indexPath.row-1];
    UITableViewCell *cell = nil;
    
    User *user = nil;
    BOOL isPeerMessage = message.ioType==AVIMMessageIOTypeIn;
    
#if TEACHERSIDE || MANAGERSIDE
    
    if (message.clientId.integerValue == self.homeworkSession.student.userId) {
       
        user = self.homeworkSession.student;
    } else {
        user = self.homeworkSession.correctTeacher;
    }
#else
    if ([message.clientId integerValue] == APP.currentUser.userId) {
        user = APP.currentUser;
    } else {
        user = self.homeworkSession.correctTeacher;
    }
#endif

    if (message.mediaType == kAVIMMessageMediaTypeText) { // 文本信息
        NSDictionary *attributes = ((AVIMTextMessage *)(message)).attributes;
        NSString *identifier = nil;
        
        if (attributes[@"isEmoji"] != nil && [UIImage imageNamed:((AVIMTextMessage *)(message)).text]!=nil) {
            if (isPeerMessage) {
                identifier = LeftEmojiMessageTableViewCellId;
            } else {
                identifier = RightEmojiMessageTableViewCellId;
            }
            
            EmojiMessageTableViewCell *emojiCell = (EmojiMessageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
            if (emojiCell == nil) {
                NSString *nibName = isPeerMessage?@"LeftEmojiMessageTableViewCell":@"RightEmojiMessageTableViewCell";
                emojiCell = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] lastObject];
            }
            [emojiCell setupWithUser:user message:message];
            
            WeakifySelf;
            [emojiCell setResendCallback:^{
                [weakSelf sendMessage:message];
            }];
            
            cell = emojiCell;
        } else {
            if (isPeerMessage) {
                identifier = LeftTextMessageTableViewCellId;
            } else {
                identifier = RightTextMessageTableViewCellId;
            }
            
            TextMessageTableViewCell *textCell = (TextMessageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
            if (textCell == nil) {
                NSString *nibName = isPeerMessage?@"LeftTextMessageTableViewCell":@"RightTextMessageTableViewCell";
                textCell = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] lastObject];
            }
            [textCell setupWithUser:user message:message];
            
            WeakifySelf;
            [textCell setResendCallback:^{
                [weakSelf sendMessage:message];
            }];
            
            cell = textCell;
        }
    } else if (message.mediaType == kAVIMMessageMediaTypeImage) { // 图片信息
        NSString *identifier = nil;
        if (isPeerMessage) {
            identifier = LeftImageMessageTableViewCellId;
        } else {
            identifier = RightImageMessageTableViewCellId;
        }
        
        ImageMessageTableViewCell *imageCell = (ImageMessageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        if (imageCell == nil) {
            NSString *nibName = isPeerMessage?@"LeftImageMessageTableViewCell":@"RightImageMessageTableViewCell";
            imageCell = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] lastObject];
        }
        [imageCell setupWithUser:user message:message];
        
        WeakifySelf;
        [imageCell setResendCallback:^{
            [weakSelf sendMessage:message];
        }];
        
        __weak ImageMessageTableViewCell *weakCell = imageCell;
        [imageCell setImagePreviewCallback:^{
            UIImage *image = weakCell.messageImageView.image;
            if (image == nil) {
                return;
            }
            NSMutableArray * imageurls = [[NSMutableArray alloc] init];
            
            for (int i = 0; i < weakSelf.messages.count; i++)
            {
                AVIMTypedMessage * tmpMessage = weakSelf.messages[i];
                if (tmpMessage.mediaType == kAVIMMessageMediaTypeImage)
                {
                    [imageurls addObject:tmpMessage.file.url];
                }
                
            }
            
            
            WBGImageEditorViewController *editVC = [[WBGImageEditorViewController alloc] init];
            [editVC setOriginalImageUrls:imageurls];
            editVC.selectIndex = [imageurls indexOfObject:message.file.url];
//            [editVC setThumbnailImage:image];
            [editVC setSendCallback:^(UIImage *image) {
                if (weakSelf.homeworkSession.score > 0) {
                    [HUD showErrorWithMessage:@"作业已完成，不能发送"];
                } else {
                    [weakSelf sendImageMessageWithImage:image];
                }
            }];
            [weakSelf.navigationController presentViewController:editVC animated:YES completion:nil];
            
            weakSelf.dontScrollWhenAppeard = YES;
        }];
        
        cell = imageCell;
    } else if (message.mediaType == kAVIMMessageMediaTypeVideo) { // 视频信息
        NSString *identifier = nil;
        if (isPeerMessage) {
            identifier = LeftVideoMessageTableViewCellId;
        } else {
            identifier = RightVideoMessageTableViewCellId;
        }
        
        VideoMessageTableViewCell *videoCell = (VideoMessageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        if (videoCell == nil) {
            NSString *nibName = isPeerMessage?@"LeftVideoMessageTableViewCell":@"RightVideoMessageTableViewCell";
            videoCell = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] lastObject];
        }
        [videoCell setupWithUser:user message:message];
        
        WeakifySelf;
        [videoCell setVideoPlayCallback:^{
            [weakSelf playerVideoWithURL:message.file.url showSave:YES];
        }];
        
        [videoCell setResendCallback:^{
            [weakSelf sendMessage:message];
        }];
        
        cell = videoCell;
    } else if (message.mediaType == kAVIMMessageMediaTypeAudio) { // 音频信息
        NSString *identifier = nil;
        if (isPeerMessage) {
            identifier = LeftAudioMessageTableViewCellId;
        } else {
            identifier = RightAudioMessageTableViewCellId;
        }
        
        NSString *typeName = message.attributes[@"typeName"];
        if ([typeName isEqualToString:kHomeworkTaskWordMemoryName] ||
            [typeName isEqualToString:kHomeworkTaskFollowUpName]) { // 跟读，单词任务消息
            NSString *identifier = nil;
            if (isPeerMessage) {
                identifier = LeftTextMessageTableViewCellId;
            } else {
                identifier = RightTextMessageTableViewCellId;
            }
            
            TextMessageTableViewCell *textCell = (TextMessageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
            if (textCell == nil) {
                NSString *nibName = isPeerMessage?@"LeftTextMessageTableViewCell":@"RightTextMessageTableViewCell";
                textCell = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] lastObject];
            }
            message.text = typeName;
            [textCell setupWithUser:user message:message];
            
            WeakifySelf;
            [textCell setResendCallback:^{
                [weakSelf sendMessage:message];
            }];
            [textCell setClickCallback:^{// 查看作业

                NSString *typeName = self.homeworkSession.homework.typeName;
                if ([typeName isEqualToString:kHomeworkTaskFollowUpName]) {
                    
                    HomeworkItem *followItem = weakSelf.homeworkSession.homework.otherItem.firstObject;
                    [self playAudioWithURL:message.file.url withCoverURL:followItem.audioCoverUrl];
                    
                } else if ([typeName isEqualToString:kHomeworkTaskWordMemoryName]){
                   
                    MICheckWordsViewController *taskVC = [[MICheckWordsViewController alloc] initWithNibName:NSStringFromClass([MICheckWordsViewController class]) bundle:nil];
                    NSString *fileUrl = message.file.url;
                    taskVC.audioUrl = fileUrl;
                    taskVC.homework = weakSelf.homeworkSession.homework;
                    [weakSelf.navigationController pushViewController:taskVC animated:YES];
                }
            }];
            cell = textCell;
            
        } else {
            
            AudioMessageTableViewCell *audioCell = (AudioMessageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
            if (audioCell == nil) {
                NSString *nibName = isPeerMessage?@"LeftAudioMessageTableViewCell":@"RightAudioMessageTableViewCell";
                audioCell = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] lastObject];
            }
            [audioCell setupWithUser:user message:message];
            
            WeakifySelf;
            [audioCell setResendCallback:^{
                [weakSelf sendMessage:message];
            }];
            
            cell = audioCell;
        }
    }
    else
    {
        cell = [[UITableViewCell alloc] init];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    if (indexPath.section == 0) {
        
        return [SessionHomeworkTableViewCell heightWithHomeworkSession:self.homeworkSession];
    }
    
    if (indexPath.row == 0) {
        return MessageTimeTableViewCellHeight;
    }
    
    NSString *key = self.sortedKeys[indexPath.section-1];
    NSArray *messages = self.sortedMessages[key];
    
    AVIMMessage *message = messages[indexPath.row-1];
    if (message.mediaType == kAVIMMessageMediaTypeText) { // 文本信息或者emoji
        NSDictionary *attributes = ((AVIMTextMessage *)(message)).attributes;
        if (attributes[@"isEmoji"] != nil && [UIImage imageNamed:((AVIMTextMessage *)(message)).text]!=nil) {
            return EmojiMessageTableViewCellHeight;
        }
        
        return [TextMessageTableViewCell heightOfMessage:(AVIMTypedMessage *)message];
    } else if (message.mediaType == kAVIMMessageMediaTypeImage) {
        return ImageMessageTableViewCellHeight;
    } else if (message.mediaType == kAVIMMessageMediaTypeVideo) {
        return VideoMessageTableViewCellHeight;
    } else if (message.mediaType == kAVIMMessageMediaTypeAudio) {
        
        NSString *typeName = ((AVIMTypedMessage*)message).attributes[@"typeName"];
        if ([typeName isEqualToString:kHomeworkTaskWordMemoryName] ||
            [typeName isEqualToString:kHomeworkTaskFollowUpName]) {
            return [TextMessageTableViewCell heightOfMessage:(AVIMTypedMessage *)message];
        } else {
            return AudioMessageTableViewCellHeight;
        }
    }
    
    return 0.f;
}

#pragma mark - UIScrollViewDelegate
#if TEACHERSIDE || MANAGERSIDE
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    CGFloat height = [SessionHomeworkTableViewCell heightWithHomeworkSession:self.homeworkSession];
    // 教师端批改备注置顶
    if (self.homeworkSession.homework.teremark.length) {
        
        if (scrollView.contentOffset.y >= height - kNaviBarHeight) {
            if (!self.teremarkView) {
                
                self.teremarkView = [[UIView alloc] init];
                self.teremarkView.backgroundColor = [UIColor whiteColor];
                self.teremarkLabel = [[UILabel alloc] init];
                self.teremarkLabel.textColor = [UIColor colorWithHex:0x05ABFA];
                self.teremarkLabel.numberOfLines = 0;
                self.teremarkLabel.backgroundColor = [UIColor whiteColor];
                [self.teremarkView addSubview:self.teremarkLabel];
            }
            NSString * teremark = [NSString stringWithFormat:@"注：%@",self.homeworkSession.homework.teremark];
            NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.lineSpacing = 5;
            NSDictionary *dic = @{NSParagraphStyleAttributeName:paragraphStyle,NSFontAttributeName:[UIFont systemFontOfSize:14]};
            NSMutableAttributedString * teremarkAtt = [[NSMutableAttributedString alloc] initWithString:teremark attributes:dic];
            
            NSStringDrawingOptions options =  NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
            CGSize rect = [teremark boundingRectWithSize:CGSizeMake(ScreenWidth - 20,MAXFLOAT) options:options attributes:dic context:nil].size;
            
            self.teremarkView.frame = CGRectMake(0, kNaviBarHeight, ScreenWidth, rect.height + 20);
            self.teremarkLabel.frame = CGRectMake(10, 0, ScreenWidth - 20, rect.height + 20);
            self.teremarkLabel.attributedText = teremarkAtt;
            [self.view addSubview:self.teremarkView];
        } else {
            if (self.teremarkView.superview) {
                
                [self.teremarkView removeFromSuperview];
            }
        }
    }
}
#else
#endif

#pragma mark - VIResourceLoaderManagerDelegate
- (void)resourceLoaderManagerLoadURL:(NSURL *)url didFailWithError:(NSError *)error
{
    //播放失败清除缓存
    [VICacheManager cleanCacheForURL:url error:nil];
    // 适配ipad版本
    UIAlertControllerStyle alertStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        alertStyle = UIAlertControllerStyleActionSheet;
    } else {
        alertStyle = UIAlertControllerStyleAlert;
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil
                                                                     message:@"播放失败"
                                                              preferredStyle:alertStyle];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           [self dismissViewControllerAnimated:YES completion:^{
                                                               
                                                           }];
                                                       }];
    
    [alertVC addAction:cancelAction];

    [self presentViewController:alertVC
                     animated:YES
                   completion:nil];
    
}

#pragma mark - EmojiInputViewDelegate
- (void)emojiDidSelect:(NSString *)emojiText {
    
    NSString * text = [self.inputTextView.text stringByAppendingString:emojiText];
    self.inputTextView.text = text;
   // [self sendEmojiMessage:emojiText];
}

- (void)emojiDidSend
{
    [self sendTextMessage:self.inputTextView.text];
}

#pragma mark - 获取作业内容
- (void)requestHomeworkDetail{

    [self.loadingContainerView showLoadingView];
    [HomeworkSessionService requestHomeworkSessionWithId:self.homeworkSession.homeworkSessionId callback:^(Result *result, NSError *error) {
        
        [self.loadingContainerView hideAllStateView];
        if (error) {
            [self.loadingContainerView showFailureViewWithRetryCallback:^{
                [self requestHomeworkDetail];
            }];
            return ;
        } else {
            HomeworkSession *session = (HomeworkSession *)(result.userInfo);
            if (session) {
                self.homeworkSession = session;
              
                if ((session.correctTeacher.userId > 0) && (session.student.userId > 0)) {
                    [self setupConversation];
                } else {
                    [self.loadingContainerView showFailureViewWithRetryCallback:^{
                        [self requestHomeworkDetail];
                    }];
                }
            }
            [self updateData];
        }
    }];
}

#pragma mark - 更新

- (void)updateData{
    
#if TEACHERSIDE || MANAGERSIDE
    
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:self.homeworkSession.student.nickname];
    if (self.homeworkSession.stuLabel > 0) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:[NSString stringWithFormat:@"icon_sign_mark%lu",self.homeworkSession.stuLabel]];
        NSAttributedString *emptyStr = [[NSAttributedString alloc] initWithString:@"  "];
        NSAttributedString *imageStr = [NSAttributedString attributedStringWithAttachment:attachment];
        [attrStr appendAttributedString:emptyStr];
        [attrStr appendAttributedString:imageStr];
    }
    self.customTitleLabel.attributedText = attrStr;
#else
    self.customTitleLabel.text = self.homeworkSession.correctTeacher.nickname;
#endif
    
    // -1表示未批改过
    if (self.homeworkSession.score >= 0) {
        
        [self setupResultView];
        self.resultView.hidden = NO;
        self.inputView.hidden = YES;
    } else {
        
        self.resultView.hidden = YES;
        self.inputView.hidden = NO;
        
#if MANAGERSIDE
        // 管理端非当前账号会话页不允许输入
        if (self.teacher.userId != APP.currentUser.userId) {
            self.inputViewBottomConstraint.constant = -60;
        }  else {
            self.inputViewBottomConstraint.constant = 0;
        }
#endif
    }
    [self.messagesTableView reloadData];
}

- (void)configureUI{
    
#if TEACHERSIDE
    self.correctButton.hidden = NO;
    self.answerViewWidthConstraint.constant = ScreenWidth/4;
    self.warnViewWidthConstraint.constant = ScreenWidth/4;
    
#elif MANAGERSIDE
    
    self.correctButton.hidden = NO;
    self.answerViewWidthConstraint.constant = kColumnThreeWidth/4;
    self.warnViewWidthConstraint.constant = kColumnThreeWidth/4;
#else
    self.correctButton.hidden = YES;
    self.answerViewWidthConstraint.constant = 0;
    self.warnViewWidthConstraint.constant = 0;
#endif
    
    self.recordButton.hidden = YES;
    self.recordButton.layer.borderWidth = 0.5f;
    self.recordButton.layer.borderColor = [UIColor colorWithHex:0x333333].CGColor;
    self.recordButton.layer.cornerRadius = 12.f;
    self.recordButton.layer.masksToBounds = YES;
    WeakifySelf;
    self.recordButton.stateChangeBlock = ^(RecordButtonState state) {
        if (state == RecordButtonStateTouchCancelled ||
            state == RecordButtonStateTouchUpInside ||
            state == RecordButtonStateTouchUpOutside) {
            weakSelf.recordButton.backgroundColor = [UIColor whiteColor];
        } else {
            weakSelf.recordButton.backgroundColor = [UIColor colorWithHex:0xCCCCCC];
        }
        
        if (state == RecordButtonStateTouchDown) {
            [weakSelf startRecord];
            
            weakSelf.recordStateView = [RecordStateView showInView:weakSelf.view];
        } else if (state == RecordButtonStateMoveInside) {
            [weakSelf.recordStateView updateWithCancelState:NO];
        } else if (state == RecordButtonStateMoveOutside) {
            [weakSelf.recordStateView updateWithCancelState:YES];
        } else if (state == RecordButtonStateTouchUpInside) {
            [weakSelf.recordStateView hide];
            [weakSelf stopRecord:YES];
        } else if (state == RecordButtonStateTouchUpOutside ||
                   state == RecordButtonStateTouchCancelled) {
            [weakSelf.recordStateView hide];
            [weakSelf stopRecord:NO];
        }
    };
    
    self.inputTextBgView.layer.cornerRadius = 12.f;
    self.inputTextBgView.layer.masksToBounds = YES;
    self.inputTextView.textContainerInset = UIEdgeInsetsZero;
    self.inputTextViewHeightConstraint.constant = self.inputTextView.font.lineHeight;
    
    self.messagesTableView.estimatedRowHeight = 0.f;
    self.messagesTableView.estimatedSectionFooterHeight = 0.f;
    self.messagesTableView.estimatedSectionHeaderHeight = 0.f;
    
    UIView *footerView = [[UIView alloc] init];
    [footerView setBackgroundColor:[UIColor colorWithHex:0xF5F5F5]];
    [footerView setFrame:CGRectMake(0, 0, ScreenWidth, 20)];
    self.messagesTableView.tableFooterView = footerView;
    
    self.emojiViewBottomLayoutConstraint.constant = -216.f - (isIPhoneX?39:0);
    self.operationsViewBottomConstraint.constant = -80.f - (isIPhoneX?39:0);
}

- (void)setupResultView {
    UIColor *bgColor = nil;
    NSString *text = nil;
    
    self.start1ImageView.hidden = self.homeworkSession.score<1;
    self.start2ImageView.hidden = self.homeworkSession.score<2;
    self.start3ImageView.hidden = self.homeworkSession.score<3;
    self.start4ImageView.hidden = self.homeworkSession.score<4;
    self.start5ImageView.hidden = self.homeworkSession.score<5;
    
    if (self.homeworkSession.score == 0) {
        bgColor = [UIColor lightGrayColor];
    }else if (self.homeworkSession.score == 1) {
        text = @"Pass!";
        bgColor = [UIColor colorWithHex:0x28C4B7];
    } else if (self.homeworkSession.score == 2) {
        text = @"Good job!";
        bgColor = [UIColor colorWithHex:0x00CE00];
    } else if (self.homeworkSession.score == 3) {
        text = @"Very nice!";
        bgColor = [UIColor colorWithHex:0x0098FE];
    } else if (self.homeworkSession.score == 4) {
        text = @"Great!";
        bgColor = [UIColor colorWithHex:0xFFC600];
    } else if (self.homeworkSession.score == 5) {
        text = @"Perfect!";
        bgColor = [UIColor colorWithHex:0xFF4858];
    } else if (self.homeworkSession.score == 6) {
        text = @"Very hardworking!";
        bgColor = [UIColor colorWithHex:0xB248FF];
    }
    
    self.scoreLabel.text = self.homeworkSession.reviewText;
    
    self.resultContentView.backgroundColor = bgColor;
    self.resultPaddingView.backgroundColor = bgColor;
    
#if TEACHERSIDE || MANAGERSIDE
    self.retryButton.hidden = YES;
#else
    if (self.homeworkSession.isRedo)
    {
        self.retryButton.backgroundColor = bgColor;
        self.retryButton.layer.cornerRadius = 12.f;
        self.retryButton.layer.masksToBounds = YES;
        self.retryButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.retryButton.layer.borderWidth = 1;
        self.retryButton.hidden = NO;
    }
#endif
}


- (void)dealloc {
    
    APP.currentIMHomeworkSessionId = 0;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"%s", __func__);
}


@end


