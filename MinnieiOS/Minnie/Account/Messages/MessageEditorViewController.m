//
//  MessageEditorViewController.m
//  NECatoonReader
//
//  Created by yebw on 15/8/20.
//  Copyright (c) 2015年 netease. All rights reserved.
//

#import "MessageEditorViewController.h"
#import "UITextView+Placeholder.h"
#import "UIColor+HEX.h"
#import "ImageTextAttachment.h"
#import "MessageService.h"
#import "NoticeMessage.h"
#import "NoticeMessageItem.h"
#import "FileUploader.h"
#import "PushManager.h"

#import <SDWebImage/SDWebImageManager.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Mantle/Mantle.h>
#import <Masonry/Masonry.h>

#import "ClassAndStudentSelectorController.h"

const NSUInteger kMessageEditorMinNumberOfTitleCharactors = 1; // 标题最少的字数
const NSUInteger kMessageEditorMaxNumberOfTitleCharactors = 30; // 标题最多字数
const NSUInteger kMessageEditorMaxNumberOfContentImages = 3; // 正文最多插图
const NSUInteger kMessageEditorMinNumberOfContentCharactors = 0; // 正文最少的字数
const NSUInteger kMessageEditorMaxNumberOfContentCharactors = 500; // 正文最多的字数
const CGFloat kMessageEditorCustomNavigationBarHeight = 44.f;
const CGFloat kMessageEditorMargin = 16.f;

typedef NS_ENUM(NSUInteger, TextAttachmentType) {
    TextAttachmentImage,
};

@interface MessageEditorViewController ()
<UITextViewDelegate,
NSTextStorageDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
UIGestureRecognizerDelegate,
ClassAndStudentSelectorControllerDelegate>

@property(nonatomic, assign) BOOL everAppeard; // 该视图控制器实例是否是已经展示过，第一次展示的时候需要处理加载默认内容

@property(nonatomic, weak) IBOutlet NSLayoutConstraint *titleViewTopLayoutConstraint;
@property(nonatomic, weak) IBOutlet NSLayoutConstraint *titleViewHeightLayoutConstraint;
@property(nonatomic, weak) IBOutlet NSLayoutConstraint *bottomViewBottomLayoutConstraint;

@property(nonatomic, weak) IBOutlet UIButton *closeButton;
@property(nonatomic, weak) IBOutlet UITextView *titleTextView;
@property(nonatomic, weak) IBOutlet UITextView *contentTextView;

@property(nonatomic, strong) UIImage *placeholder;

@property(nonatomic, strong) NSDictionary *textAttibutes;
@property(nonatomic, assign) BOOL isFromAttachmentPicker;
@property(nonatomic, assign) BOOL imageInserted;

@property(nonatomic, strong) NoticeMessage *noticeMessage;

@property(nonatomic, strong) BaseRequest *sendRequest;

@property(nonatomic, strong) NSURLSessionTask *uploadImageTask;

@property(nonatomic, assign) CGFloat lastOffset;

@property(nonatomic, assign) NSTimeInterval updateTime;

@property(nonatomic, assign) BOOL contentViewFirstLocationFocused; // 用来做光标定位到contentView第一位的标记，在自动插入书籍的逻辑中用到

@property(nonatomic, strong) ClassAndStudentSelectorController *seletorVC;

@property(nonatomic, strong) NSArray *selectedClasses;
@property(nonatomic, strong) NSArray *selectedStudents;

@end

@implementation MessageEditorViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
        paragrahStyle.lineSpacing = 2;
        paragrahStyle.alignment = NSTextAlignmentLeft;
        _textAttibutes = @{NSForegroundColorAttributeName:[UIColor colorWithHex:0x666666 alpha:1.0],
                           NSFontAttributeName:[UIFont systemFontOfSize:16.f],
                           NSParagraphStyleAttributeName:paragrahStyle};
        
        _lastOffset = 0.f;
        
        // 监听键盘改变事件
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardFrameWillChange:)
                                                     name:UIKeyboardWillChangeFrameNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardFrameDidChange:)
                                                     name:UIKeyboardDidChangeFrameNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textViewImageLoadDidSuccess:)
                                                     name:kNotificationOfTextViewImageLoadDidSuccess
                                                   object:nil];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 设置导航栏
    [self setupNavigationBar];
    
    // 设置标题栏的样式
    [self setupTitleTextView];
    
    // 设置内容区域的样式
    [self setupContentTextView];
    
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(hidesKeyboard)];
    [self.view addGestureRecognizer:tapGR];
    
    UISwipeGestureRecognizer *swipeGR = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(showTitleView:)];
    [swipeGR setDirection:UISwipeGestureRecognizerDirectionDown];
    [swipeGR setDelegate:self];
    [self.contentTextView addGestureRecognizer:swipeGR];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.everAppeard) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.updateTime = 0;
            
            NSAttributedString *attributedText = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.titleTextView.text = self.noticeMessage.title;
                self.contentTextView.attributedText = attributedText;
                
                if (self.noticeMessage.title.length > 0) {
                    CGFloat width = ScreenWidth - 2 * kMessageEditorMargin;
                    CGSize maxSize = CGSizeMake(width, CGFLOAT_MAX);
                    CGFloat height = ceil([self.titleTextView.text boundingRectWithSize:maxSize
                                                                                options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                                             attributes:@{NSFontAttributeName:self.titleTextView.font}
                                                                                context:nil].size.height);
                    self.titleViewHeightLayoutConstraint.constant = MAX(24.f, height) + 2 * kMessageEditorMargin;
                    [self.titleTextView scrollRangeToVisible:NSMakeRange(0, 1)];
                } else {
                    self.titleTextView.contentOffset = CGPointZero;
                }
            });
        });
        
        self.everAppeard = YES;
    } else {
        if (self.titleTextView.text.length > 0) {
            [self.titleTextView scrollRangeToVisible:NSMakeRange(0, 1)];
        } else {
            self.titleTextView.contentOffset = CGPointZero;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.isFromAttachmentPicker && !self.contentViewFirstLocationFocused) {
        [self.titleTextView becomeFirstResponder];
    } else {
        [self.contentTextView becomeFirstResponder];
        
        if (self.contentViewFirstLocationFocused) {
            [self.contentTextView setSelectedRange:NSMakeRange(0, 0)];
            self.contentViewFirstLocationFocused = NO;
        }
    }
}

#pragma mark - IBActions

- (IBAction)closeButtonPressed:(id)sender {
    [self closeEditor];
}

- (IBAction)albumButtonPressed:(id)sender {
    NSUInteger numberOfImages = [self numberOfImagesInTextView];
    if (numberOfImages > kMessageEditorMaxNumberOfContentImages) {
        [HUD showErrorWithMessage:[NSString stringWithFormat:@"最多%@张图片", @(kMessageEditorMaxNumberOfContentImages)]];
        
        return;
    }
    
    [self.titleTextView resignFirstResponder];
    [self.contentTextView resignFirstResponder];
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    //    imagePickerController.allowsEditing = YES;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:imagePickerController animated:YES completion:nil];
}

// 发送按钮点击
- (IBAction)sendMessageButtonPressed {
    [self makeMessageForUploading];
    
    // 正文不能为空
    NSString *text = [self.contentTextView.attributedText.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (self.noticeMessage.items.count == 0 || text.length==0) {
        [HUD showErrorWithMessage:@"消息内容不能为空"];
        return;
    }

    [self.titleTextView resignFirstResponder];
    [self.contentTextView resignFirstResponder];
    
    // 检查格式：是否满足字数限制
    if (![self checkTitleAndContent]) {
        return;
    }
    // 发送消息
    ClassAndStudentSelectorController *vc = [[ClassAndStudentSelectorController alloc] init];
    vc.delegate = self;
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:vc animated:YES completion:nil];

    self.seletorVC = vc;
}

#pragma mark - Private Methods

- (void)setupNavigationBar {
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)setupTitleTextView {
    [self.titleTextView setDelegate:self];
    [self.titleTextView setPlaceholderColor:[UIColor colorWithHex:0xCCCCCC]];
    [self.titleTextView setPlaceholder:@"输入标题，最多30个字"];
    [self.titleTextView setTextColor:[UIColor colorWithHex:0x666666]];
    [self.titleTextView setTextContainerInset:UIEdgeInsetsZero];
    [self.titleTextView setContentInset:UIEdgeInsetsZero];
    [self.titleTextView.textContainer setLineFragmentPadding:0];
}

- (void)setupContentTextView {
    [self.contentTextView.textStorage setDelegate:self];
    [self.contentTextView setDelegate:self];
    [self.contentTextView setPlaceholderColor:[UIColor colorWithHex:0xCCCCCC]];
    [self.contentTextView setPlaceholder:@"正文字数限制500字"];
    [self.contentTextView setTextContainerInset:UIEdgeInsetsMake(16, 16, 16, 16)];
    [self.contentTextView.textContainer setLineFragmentPadding:0];
}

- (UIImage *)placeholder {
    if (_placeholder != nil) {
        return _placeholder;
    }
    
    CGRect rect = CGRectMake(0, 0, 10, 10);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithHex:0xCCCCCC].CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)closeEditor {
    [self.uploadImageTask cancel];
    
    [self.titleTextView resignFirstResponder];
    [self.contentTextView resignFirstResponder];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSUInteger)numberOfCharactors {
    //    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    
    NSUInteger numberOfCharactors = 0;
    
    // 找出全部的附件
    NSMutableArray *attachmentRanges = [NSMutableArray array];
    NSMutableArray<ImageTextAttachment *> *attachments = [NSMutableArray array];
    
    [self.contentTextView.attributedText enumerateAttribute:NSAttachmentAttributeName
                                                    inRange:NSMakeRange(0, self.contentTextView.attributedText.length)
                                                    options:0
                                                 usingBlock:^(id value, NSRange range, BOOL *stop) {
                                                     if ([value isKindOfClass:[ImageTextAttachment class]]) {
                                                         ImageTextAttachment *attachment = (ImageTextAttachment *)value;
                                                         UIImage *image = attachment.image;
                                                         if (image != nil) {
                                                             [attachmentRanges addObject:NSStringFromRange(range)];
                                                             [attachments addObject:attachment];
                                                         }
                                                     }
                                                 }];
    
    // 如果没有附件，整个是纯文本
    if (attachments.count == 0) {
        if (self.contentTextView.attributedText.string.length > 0) {
            numberOfCharactors += [self.contentTextView.attributedText.string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]].length;
        }
    } else {
        // 遍历段落
        for (NSInteger index=0; index<attachments.count; index++) {
            @autoreleasepool {
                NSRange attachmentRange = NSRangeFromString(attachmentRanges[index]);
                
                if (index == 0) { // 第一个附件前有文字
                    if (attachmentRange.location > 0) {
                        NSRange textRange = NSMakeRange(0, attachmentRange.location);
                        NSAttributedString *attributedString = [self.contentTextView.attributedText attributedSubstringFromRange:textRange];
                        NSString *text = attributedString.string;
                        if ([text hasSuffix:@"\n"]) {
                            NSString *t = [text substringToIndex:text.length-1];
                            t = [[t stringByAppendingString:@"*"] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                            t = [t substringToIndex:t.length-1];
                            
                            numberOfCharactors += t.length;
                        } else {
                        }
                    }
                }
                
                if (index == attachments.count - 1) { // 最后一个前有文字
                    if (attachmentRange.location+attachmentRange.length < self.contentTextView.attributedText.length) {
                        NSRange textRange = NSMakeRange(attachmentRange.location+attachmentRange.length, self.contentTextView.attributedText.length-attachmentRange.location-attachmentRange.length);
                        NSAttributedString *attributedString = [self.contentTextView.attributedText attributedSubstringFromRange:textRange];
                        NSString *text = attributedString.string;
                        
                        if ([text hasPrefix:@"\n"]) {
                            NSString *t = [text substringFromIndex:1];
                            
                            // 最后的部分，还要把最后面的空行去掉
                            t = [[@"*" stringByAppendingString:t] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            t = [t substringFromIndex:1];
                            
                            numberOfCharactors += t.length;
                        } else {
                        }
                    }
                }
                
                if (index > 0) {
                    NSRange previousAttachmentRange = NSRangeFromString(attachmentRanges[index-1]);
                    NSRange currentAttachmentRange = NSRangeFromString(attachmentRanges[index]);
                    
                    NSUInteger length = currentAttachmentRange.location - previousAttachmentRange.location - previousAttachmentRange.length;
                    if (length > 2) { // 前后各一个回车
                        numberOfCharactors += length - 2;
                    } else if (length == 2) {
                        numberOfCharactors += 1;
                    }
                }
            }
        }
    }
    
    //    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    //    NSLog(@"%.2fms", (end - start)*1000);
    
    return numberOfCharactors;
}

// 上传图片
- (void)uploadImages:(NSArray *)imageDatas
        messageItems:(NSArray *)items
           withIndex:(NSInteger)index
       uploadedCount:(NSUInteger)uploadedCount
{
    [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传图片%@/%@", @(index+1+uploadedCount), @(imageDatas.count+uploadedCount)] cancelCallback:^{
        [self.uploadImageTask cancel];
        self.uploadImageTask = nil;
        
        [HUD showProgressWithMessage:@"已取消"];
    }];
    
    NSDictionary *dict = imageDatas[index];
    NSData *data = dict[@"imageData"];
    
    [HUD showProgressWithMessage:@"正在上传图片..."];
    
    QNUploadOption * option = [[QNUploadOption alloc] initWithProgressHandler:^(NSString *key, float percent) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传图片%.f%%...", percent * 100]];
        });
        
    }];
    
    [[FileUploader shareInstance] qn_uploadData:data type:UploadFileTypeImage option:option completionBlock:^(NSString * _Nullable imageUrl, NSError * _Nullable error) {
        if (imageUrl.length == 0) {
            [HUD showErrorWithMessage:@"图片上传失败"];
            
            return;
        }
        
        NoticeMessageItem *item = items[index];
        item.imageUrl = imageUrl;
        ((ImageTextAttachment *)(item.attachment)).imageUrl = item.imageUrl;
        
        if (index == imageDatas.count-1) { // 最后一张图片上传完了
            [HUD showProgressWithMessage:@"正在发送消息..."];
            
            [self sendMessage];
        } else {
            [self uploadImages:imageDatas
                  messageItems:items
                     withIndex:index+1
                 uploadedCount:uploadedCount];
        }
    }];
    
//    [[FileUploader shareInstance] uploadData:data
//                        type:UploadFileTypeImage
//               progressBlock:^(NSInteger number) {
//                   [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传图片%@%%...", @(number)]];
//               }
//             completionBlock:^(NSString * _Nullable imageUrl, NSError * _Nullable error) {
//                 if (imageUrl.length == 0) {
//                     [HUD showErrorWithMessage:@"图片上传失败"];
//
//                     return;
//                 }
//
//                 NoticeMessageItem *item = items[index];
//                 item.imageUrl = imageUrl;
//                 ((ImageTextAttachment *)(item.attachment)).imageUrl = item.imageUrl;
//
//                 if (index == imageDatas.count-1) { // 最后一张图片上传完了
//                     [HUD showProgressWithMessage:@"正在发送消息..."];
//
//                     [self sendMessage];
//                 } else {
//                     [self uploadImages:imageDatas
//                           messageItems:items
//                              withIndex:index+1
//                          uploadedCount:uploadedCount];
//                 }
//             }];
}

- (BOOL)checkTitleAndContent
{
    BOOL result = NO;
    
    do {
        if (self.noticeMessage.title.length < kMessageEditorMinNumberOfTitleCharactors) {
            [HUD showErrorWithMessage:[NSString stringWithFormat:@"标题最少%@字", @(kMessageEditorMinNumberOfTitleCharactors)]];
            
            break;
        } else if (self.noticeMessage.title.length > kMessageEditorMaxNumberOfTitleCharactors) {
            [HUD showErrorWithMessage:[NSString stringWithFormat:@"标题最多%@字", @(kMessageEditorMaxNumberOfTitleCharactors)]];
            break;
        }
        
        NSUInteger numberOfCharactors = [self numberOfCharactors];
        if (numberOfCharactors < kMessageEditorMinNumberOfContentCharactors) {
            [HUD showErrorWithMessage:[NSString stringWithFormat:@"正文最少%@字", @(kMessageEditorMinNumberOfContentCharactors)]];
            break;
        } else if (numberOfCharactors > kMessageEditorMaxNumberOfContentCharactors) {
            [HUD showErrorWithMessage:[NSString stringWithFormat:@"正文最多%@字", @(kMessageEditorMaxNumberOfContentCharactors)]];
            break;
        }
        
        result = YES;
    }while(NO);
    
    return result;
}

- (void)sendMessage
{
    if (self.selectedClasses.count == 0 && self.selectedStudents.count == 0) {
        [HUD showErrorWithMessage:@"请选择要发送消息的班级或者学生"];

        return;
    }

    NSMutableArray *classIds = [NSMutableArray array];
    if (self.selectedClasses.count > 0) {
        for (Clazz *cls in self.selectedClasses) {
            [classIds addObject:@(cls.classId)];
        }
    }
    
    NSMutableArray *studentIds = [NSMutableArray array];
    if (self.selectedStudents.count > 0) {
        for (User *student in self.selectedStudents) {
            [studentIds addObject:@(student.userId)];
        }
    }
    
    self.noticeMessage.classIds = classIds;
    self.noticeMessage.studentIds = studentIds;
    
    [HUD showProgressWithMessage:@"正在发布"];

    [self.sendRequest stop];
    WeakifySelf;
    self.sendRequest = [MessageService sendNoticeMessage:self.noticeMessage
                                                  callback:^(Result *result, NSError *error) {
                                                      StrongifySelf;
                                                      if (error != nil) {
                                                          [HUD showErrorWithMessage:@"发布失败"];
                                                          return;
                                                      }
                                                      
                                                      if (classIds.count > 0) {
                                                          [PushManager pushText:@"你有一条新的通知" toClasses:classIds];
                                                      }
                                                      
                                                      if (studentIds.count > 0) {
                                                          [PushManager pushText:@"你有一条新的通知" toUsers:studentIds];
                                                      }

                                                      [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfSendNoticeMessage object:nil userInfo:nil];
                                                      
                                                      [HUD showWithMessage:@"发布成功"];
                                                      
                                                      strongSelf.noticeMessage = nil;
                                                      
                                                      
                                                      if (strongSelf.seletorVC != nil) {
                                                          [strongSelf.seletorVC dismissViewControllerAnimated:YES
                                                                                                   completion:^{
                                                                                                       [strongSelf closeEditor];
                                                                                                   }];
                                                      } else {
                                                          [strongSelf closeEditor];
                                                      }
                                                  }];
}

// 隐藏键盘
- (void)hidesKeyboard {
    [self.titleTextView resignFirstResponder];
    [self.contentTextView resignFirstResponder];
}

- (void)showTitleView:(UISwipeGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateRecognized) {
        if ((self.contentTextView.contentSize.height > self.contentTextView.bounds.size.height && self.contentTextView.contentOffset.y < 0.f) ||
            self.contentTextView.contentSize.height <= self.contentTextView.bounds.size.height) {
            if (self.titleViewTopLayoutConstraint.constant != 0.f) {
                self.titleViewTopLayoutConstraint.constant = 0.f;
                [UIView animateWithDuration:0.15
                                 animations:^{
                                     [self.titleTextView.superview.superview layoutIfNeeded];
                                 }];
            }
        }
    }
}

// 唯一文件名
- (NSString *)uniqueRadomFileName {
    CFUUIDRef uuidObj = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuid = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuidObj);
    CFRelease(uuidObj);
    
    return uuid;
}

// 生成合适尺寸的图
- (UIImage *)editedImageWithImage:(UIImage *)originalImage {
    // 先看确定尺寸
    CGSize size = [[self class] editImageSizeWithOriginalImageSize:originalImage.size];
    CGFloat width = size.width;
    CGFloat height = size.height;
    
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

+ (CGSize)editImageSizeWithOriginalImageSize:(CGSize)imageSize {
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    if (width<=0.f || height<=0.f) {
        return CGSizeZero;
    }
    
    if (width>=1920.f || height>=5760.f) {
        CGFloat ratio = width / height;
        if (ratio >= 1/3.f) {
            width = MIN(width, 1920.f);
            height = width / ratio;
        } else {
            width = MIN(width, 1280.f);
            height = width / ratio;
        }
    }
    
    return CGSizeMake(width, height);
}

// 生成一个noticeMessage;
- (void)makeMessageForUploading {
    NSMutableArray<NoticeMessageItem *> *items = [NSMutableArray array];
    self.noticeMessage = [[NoticeMessage alloc] init];
    self.noticeMessage.items = items;
    self.noticeMessage.title = [self.titleTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // 找出全部的附件
    NSMutableArray *attachmentRanges = [NSMutableArray array];
    NSMutableArray<ImageTextAttachment *> *attachments = [NSMutableArray array];
    
    [self.contentTextView.attributedText enumerateAttribute:NSAttachmentAttributeName
                                                    inRange:NSMakeRange(0, self.contentTextView.attributedText.length)
                                                    options:0
                                                 usingBlock:^(id value, NSRange range, BOOL *stop) {
                                                     if ([value isKindOfClass:[ImageTextAttachment class]]) {
                                                         ImageTextAttachment *attachment = (ImageTextAttachment *)value;
                                                         if (attachment.image!=nil || attachment.imageUrl.length>0) {
                                                             [attachmentRanges addObject:NSStringFromRange(range)];
                                                             [attachments addObject:attachment];
                                                         }
                                                     }
                                                 }];
    
    // 如果没有附件，整个是纯文本， 去掉首尾的换行
    if (attachments.count == 0) {
        NSString *text = [self.contentTextView.attributedText.string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        if (text.length > 0) {
            NoticeMessageItem *item = [[NoticeMessageItem alloc] init];
            item.type = NoticeMessageItemTypeText;
            item.text = text;
            
            [items addObject:item];
        }
        
        return;
    }
    
    // 遍历段落
    NSInteger lastLocation = 0;
    for (NSInteger index=0; index<attachments.count; index++) {
        @autoreleasepool {
            NSRange attachmentRange = NSRangeFromString(attachmentRanges[index]);
            if (attachmentRange.location > lastLocation) { // 说明之间有文字
                NSRange textRange = NSMakeRange(lastLocation, attachmentRange.location-lastLocation);
                NSAttributedString *attributedString = [self.contentTextView.attributedText attributedSubstringFromRange:textRange];
                NSString *text = attributedString.string;
                if ([text hasSuffix:@"\n"]) {
                    text = [text substringToIndex:text.length-1];
                    
                    // 如果是最开始的部分，还要把最前面的空行去掉
                    if (index == 0) {
                        NSString *t = [[text stringByAppendingString:@"*"] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                        text = [t substringToIndex:t.length-1];
                    } else {
                        if ([text hasPrefix:@"\n"] && text.length>1) {
                            text = [text substringFromIndex:1];
                        }
                    }
                    
                    if (text.length > 0) {
                        NoticeMessageItem *item = [[NoticeMessageItem alloc] init];
                        item.type = NoticeMessageItemTypeText;
                        item.text = text;
                        
                        [items addObject:item];
                    }
                }
            }
            
            ImageTextAttachment *attachment = attachments[index];
            
            NoticeMessageItem *item = [[NoticeMessageItem alloc] init];
            item.attachment = attachment;
            
            if (attachment.imageUrl.length > 0) {
                item.imageUrl = attachment.imageUrl;
                
                if (attachment.image == nil) {
                    item.imageWidth = MAX(0, attachment.attachmentSize.width);
                    item.imageHeight = MAX(0, attachment.attachmentSize.height);
                }
            }
            
            if (attachment.image != nil) {
                item.imageWidth = MAX(0, attachment.image.size.width);
                item.imageHeight = MAX(0, attachment.image.size.height);
            }
            
            if ([attachment isMemberOfClass:[ImageTextAttachment class]]) { // 图片
                item.type = NoticeMessageItemTypeImage;
                
                [items addObject:item];
            }
            lastLocation = attachmentRange.location + attachmentRange.length;
            
            // 最后还有文字
            if (index == attachments.count-1 && attachmentRange.location+attachmentRange.length<self.contentTextView.attributedText.length) {
                NSRange textRange = NSMakeRange(attachmentRange.location+attachmentRange.length, self.contentTextView.attributedText.length-attachmentRange.location-attachmentRange.length);
                NSAttributedString *attributedString = [self.contentTextView.attributedText attributedSubstringFromRange:textRange];
                NSString *text = attributedString.string;
                
                if ([text hasPrefix:@"\n"]) {
                    text = [text substringFromIndex:1];
                    
                    // 最后的部分，还要把最后面的空行去掉
                    NSString *t = [[@"*" stringByAppendingString:text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    text = [t substringFromIndex:1];
                    
                    if (text.length > 0) {
                        NoticeMessageItem *item = [[NoticeMessageItem alloc] init];
                        item.type = NoticeMessageItemTypeText;
                        item.text = text;
                        
                        [items addObject:item];
                    }
                }
            }
        }
    }
}

- (void)uploadImagesAndSendMessage {
    // 如果有图片，需要先上传图片获取URL
    NSUInteger numberOfImagesUnuploaded = 0;
    NSUInteger numberOfImages = 0;
    for (NoticeMessageItem *item in self.noticeMessage.items) {
        if ([item.type isEqualToString:NoticeMessageItemTypeImage]) {
            numberOfImages++;
            
            if (item.imageUrl.length == 0) {
                item.imageUrl = ((ImageTextAttachment *)(item.attachment)).imageUrl;
            }
            
            if (item.imageUrl.length == 0) {
                numberOfImagesUnuploaded++;
            }
        }
    }
    
    if (numberOfImagesUnuploaded > 0) {
        [HUD showProgressWithMessage:@"正在处理图片"];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *imageDatas = [NSMutableArray array];
            NSMutableArray *imageMessageItems = [NSMutableArray array];
            NSUInteger threshold = 1024 * 1024;
            
            for (NSInteger index=0; index<self.noticeMessage.items.count; index++) {
                NoticeMessageItem *item = self.noticeMessage.items[index];
                if (![item.type isEqualToString:NoticeMessageItemTypeImage] || (item.imageUrl.length>0)) {
                    continue;
                }
                
                NSData *imgData;
                if ([item.attachment isKindOfClass:[ImageTextAttachment class]]) {
                    ImageTextAttachment *imageAttachmengt = (ImageTextAttachment *)item.attachment;
                    imgData = imageAttachmengt.imageData;
                }
                
                if (imgData == nil) {
                    // 循环压缩图片，一直压到小于1MB
                    UIImage *image = item.attachment.image;
                    if (image == nil) {
                        continue;
                    }
                    
                    imgData = UIImageJPEGRepresentation(image, 1.f);
                    NSInteger index = 0;
                    do {
                        @autoreleasepool {
                            if (imgData.length <= threshold || index > 4) {
                                break;
                            }
                            
                            imgData = UIImageJPEGRepresentation(image, MAX(0.05f, 0.6f - (index++)*0.2f));
                        }
                    } while(YES);
                }
                
                if (imgData == nil) {
                    continue;
                }
                
                NSDictionary *dict = @{@"imageData" : imgData};
                [imageDatas addObject:dict];
                [imageMessageItems addObject:item];
            }
            
            if (imageDatas.count > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self uploadImages:imageDatas
                          messageItems:imageMessageItems
                             withIndex:0
                         uploadedCount:numberOfImages-numberOfImagesUnuploaded];
                });
            }
        });
    } else {
        [self sendMessage];
    }
}

// 判断attributedString是否为一张图片
- (BOOL)isAttachment:(NSAttributedString *)attributedString
{
    __block BOOL result = NO;
    
    [attributedString enumerateAttribute:NSAttachmentAttributeName
                                 inRange:NSMakeRange(0, attributedString.length)
                                 options:0
                              usingBlock:^(id value, NSRange range, BOOL *stop) {
                                  (*stop) = YES;
                                  
                                  if (value != nil) {
                                      result = YES;
                                  }
                              }];
    
    return result;
}

// 获取编辑器中图片的数量
- (NSUInteger)numberOfImagesInTextView
{
    __block NSUInteger result = 0;
    
    [self.contentTextView.attributedText enumerateAttribute:NSAttachmentAttributeName
                                                    inRange:NSMakeRange(0, self.contentTextView.attributedText.length)
                                                    options:0
                                                 usingBlock:^(id value, NSRange range, BOOL *stop) {
                                                     if ([value isMemberOfClass:[ImageTextAttachment class]]) {
                                                         result++;
                                                     }
                                                 }];
    
    return result;
}

// 获取编辑器中纯图片的内容
- (NSMutableArray<ImageTextAttachment *> *)imageAttachmentsInTextView
{
    NSMutableArray<ImageTextAttachment *> *imageAttachments = [NSMutableArray array];
    
    [self.contentTextView.attributedText enumerateAttribute:NSAttachmentAttributeName
                                                    inRange:NSMakeRange(0, self.contentTextView.attributedText.length)
                                                    options:0
                                                 usingBlock:^(id value, NSRange range, BOOL *stop) {
                                                     if ([value isKindOfClass:[ImageTextAttachment class]]) {
                                                         [imageAttachments addObject:value];
                                                     }
                                                 }];
    
    return imageAttachments;
}

- (void)insertTextAttachmentsWithItems:(NSArray *)items
                           compeletion:(void(^)(void))compeletion {
    NSMutableArray *images = [NSMutableArray array];
    NSMutableArray *thumbnails = [NSMutableArray array];
    
    [HUD showProgressWithMessage:@"正在处理图片..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSInteger i=0; i<items.count; i++) {
            UIImage *image = nil;
            id item = items[i];
            if ([item isKindOfClass:[UIImage class]]) {
                image = [self editedImageWithImage:(UIImage *)item];
            }
            
            if ([image isKindOfClass:[UIImage class]]) {
                [images addObject:image];
                [thumbnails addObject:[ImageTextAttachment thumbnailOfImage:image]];
            }
            
            if (image == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [HUD showErrorWithMessage:@"添加图片失败"];
                    
                    if (compeletion != nil) {
                        compeletion();
                    }
                });
                
                return ;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [HUD hideAnimated:NO];
            
            // 将这些图片添加进入
            for (NSInteger i=0; i<images.count; i++) {
                ImageTextAttachment *imageAttachment = [[ImageTextAttachment alloc] init];
                imageAttachment.thumbnail = thumbnails[i];
                imageAttachment.image = images[i];
                
                NSMutableAttributedString *attachmentAttributedString = [[NSMutableAttributedString alloc] init];
                if (self.contentTextView.selectedRange.location > 0) {
                    NSAttributedString *attributedTextLeft = [self.contentTextView.attributedText attributedSubstringFromRange:NSMakeRange(self.contentTextView.selectedRange.location-1, 1)];
                    if (![attributedTextLeft.string isEqualToString:@"\n"]) {
                        [attachmentAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:self.textAttibutes]];
                    }
                }
                
                [attachmentAttributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:imageAttachment]];
                [self.contentTextView.textStorage insertAttributedString:attachmentAttributedString
                                                                 atIndex:self.contentTextView.selectedRange.location];
                [self.contentTextView setSelectedRange:NSMakeRange(self.contentTextView.selectedRange.location+attachmentAttributedString.length, 0)];
            }
            
            // 自动插入一个空行
            [self.contentTextView.textStorage insertAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:self.textAttibutes] atIndex:self.contentTextView.selectedRange.location];
            [self.contentTextView setSelectedRange:NSMakeRange(self.contentTextView.selectedRange.location+1, 0)];
            
            self.isFromAttachmentPicker = YES;
            self.imageInserted = YES;
            
            // 这里做一个补丁，添加一张图片的时候placeholder不会被隐藏掉
            if (self.contentTextView.placeholderLabel.superview != nil) {
                [self.contentTextView.placeholderLabel removeFromSuperview];
            }
            
            if (compeletion != nil) {
                compeletion();
            }
        });
    });
}

- (void)insertText:(NSString *)text {
    NSMutableAttributedString *attachmentAttributedString = [[NSMutableAttributedString alloc] init];
    
    if (self.contentTextView.selectedRange.location > 0) {
        NSAttributedString *attributedTextLeft = [self.contentTextView.attributedText attributedSubstringFromRange:NSMakeRange(self.contentTextView.selectedRange.location-1, 1)];
        if (![attributedTextLeft.string isEqualToString:@"\n"]) {
            [attachmentAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:self.textAttibutes]];
        }
    }
    
    [attachmentAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:text
                                                                                       attributes:self.textAttibutes]];
    [self.contentTextView.textStorage insertAttributedString:attachmentAttributedString
                                                     atIndex:self.contentTextView.selectedRange.location];
    [self.contentTextView setSelectedRange:NSMakeRange(self.contentTextView.selectedRange.location+attachmentAttributedString.length, 0)];
    
    self.isFromAttachmentPicker = YES;
}

#pragma mark - ClassAndStudentSelectorControllerDelegate

- (void)classesDidSelect:(NSArray<Clazz *> *)classes {
    self.selectedClasses = classes;
    
    [self uploadImagesAndSendMessage];
}

- (void)studentsDidSelect:(NSArray<User *> *)students {
    self.selectedStudents = students;

    [self uploadImagesAndSendMessage];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    if (textView == self.titleTextView) { // 标题区域内容改变
        self.noticeMessage.title = textView.text;
        
        CGSize maxSize = CGSizeMake(textView.bounds.size.width, CGFLOAT_MAX);
        CGFloat height = ceil([textView.text boundingRectWithSize:maxSize
                                                          options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                       attributes:@{NSFontAttributeName:textView.font}
                                                          context:nil].size.height);
        self.titleViewHeightLayoutConstraint.constant = MAX(24.f, height) + 2 * kMessageEditorMargin;
        if (self.titleTextView.text.length > 0) {
            [self.titleTextView scrollRangeToVisible:NSMakeRange(0, 1)];
        }
    }
}

// 控制能否添加和删除和编辑文字
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    BOOL result = YES;
    
    do {
        // 如果是标题输入框按下换行键，那么切换到内容输入框
        if (textView == self.titleTextView) {
            if ([text isEqualToString:@"\n"]) {
                result = NO;
                
                [self.contentTextView becomeFirstResponder];
            } else if (textView.text.length - range.length + text.length > kMessageEditorMaxNumberOfTitleCharactors) {
                [HUD showErrorWithMessage:[NSString stringWithFormat:@"标题最多%zd字", kMessageEditorMaxNumberOfTitleCharactors]];
                
                result = NO;
            }
            
            break;
        }
        
        // 插入文字的情况
        // 如果插入位置的左边是图片, 并且插入的文字不是以 \n 开头的，那么自动插入一个 \n 然后再插入之前打算插入的内容，然后移动光标
        // 如果插入位置的右边是图片, 并且插入的文字这不是以 \n 结尾的，那么自动插入一个 \n 然后在 \n 之前插入内容，然后移动光标
        if (text.length > 0) {
            if (textView.attributedText.length>0 && range.location>0) {
                NSAttributedString *attributedTextLeft = [textView.attributedText attributedSubstringFromRange:NSMakeRange(range.location-1, 1)];
                BOOL isImageLeft = [self isAttachment:attributedTextLeft];
                if (isImageLeft && ![text hasPrefix:@"\n"]) { // 如果插入的文字，左边是图，并且插入的不是\n开头的
                    NSMutableAttributedString *attachmentAttributedString = [[NSMutableAttributedString alloc] init];
                    [attachmentAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:self.textAttibutes]];
                    [self.contentTextView.textStorage insertAttributedString:attachmentAttributedString atIndex:range.location];
                    [self.contentTextView setSelectedRange:NSMakeRange(range.location+1, 0)];
                    result = NO;
                    break;
                }
            }
            
            if (textView.attributedText.length > range.location) {
                NSAttributedString *attributedTextRight = [textView.attributedText attributedSubstringFromRange:NSMakeRange(range.location, 1)];
                BOOL isImageRight = [self isAttachment:attributedTextRight];
                if (isImageRight && ![text hasSuffix:@"\n"]) {
                    NSMutableAttributedString *attachmentAttributedString = [[NSMutableAttributedString alloc] init];
                    [attachmentAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:text attributes:self.textAttibutes]];
                    [attachmentAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:self.textAttibutes]];
                    [self.contentTextView.textStorage insertAttributedString:attachmentAttributedString atIndex:range.location];
                    [self.contentTextView setSelectedRange:NSMakeRange(range.location+text.length, 0)];
                    
                    result = NO;
                    break;
                }
            }
        }
        
        // 删除文字的情况：
        // 如果删除位置的上一个位置就是图片，那么不能删除
        // 如果删除位置的下一个位置是图片，也不能删除
        else { // 删除
            if (textView.attributedText.length>0 && range.location>0) {
                NSAttributedString *attributedTextLeft = [textView.attributedText attributedSubstringFromRange:NSMakeRange(range.location-1, 1)];
                BOOL isImageLeft = [self isAttachment:attributedTextLeft];
                if (isImageLeft && range.location+range.length<textView.attributedText.length) { // 如果左边是图，并且删除的内容后面还有内容
                    // 删除内容后的左边是图片，但是右边是回去，还是可以删除
                    if (textView.attributedText.length>range.location+range.length) {
                        NSAttributedString *attributedTextRight = [textView.attributedText attributedSubstringFromRange:NSMakeRange(range.location+range.length, 1)];
                        if ([attributedTextRight.string isEqualToString:@"\n"]) {
                            break;
                        }
                    }
                    
                    result = NO;
                    break;
                }
            }
            
            if (textView.attributedText.length>range.location+range.length) {
                NSAttributedString *attributedTextRight = [textView.attributedText attributedSubstringFromRange:NSMakeRange(range.location+range.length, 1)];
                BOOL isImageRight = [self isAttachment:attributedTextRight];
                if (isImageRight && range.location>0) {
                    // 如果前面是空格，还是可以删
                    if (textView.attributedText.length>range.location-1) {
                        attributedTextRight = [textView.attributedText attributedSubstringFromRange:NSMakeRange(range.location-1, 1)];
                        if ([attributedTextRight.string isEqualToString:@"\n"]) {
                            break;
                        }
                    }
                    
                    result = NO;
                    break;
                }
            }
        }
    } while(NO);
    
    return result;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.contentTextView) {
        return;
    }
    
    if (scrollView.contentOffset.y > _lastOffset ) {
        if (scrollView.contentOffset.y > 0) {
            if (self.titleViewTopLayoutConstraint.constant != -self.titleViewHeightLayoutConstraint.constant) {
                self.titleViewTopLayoutConstraint.constant = -self.titleViewHeightLayoutConstraint.constant;
                
                [UIView animateWithDuration:0.15
                                 animations:^{
                                     [self.titleTextView.superview.superview layoutIfNeeded];
                                 }];
            }
            
        }
    } else {
        if (scrollView.contentOffset.y < 0) {
            if (self.titleViewTopLayoutConstraint.constant != 0.f) {
                self.titleViewTopLayoutConstraint.constant = 0.f;
                [UIView animateWithDuration:0.15
                                 animations:^{
                                     [self.titleTextView.superview.superview layoutIfNeeded];
                                 }];
            }
        }
    }
    
    _lastOffset = scrollView.contentOffset.y;
}

#pragma mark - Keyboard Notification

- (void)keyboardFrameWillChange:(NSNotification *)notification {
    NSValue *endValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect kbFrame = [endValue CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:nil];
    
    if (kbFrame.origin.y >= self.view.bounds.size.height) {
        self.bottomViewBottomLayoutConstraint.constant = 0;
    } else {
        if (@available(iOS 11.0, *)) {
            self.bottomViewBottomLayoutConstraint.constant = kbFrame.size.height - self.view.safeAreaInsets.bottom;
        } else {
            self.bottomViewBottomLayoutConstraint.constant = kbFrame.size.height;
        }
    }
    
    [UIView animateWithDuration:0.45f
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                     }];
}

- (void)keyboardFrameDidChange:(NSNotification *)notification {
}

- (void)textViewImageLoadDidSuccess:(NSNotification *)notification {
    ImageTextAttachment *attachment = (ImageTextAttachment *)(notification.object);
    
    __block NSRange rangeResult = NSMakeRange(NSNotFound, NSNotFound);
    
    [self.contentTextView.attributedText enumerateAttribute:NSAttachmentAttributeName
                                                    inRange:NSMakeRange(0, self.contentTextView.attributedText.length)
                                                    options:0
                                                 usingBlock:^(id value, NSRange range, BOOL *stop) {
                                                     if (value == attachment) {
                                                         rangeResult = range;
                                                         *stop = YES;
                                                     }
                                                 }];
    
    if (rangeResult.location != NSNotFound) {
        [self.contentTextView.layoutManager invalidateDisplayForCharacterRange:rangeResult];
    }
}

#pragma mark - NSTextStorageDelegate

- (void)textStorage:(NSTextStorage *)textStorage
 willProcessEditing:(NSTextStorageEditActions)editedMask
              range:(NSRange)editedRange
     changeInLength:(NSInteger)delta {
    [self.contentTextView.textStorage removeAttribute:NSForegroundColorAttributeName
                                                range:editedRange];
    [self.contentTextView.textStorage removeAttribute:NSFontAttributeName
                                                range:editedRange];
    [self.contentTextView.textStorage removeAttribute:NSParagraphStyleAttributeName
                                                range:editedRange];
    
    [self.contentTextView.textStorage addAttribute:NSForegroundColorAttributeName
                                             value:self.textAttibutes[NSForegroundColorAttributeName]
                                             range:editedRange];
    [self.contentTextView.textStorage addAttribute:NSFontAttributeName
                                             value:self.textAttibutes[NSFontAttributeName]
                                             range:editedRange];
    [self.contentTextView.textStorage addAttribute:NSParagraphStyleAttributeName
                                             value:self.textAttibutes[NSParagraphStyleAttributeName]
                                             range:editedRange];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    self.isFromAttachmentPicker = YES;
    
    [picker dismissViewControllerAnimated:YES completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self insertTextAttachmentsWithItems:@[image] compeletion:nil];
        });
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    self.isFromAttachmentPicker = YES;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - Dealloc

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.titleTextView.delegate = nil;
    self.contentTextView.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}

@end
