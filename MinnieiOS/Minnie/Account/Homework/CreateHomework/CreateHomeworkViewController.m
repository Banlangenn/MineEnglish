//
//  CreateHomeworkViewController.m
//  X5Teacher
//
//  Created by yebw on 2018/1/22.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "CreateHomeworkViewController.h"
#import "HomeworkService.h"
#import "HomeworkLabelTableViewCell.h"
#import "HomeworkTagsTableViewCell.h"
#import "HomeworkTitleTableViewCell.h"
#import "HomeworkTextTableViewCell.h"
#import "HomeworkVideoTableViewCell.h"
#import "HomeworkAudioTableViewCell.h"
#import "HomeworkImageTableViewCell.h"
#import "HomeworkAddTableViewCell.h"
#import "TagService.h"
#import "TagsViewController.h"
#import "Homework.h"
#import "FileUploader.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVKit/AVKit.h>
#import "HomeworkSegmentTableViewCell.h"
#import "HomeworkDiffTableViewCell.h"
#import "HomeworkLimitTimeCell.h"
#import "ChooseDatePickerView.h"
#import <objc/runtime.h>

static const char keyOfPickerDocument;

@interface CreateHomeworkViewController ()<UITableViewDataSource, UITableViewDelegate,
UIImagePickerControllerDelegate, UINavigationControllerDelegate,ChooseDatePickerViewDelegate,UIDocumentPickerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *homeworkTableView;
@property (nonatomic, copy) NSString *homeworkTitle;
@property (nonatomic, copy) NSString *teremark;// 批改备注
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) NSMutableArray<HomeworkItem *> *items;
@property (nonatomic, strong) NSMutableArray<HomeworkAnswerItem *> *answerItems;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSArray *formTags;
@property (nonatomic, strong) NSMutableArray *selectedTags;
@property (nonatomic, assign) BOOL isAddingAnswerItem;

@property (nonatomic, assign) NSInteger categoryType;
@property (nonatomic, assign) NSInteger styleType;
@property (nonatomic, assign) NSInteger level;
@property (nonatomic, assign) NSInteger limitTimeSecs;
@property (nonatomic, strong) NSString * selectFormTag;
@property (nonatomic, strong) MBProgressHUD * mHud;
@end

@implementation CreateHomeworkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.homework == nil) {
        self.homework = [[Homework alloc] init];
        self.items = [[NSMutableArray alloc] init];
        self.answerItems = [[NSMutableArray alloc] init];
        self.selectedTags = [[NSMutableArray alloc] init];
        self.limitTimeSecs = 300;
        self.categoryType = 1;
        //作业类型：日常1、假期2、集训3
        self.styleType = 1;
    } else {
        self.customTitleLabel.text = @"作业详情";
        
        self.homeworkTitle = self.homework.title;
        
        HomeworkItem *item = self.homework.items[0];
        self.text = item.text;
        NSArray *items = [self.homework.items subarrayWithRange:NSMakeRange(1, self.homework.items.count-1)];
        self.items = [NSMutableArray arrayWithArray:items];
        
        if (self.homework.answerItems.count == 0) {
            self.answerItems = [[NSMutableArray alloc] init];
        } else {
            self.answerItems = [NSMutableArray arrayWithArray:self.homework.answerItems];
        }
        
        self.categoryType = self.homework.category;
        self.styleType = self.homework.style;
        self.level = self.homework.level;
        self.limitTimeSecs = self.homework.limitTimes;
        self.selectedTags = [NSMutableArray arrayWithArray:self.homework.tags];
        self.selectFormTag = self.homework.formTag;
        self.teremark = self.homework.teremark;
    }
    
    self.homeworkTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestTags)
                                                 name:kNotificationKeyOfAddTags
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestTags)
                                                 name:kNotificationKeyOfDeleteTags
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestFormTags)
                                                 name:kNotificationKeyOfAddFormTags
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestFormTags)
                                                 name:kNotificationKeyOfDeleteFormTags
                                               object:nil];
    
    
    [self registerCellNibs];
    
    [self requestTags];
    
    [self requestFormTags];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"%s", __func__);
}

#pragma mark - IBAction

- (IBAction)saveButtonPressed:(id)sender {
    if (self.homeworkTitle.length == 0) {
        [HUD showErrorWithMessage:@"作业标题不能为空"];
        return;
    }
    
    if (self.text.length == 0 && self.items.count==0) {
        [HUD showErrorWithMessage:@"作业内容不能为空"];
        return;
    }
    
    NSMutableArray *items = [NSMutableArray arrayWithArray:self.items];
    
    HomeworkItem *textItem = [[HomeworkItem alloc] init];
    textItem.type = HomeworkItemTypeText;
    textItem.text = self.text==nil?@"":self.text;
    [items insertObject:textItem atIndex:0];
    
    self.homework.title = self.homeworkTitle;
    self.homework.items = items;
    self.homework.answerItems = self.answerItems;
    self.homework.tags = self.selectedTags;
    self.homework.createTeacher = APP.currentUser;
    self.homework.category = self.categoryType;
    self.homework.style = self.styleType;
    self.homework.limitTimes = self.limitTimeSecs;
    self.homework.level = self.level;
    self.homework.formTag = self.selectFormTag;
    self.homework.teremark = self.teremark;
    
    if (self.homework.homeworkId == 0) {
        [HUD showProgressWithMessage:@"正在新建作业"];
    } else {
        [HUD showProgressWithMessage:@"正在更新作业"];
    }
    [HomeworkService createHomework:self.homework
                           callback:^(Result *result, NSError *error) {
                               if (error != nil) {
                                   if (self.homework.homeworkId == 0) {
                                       [HUD showErrorWithMessage:@"新建作业失败"];
                                   } else {
                                       [HUD showErrorWithMessage:@"更新作业失败"];
                                   }
                                   return;
                               }
                               
                               if (self.homework.homeworkId == 0) {
                                   [HUD showWithMessage:@"新建作业成功"];
                               } else {
                                   [HUD showWithMessage:@"更新作业成功"];
                               }
                               
                               [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfAddHomework object:nil];
                               
                               [self.navigationController popViewControllerAnimated:YES];
                           }];
}

#pragma mark - Private Methods

- (void)registerCellNibs {
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkLabelTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkLabelTableViewCellId];
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkTitleTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkTitleTableViewCellId];
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkTextTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkTextTableViewCellId];
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkVideoTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkVideoTableViewCellId];
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkAudioTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkAudioTableViewCellId];
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkImageTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkImageTableViewCellId];
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkTagsTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkTagsTableViewCellId];
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkAddTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkAddTableViewCellId];
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkSegmentTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkSegmentTableViewCellId];
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkDiffTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkDiffTableViewCellId];
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkLimitTimeCell" bundle:nil] forCellReuseIdentifier:HomeworkLimitTimeCellId];
    
}

- (void)requestTags {
    [TagService requestTagsWithCallback:^(Result *result, NSError *error) {
        if (error != nil) {
            [HUD showErrorWithMessage:@"标签请求失败"];
            
            return ;
        }
        
        self.tags = (NSArray *)(result.userInfo);
        [self.homeworkTableView reloadData];
    }];
}

- (void)requestFormTags
{
    [TagService requestFormTagsWithCallback:^(Result *result, NSError *error) {
        if (error != nil) {
            [HUD showErrorWithMessage:@"标签请求失败"];
            
            return ;
        }
        
        self.formTags = (NSArray *)(result.userInfo);
        [self.homeworkTableView reloadData];
    }];
}

- (void)handleAddItem {
    // 适配ipad版本
    UIAlertControllerStyle alertStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        alertStyle = UIAlertControllerStyleActionSheet;
    } else {
        alertStyle = UIAlertControllerStyleAlert;
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"选择作业材料类型"
                                                                     message:nil
                                                              preferredStyle:alertStyle];
    
    UIAlertAction * fileAction = [UIAlertAction actionWithTitle:@"文件"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            [self addFileItem:@[@"public.image", @"public.movie",@"public.audio"] withHomeworkItem:nil];
                                                        }];
    
    UIAlertAction * videoAction = [UIAlertAction actionWithTitle:@"视频"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            [self addVideoItem];
                                                        }];
    
    UIAlertAction * imageAction = [UIAlertAction actionWithTitle:@"图片"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            [self addImageItem];
                                                        }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    [alertVC addAction:fileAction];
    [alertVC addAction:videoAction];
    [alertVC addAction:imageAction];
    [alertVC addAction:cancelAction];

    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:alertVC
                                            animated:YES
                                          completion:nil];
}

- (void)addFileItem:(NSArray *)allowedUTIs withHomeworkItem:(HomeworkItem *)item
{
    self.isAddingAnswerItem = NO;
    UIDocumentPickerViewController * picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:allowedUTIs inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    
    objc_setAssociatedObject(picker , &keyOfPickerDocument, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)addVideoItem {
    self.isAddingAnswerItem = NO;
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeMovie];

    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)addImageItem {
    self.isAddingAnswerItem = NO;
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeImage];

    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)handleSetTimeLimit
{
    ChooseDatePickerView * chooseDataPicker = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([ChooseDatePickerView class]) owner:nil options:nil] firstObject];
    [chooseDataPicker setDefultSeconds:300];
    chooseDataPicker.delegate = self;
    [chooseDataPicker show];
}

- (void)handleAddAnswerItem {
    // 适配ipad版本
    UIAlertControllerStyle alertStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        alertStyle = UIAlertControllerStyleActionSheet;
    } else {
        alertStyle = UIAlertControllerStyleAlert;
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"选择作业答案类型"
                                                                     message:nil
                                                              preferredStyle:alertStyle];
    
    UIAlertAction * fileAction = [UIAlertAction actionWithTitle:@"文件"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            [self addFileAnswerItem:@[@"public.image", @"public.movie",@"public.audio"] withHomeworkItem:nil];
                                                        }];
    
    
    UIAlertAction *videoAction = [UIAlertAction actionWithTitle:@"视频"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            [self addVideoAnswerItem];
                                                        }];
    
    UIAlertAction *imageAction = [UIAlertAction actionWithTitle:@"图片"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            [self addImageAnswerItem];
                                                        }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    [alertVC addAction:fileAction];
    [alertVC addAction:videoAction];
    [alertVC addAction:imageAction];
    [alertVC addAction:cancelAction];

    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:alertVC
                                            animated:YES
                                          completion:nil];
}

- (void)addFileAnswerItem:(NSArray *)allowedUTIs withHomeworkItem:(HomeworkAnswerItem *)item
{
    self.isAddingAnswerItem = YES;
    
    UIDocumentPickerViewController * picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:allowedUTIs inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    
    objc_setAssociatedObject(picker , &keyOfPickerDocument, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)addVideoAnswerItem {
    self.isAddingAnswerItem = YES;
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeMovie];

    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)addImageAnswerItem {
    self.isAddingAnswerItem = YES;

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeImage];

    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)deleteItem:(HomeworkItem *)item {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认删除?"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"删除"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self.items removeObject:item];
                                                              [self.homeworkTableView reloadData];
                                                          }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];

    alertController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)deleteMp3ForItem:(HomeworkItem *)item
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认删除?"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"删除"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              item.audioUrl = @"";
                                                              NSString * coverUrl = item.audioCoverUrl;
                                                              item.imageUrl = coverUrl;
                                                              item.audioCoverUrl = @"";
                                                              item.type = HomeworkItemTypeImage;
                                                              [self.homeworkTableView reloadData];
                                                          }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];

    alertController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteAnswerMp3ForItem:(HomeworkAnswerItem *)item
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认删除?"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"删除"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              item.audioUrl = @"";
                                                              NSString * coverUrl = item.audioCoverUrl;
                                                              item.imageUrl = coverUrl;
                                                              item.audioCoverUrl = @"";
                                                              item.type = HomeworkItemTypeImage;
                                                              [self.homeworkTableView reloadData];
                                                          }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];

    alertController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteAnswerItem:(HomeworkAnswerItem *)item {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认删除?"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"删除"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self.answerItems removeObject:item];
                                                              [self.homeworkTableView reloadData];
                                                          }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];

    alertController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteHomework {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认删除?"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"删除"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self doDeleteHomework];
                                                          }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];

    alertController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)doDeleteHomework {
    
}

- (void)uploadVideoForPath:(NSURL *)videoUrl
{
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld_compressedVideo.mp4",time(NULL)]];
    
    [HUD showProgressWithMessage:@"正在压缩视频文件..."];
    
    AVURLAsset *avAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    NSTimeInterval durationInSeconds = 0.0;
    if (avAsset != nil) {
        durationInSeconds = CMTimeGetSeconds(avAsset.duration);
    }
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];

    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPreset1280x720];
        exportSession.outputURL = [NSURL fileURLWithPath:path];
        exportSession.shouldOptimizeForNetworkUse = true;
        exportSession.outputFileType = AVFileTypeMPEG4;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                dispatch_async(dispatch_get_main_queue(), ^{
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
                        if (videoUrl.length == 0) {
                            [HUD showErrorWithMessage:@"视频上传失败"];
                            
                            return ;
                        }
                        
                        [HUD showWithMessage:@"视频上传成功"];
                        
                        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                        
                        if (weakSelf.isAddingAnswerItem) {
                            HomeworkAnswerItem *item = [[HomeworkAnswerItem alloc] init];
                            item.type = HomeworkItemTypeVideo;
                            item.videoUrl = videoUrl;
                            item.itemTime = durationInSeconds;
                            item.videoCoverUrl = @"";
                            
                            [weakSelf.answerItems addObject:item];
                        } else{
                            HomeworkItem *item = [[HomeworkItem alloc] init];
                            item.type = HomeworkItemTypeVideo;
                            item.videoUrl = videoUrl;
                            item.videoCoverUrl = @"";
                            
                            [weakSelf.items addObject:item];
                        }
                        
                        [weakSelf.homeworkTableView reloadData];
                    }];
                    
//                    [[FileUploader shareInstance] uploadDataWithLocalFilePath:path
//                                                                progressBlock:^(NSInteger progress) {
//                                                                    [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传视频%@%%...", @(progress)] cancelCallback:^{
//                                                                        [[FileUploader shareInstance] cancleUploading];
//                                                                    }];
//                                                                }
//                                                              completionBlock:^(NSString * _Nullable videoUrl, NSError * _Nullable error) {
//                                                                  if (videoUrl.length == 0) {
//                                                                      [HUD showErrorWithMessage:@"视频上传失败"];
//                                                                      
//                                                                      return ;
//                                                                  }
//                                                                  
//                                                                  [HUD showWithMessage:@"视频上传成功"];
//                                                                  
//                                                                  [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
//                                                                  
//                                                                  if (self.isAddingAnswerItem) {
//                                                                      HomeworkAnswerItem *item = [[HomeworkAnswerItem alloc] init];
//                                                                      item.type = HomeworkItemTypeVideo;
//                                                                      item.videoUrl = videoUrl;
//                                                                      item.itemTime = durationInSeconds;
//                                                                      item.videoCoverUrl = @"";
//                                                                      
//                                                                      [self.answerItems addObject:item];
//                                                                  } else{
//                                                                      HomeworkItem *item = [[HomeworkItem alloc] init];
//                                                                      item.type = HomeworkItemTypeVideo;
//                                                                      item.videoUrl = videoUrl;
//                                                                      item.videoCoverUrl = @"";
//                                                                      
//                                                                      [self.items addObject:item];
//                                                                  }
//                                                                  
//                                                                  [self.homeworkTableView reloadData];
//                                                              }];
//                    
//                    [HUD showProgressWithMessage:@"正在上传视频..." cancelCallback:^{
//                        [[FileUploader shareInstance] cancleUploading];
//                    }];
                });
            }else{
                NSLog(@"当前压缩进度:%f",exportSession.progress);
            }
            NSLog(@"%@",exportSession.error);
            
        }];
    }
    
    
    
}

- (void)uploadImageForPath:(UIImage *)image
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = UIImageJPEGRepresentation(image, 0.8);
        dispatch_async(dispatch_get_main_queue(), ^{
            [HUD showProgressWithMessage:@"正在上传图片..."];
            
            QNUploadOption * option = [[QNUploadOption alloc] initWithProgressHandler:^(NSString *key, float percent) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传图片%.f%%...", percent * 100]];
                });
                
            }];
            
            [[FileUploader shareInstance] qn_uploadData:data type:UploadFileTypeImage option:option completionBlock:^(NSString * _Nullable imageUrl, NSError * _Nullable error) {
                if (imageUrl.length == 0) {
                    [HUD showErrorWithMessage:@"图片上传失败"];
                    
                    return ;
                }
                
                [HUD showWithMessage:@"图片上传成功"];
                
                if (self.isAddingAnswerItem) {
                    HomeworkAnswerItem *item = [[HomeworkAnswerItem alloc] init];
                    item.type = HomeworkItemTypeImage;
                    item.imageUrl = imageUrl;
                    item.imageWidth = image.size.width;
                    item.imageHeight = image.size.height;
                    
                    [self.answerItems addObject:item];
                } else {
                    HomeworkItem *item = [[HomeworkItem alloc] init];
                    item.type = HomeworkItemTypeImage;
                    item.imageUrl = imageUrl;
                    item.imageWidth = image.size.width;
                    item.imageHeight = image.size.height;
                    
                    [self.items addObject:item];
                }
                
                [self.homeworkTableView reloadData];
            }];
            
//            [[FileUploader shareInstance] uploadData:data
//                                                type:UploadFileTypeImage
//                                       progressBlock:^(NSInteger progress) {
//                                           [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传图片%@%%...", @(progress)]];
//                                       }
//                                     completionBlock:^(NSString * _Nullable imageUrl, NSError * _Nullable error) {
//                                         if (imageUrl.length == 0) {
//                                             [HUD showErrorWithMessage:@"图片上传失败"];
//
//                                             return ;
//                                         }
//
//                                         [HUD showWithMessage:@"图片上传成功"];
//
//                                         if (self.isAddingAnswerItem) {
//                                             HomeworkAnswerItem *item = [[HomeworkAnswerItem alloc] init];
//                                             item.type = HomeworkItemTypeImage;
//                                             item.imageUrl = imageUrl;
//                                             item.imageWidth = image.size.width;
//                                             item.imageHeight = image.size.height;
//
//                                             [self.answerItems addObject:item];
//                                         } else {
//                                             HomeworkItem *item = [[HomeworkItem alloc] init];
//                                             item.type = HomeworkItemTypeImage;
//                                             item.imageUrl = imageUrl;
//                                             item.imageWidth = image.size.width;
//                                             item.imageHeight = image.size.height;
//
//                                             [self.items addObject:item];
//                                         }
//
//                                         [self.homeworkTableView reloadData];
//                                     }];
        });
    });
}

- (void)uploadAudioFileForPath:(NSData *)data forHomeworkItem:(id)homework
{
    WeakifySelf;
    __block BOOL flag = NO;
    QNUploadOption * option = [[QNUploadOption alloc] initWithMime:nil progressHandler:^(NSString *key, float percent) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!weakSelf.mHud)
            {
                weakSelf.mHud = [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传音频%.f%%...", percent * 100] cancelCallback:^{
                    flag = YES;
                }];
            }
            else
            {
                UILabel * label = [weakSelf.mHud.customView viewWithTag:99];
                
                label.text = [NSString stringWithFormat:@"正在上传音频%.f%%...", percent * 100];
            }
            
            
//            [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传音频%.f%%...", percent * 100] cancelCallback:^{
//                flag = YES;
//            }];
        });
    } params:nil checkCrc:NO cancellationSignal:^BOOL{
        return flag;
    }];
    
    [[FileUploader shareInstance] qn_uploadData:data type:UploadFileTypeAudio_Mp3 option:option completionBlock:^(NSString * _Nullable videoUrl, NSError * _Nullable error) {
        weakSelf.mHud = nil;
        if (videoUrl.length == 0) {
            [HUD showErrorWithMessage:@"音频上传失败"];
            
            return ;
        }
        
        [HUD showWithMessage:@"音频上传成功"];
        
        
        if (homework)
        {
            if (weakSelf.isAddingAnswerItem) {
                
                HomeworkAnswerItem *item = (HomeworkAnswerItem *)homework;
                item.type = HomeworkItemTypeAudio;
                item.audioUrl = videoUrl;
                NSString * cover = item.imageUrl;
                item.audioCoverUrl = cover;
                
            }
            else
            {
                HomeworkItem *item = (HomeworkItem *)homework;
                item.type = HomeworkItemTypeAudio;
                item.audioUrl = videoUrl;
                NSString * cover = item.imageUrl;
                item.audioCoverUrl = cover;
            }
        }
        else
        {
            if (weakSelf.isAddingAnswerItem) {
                HomeworkAnswerItem *item = [[HomeworkAnswerItem alloc] init];
                item.type = HomeworkItemTypeAudio;
                item.audioUrl = videoUrl;
                item.audioCoverUrl = @"";
                
                [weakSelf.answerItems addObject:item];
            } else{
                HomeworkItem *item = [[HomeworkItem alloc] init];
                item.type = HomeworkItemTypeAudio;
                item.audioUrl = videoUrl;
                item.audioCoverUrl = @"";
                
                [weakSelf.items addObject:item];
            }
        }
        
        [self.homeworkTableView reloadData];
    }];
    
    
//    [[FileUploader shareInstance] uploadData:data
//                                        type:UploadFileTypeAudio_Mp3
//                               progressBlock:^(NSInteger progress) {
//                                                    [HUD showProgressWithMessage:[NSString stringWithFormat:@"正在上传音频%@%%...", @(progress)] cancelCallback:^{
//                                                        [[FileUploader shareInstance] cancleUploading];
//                                                    }];
//                                                }
//                                              completionBlock:^(NSString * _Nullable videoUrl, NSError * _Nullable error) {
//                                                  if (videoUrl.length == 0) {
//                                                      [HUD showErrorWithMessage:@"音频上传失败"];
//
//                                                      return ;
//                                                  }
//
//                                                  [HUD showWithMessage:@"音频上传成功"];
//
//
//                                                  if (homework)
//                                                  {
//                                                      if (self.isAddingAnswerItem) {
//
//                                                          HomeworkAnswerItem *item = (HomeworkAnswerItem *)homework;
//                                                          item.type = HomeworkItemTypeAudio;
//                                                          item.audioUrl = videoUrl;
//                                                          NSString * cover = item.imageUrl;
//                                                          item.audioCoverUrl = cover;
//
//                                                      }
//                                                      else
//                                                      {
//                                                          HomeworkItem *item = (HomeworkItem *)homework;
//                                                          item.type = HomeworkItemTypeAudio;
//                                                          item.audioUrl = videoUrl;
//                                                          NSString * cover = item.imageUrl;
//                                                          item.audioCoverUrl = cover;
//                                                      }
//                                                  }
//                                                  else
//                                                  {
//                                                      if (self.isAddingAnswerItem) {
//                                                          HomeworkAnswerItem *item = [[HomeworkAnswerItem alloc] init];
//                                                          item.type = HomeworkItemTypeAudio;
//                                                          item.audioUrl = videoUrl;
//                                                          item.audioCoverUrl = @"";
//
//                                                          [self.answerItems addObject:item];
//                                                      } else{
//                                                          HomeworkItem *item = [[HomeworkItem alloc] init];
//                                                          item.type = HomeworkItemTypeAudio;
//                                                          item.audioUrl = videoUrl;
//                                                          item.audioCoverUrl = @"";
//
//                                                          [self.items addObject:item];
//                                                      }
//                                                  }
//
//                                                  [self.homeworkTableView reloadData];
//                                              }];
//
//    [HUD showProgressWithMessage:@"正在上传音频..." cancelCallback:^{
//        [[FileUploader shareInstance] cancleUploading];
//    }];
}


- (void)handleVideoPickerResult:(UIImagePickerController *)picker
  didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        [self uploadVideoForPath:videoUrl];
    }];
}

- (void)handlePhotoPickerResult:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (image.size.width==0 || image.size.height==0) {
            [HUD showErrorWithMessage:@"图片选择失败"];
            return;
        }
        [self uploadImageForPath:image];
    }];
}


#pragma mark - UIDocumentPickerDelegate
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
 //   [controller dismissViewControllerAnimated:YES completion:nil];
    
    id homeworkItem = objc_getAssociatedObject(controller, &keyOfPickerDocument);
    
    if (controller.documentPickerMode == UIDocumentPickerModeImport)
    {
            // 通过文件协调器读取文件地址
            NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        
            [fileCoordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:nil  byAccessor:^(NSURL * _Nonnull newURL) {
                // 读取文件
                NSString *fileName = [newURL lastPathComponent];
                [self saveLocalCachesCont:newURL fileName:fileName withObject:homeworkItem];
                
            }];
    }
}

- (void)saveLocalCachesCont:(NSURL * )fileUrl fileName:(NSString *)name withObject:(id)object
{
    // 255216 jpg;
    // 13780 png;
    // 7368 mp3
    NSData *fileData = [NSData dataWithContentsOfURL:fileUrl];
    
    int char1 = 0 ,char2 =0 ; //必须这样初始化
    [fileData getBytes:&char1 range:NSMakeRange(0, 1)];
    [fileData getBytes:&char2 range:NSMakeRange(1, 1)];
    
    NSString * asciiStr = [NSString stringWithFormat:@"%i%i",char1,char2];
    
    if ([asciiStr isEqualToString:@"255216"] || [asciiStr isEqualToString:@"13780"])
    {
        UIImage * image = [UIImage imageWithData:fileData];
        if (image)
        {
            [self uploadImageForPath:image];
        }
    }
    else if([asciiStr isEqualToString:@"7368"])
    {
        [self uploadAudioFileForPath:fileData forHomeworkItem:object];
    }
    else
    {
        [self uploadVideoForPath:fileUrl];
    }
    
}

#pragma mark - ChooseDatePickerViewDelegate
- (void)finishSelectDate:(NSInteger)seconds
{
    self.limitTimeSecs = seconds;
    
    HomeworkLimitTimeCell * cell = (HomeworkLimitTimeCell *)[self.homeworkTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 + self.items.count + 2 + self.answerItems.count + 4 inSection:0]];
    [cell updateTimeLabel:seconds];
}


#pragma mark - UIImagePickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.movie"]) {
        [self handleVideoPickerResult:picker didFinishPickingMediaWithInfo:info];
    } else {
        [self handlePhotoPickerResult:picker didFinishPickingMediaWithInfo:info];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
    NSInteger numberOfRows = 2; // 标题 + 文本（作业要求）
    
    numberOfRows += 1;// 添加批改备注
    
    numberOfRows += 1;// 添加材料文案
    
    numberOfRows += self.items.count;
    
    numberOfRows += 1; // 添加材料按钮
    
    numberOfRows += 1; // 添加答案文案
    
    numberOfRows += self.answerItems.count;
    
    numberOfRows += 1; // 添加答案按钮
    
    numberOfRows += 1; // 添加作业类型
    
    numberOfRows += 1; // 添加作业难度
    
    numberOfRows += 1; // 添加时限
    
    numberOfRows += 1; // tag1
    
    numberOfRows += 1; // tag2
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if (indexPath.row == 0) { // 标题
        WeakifySelf;
        HomeworkTitleTableViewCell *titleCell = [tableView dequeueReusableCellWithIdentifier:HomeworkTitleTableViewCellId forIndexPath:indexPath];
        [titleCell setupWithText:self.homeworkTitle title:@"标题:" placeholder:@"输入题目"];
        
        __weak HomeworkTitleTableViewCell *weakTitleCell = titleCell;
        __weak UITableView *weakTableView = tableView;
        titleCell.callback = ^(NSString *text, BOOL heightChanged) {
            weakSelf.homeworkTitle = text;
            
            if (heightChanged) {
                [weakTableView beginUpdates];
                [weakTableView endUpdates];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakTitleCell ajustTextView];
                });
            }
        };
        
        cell = titleCell;
    } else if (indexPath.row == 1) { // 文本
        WeakifySelf;
        HomeworkTextTableViewCell *textCell = [tableView dequeueReusableCellWithIdentifier:HomeworkTextTableViewCellId forIndexPath:indexPath];
        
        [textCell setupWithText:self.text];
        
        __weak HomeworkTextTableViewCell *weakTextCell = textCell;
        __weak UITableView *weakTableView = tableView;
        textCell.callback = ^(NSString *text, BOOL heightChanged) {
            weakSelf.text = text;
            
            if (heightChanged) {
                [weakTableView beginUpdates];
                [weakTableView endUpdates];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakTextCell ajustTextView];
                });
            }
        };
        
        cell = textCell;
    }
    else if (indexPath.row == 2) { // 添加批改备注
       
        WeakifySelf;
        HomeworkTitleTableViewCell *markCell = [tableView dequeueReusableCellWithIdentifier:HomeworkTitleTableViewCellId forIndexPath:indexPath];
        markCell.cellType = CreateHomeworkCell_CorrectRemarks;
        [markCell setupWithText:self.teremark title:@"批改备注:" placeholder:@"输入批改要求"];
        __weak HomeworkTitleTableViewCell *weakTitleCell = markCell;
        __weak UITableView *weakTableView = tableView;
        markCell.callback = ^(NSString *text, BOOL heightChanged) {
            weakSelf.teremark = text;
            
            if (heightChanged) {
                [weakTableView beginUpdates];
                [weakTableView endUpdates];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakTitleCell ajustTextView];
                });
            }
        };
        
        cell = markCell;
    }
    else if (indexPath.row == 3) { // 添加材料标签
        HomeworkLabelTableViewCell *labelCell = [tableView dequeueReusableCellWithIdentifier:HomeworkLabelTableViewCellId forIndexPath:indexPath];
        
        [labelCell setupWithText:@"添加材料:"];
        
        cell = labelCell;
    } else if (indexPath.row > 3 && indexPath.row < 3 + self.items.count + 1) { // 材料
        NSInteger row = indexPath.row - 4;
        HomeworkItem *item = self.items[row];
        NSString *type = item.type;
        if ([type isEqualToString:HomeworkItemTypeVideo]) {
            HomeworkVideoTableViewCell *videoCell = [tableView dequeueReusableCellWithIdentifier:HomeworkVideoTableViewCellId forIndexPath:indexPath];
            
            [videoCell setupWithVideoUrl:item.videoUrl coverUrl:item.videoCoverUrl];
            
            WeakifySelf;
            [videoCell setDeleteCallback:^{
                [weakSelf deleteItem:item];
            }];
            
            cell = videoCell;
        } else if ([type isEqualToString:HomeworkItemTypeImage]) {
            HomeworkImageTableViewCell *imageCell = [tableView dequeueReusableCellWithIdentifier:HomeworkImageTableViewCellId forIndexPath:indexPath];
            
            [imageCell setupWithImageUrl:item.imageUrl];
            
            WeakifySelf;
            [imageCell setDeleteCallback:^(BOOL bDel) {
                if (bDel)
                {
                    [weakSelf deleteItem:item];
                }
                else
                {
                    [weakSelf addFileItem:@[@"public.audio"] withHomeworkItem:item];
                }
            }];
            
            cell = imageCell;
        }
        else if ([type isEqualToString:HomeworkItemTypeAudio]) {
            
            HomeworkAudioTableViewCell *audioCell = [tableView dequeueReusableCellWithIdentifier:HomeworkAudioTableViewCellId forIndexPath:indexPath];
            [audioCell setupWithAudioUrl:item.audioUrl coverUrl:item.audioCoverUrl];

            WeakifySelf;
            [audioCell setDeleteCallback:^{
                [weakSelf deleteItem:item];
            }];
            
            [audioCell setDeleteFileCallback:^{
                [weakSelf deleteMp3ForItem:item];
            }];
            
            cell = audioCell;
            
        }
    } else if (indexPath.row == 3 + self.items.count + 1) { // 添加按钮
        HomeworkAddTableViewCell *addCell = [tableView dequeueReusableCellWithIdentifier:HomeworkAddTableViewCellId forIndexPath:indexPath];
        
        WeakifySelf;
        [addCell setAddCallback:^{
            [weakSelf handleAddItem];
        }];
        
        cell = addCell;
    } else if (indexPath.row == 3 + self.items.count + 2) { // 标签
        HomeworkLabelTableViewCell *labelCell = [tableView dequeueReusableCellWithIdentifier:HomeworkLabelTableViewCellId forIndexPath:indexPath];
        
        [labelCell setupWithText:@"添加答案:"];
        
        cell = labelCell;
    } else if (indexPath.row > 3 + self.items.count + 2 &&
               indexPath.row < 3 + self.items.count + 2 + self.answerItems.count + 1) {
        NSInteger row = indexPath.row - (3 + self.items.count + 3);
        HomeworkAnswerItem *item = self.answerItems[row];
        NSString *type = item.type;
        if ([type isEqualToString:HomeworkItemTypeVideo]) {
            HomeworkVideoTableViewCell *videoCell = [tableView dequeueReusableCellWithIdentifier:HomeworkVideoTableViewCellId forIndexPath:indexPath];
            
            [videoCell setupWithVideoUrl:item.videoUrl coverUrl:item.videoCoverUrl];
            
            WeakifySelf;
            [videoCell setDeleteCallback:^{
                [weakSelf deleteAnswerItem:item];
            }];
            
            cell = videoCell;
        } else if ([type isEqualToString:HomeworkItemTypeImage]) {
            HomeworkImageTableViewCell *imageCell = [tableView dequeueReusableCellWithIdentifier:HomeworkImageTableViewCellId forIndexPath:indexPath];
            
            [imageCell setupWithImageUrl:item.imageUrl];
            
            WeakifySelf;
            [imageCell setDeleteCallback:^(BOOL bDel) {
                if (bDel)
                {
                    [weakSelf deleteAnswerItem:item];
                }
                else
                {
                    [weakSelf addFileAnswerItem:@[@"public.audio"] withHomeworkItem:item];
                }
                
            }];
            
            cell = imageCell;
        }
        else if ([type isEqualToString:HomeworkItemTypeAudio]) {
            
            HomeworkAudioTableViewCell *audioCell = [tableView dequeueReusableCellWithIdentifier:HomeworkAudioTableViewCellId forIndexPath:indexPath];
            [audioCell setupWithAudioUrl:item.audioUrl coverUrl:item.audioCoverUrl];
            
            WeakifySelf;
            [audioCell setDeleteCallback:^{
                [weakSelf deleteAnswerItem:item];
            }];
            
            [audioCell setDeleteFileCallback:^{
                [weakSelf deleteAnswerMp3ForItem:item];
            }];
            
            cell = audioCell;
            
        }
        
    } else if (indexPath.row == 3 + self.items.count + 2 + self.answerItems.count + 1) {
        HomeworkAddTableViewCell *addCell = [tableView dequeueReusableCellWithIdentifier:HomeworkAddTableViewCellId forIndexPath:indexPath];
        
        WeakifySelf;
        [addCell setAddCallback:^{
            [weakSelf handleAddAnswerItem];
        }];
        
        cell = addCell;
    }
    else if (indexPath.row == 3 + self.items.count + 2 + self.answerItems.count + 2) {
        HomeworkSegmentTableViewCell * segmentCell = [tableView dequeueReusableCellWithIdentifier:HomeworkSegmentTableViewCellId forIndexPath:indexPath];
        
        [segmentCell updateHomeworkCategoryType:self.categoryType withStyleType:self.styleType];
        WeakifySelf;
        [segmentCell setSelectCallback:^(NSInteger index)
        {
            if (index < 3)
            {
                weakSelf.categoryType = index;
            }
            else
            {
                weakSelf.styleType = index - 2;
            }
        }];
        
        cell = segmentCell;
    }
    else if (indexPath.row == 3 + self.items.count + 2 + self.answerItems.count + 3) {
        HomeworkDiffTableViewCell * diffCell = [tableView dequeueReusableCellWithIdentifier:HomeworkDiffTableViewCellId forIndexPath:indexPath];
        [diffCell updateHomeworkLevel:self.level];
        WeakifySelf;
        [diffCell setSelectCallback:^(NSInteger index) {
            weakSelf.level = index;
        }];
        
        cell = diffCell;
    }
    else if (indexPath.row == 3 + self.items.count + 2 + self.answerItems.count + 4) {
        HomeworkLimitTimeCell * timeLimitCell = [tableView dequeueReusableCellWithIdentifier:HomeworkLimitTimeCellId forIndexPath:indexPath];
        WeakifySelf;
        [timeLimitCell updateTimeLabel:self.limitTimeSecs];
        [timeLimitCell setTimeCallback:^{
            [weakSelf handleSetTimeLimit];
        }];
        
        cell = timeLimitCell;
    }
    else if (indexPath.row == 3 + self.items.count + 2 + self.answerItems.count + 5)
    {
        HomeworkTagsTableViewCell *tagsCell = [tableView dequeueReusableCellWithIdentifier:HomeworkTagsTableViewCellId forIndexPath:indexPath];
        tagsCell.type = HomeworkTagsTableViewCellSelectSigleType;
        NSMutableArray * selectFormTags = [[NSMutableArray alloc] init];
        if (self.selectFormTag)
        {
            [selectFormTags addObject:self.selectFormTag];
        }
        [tagsCell setupWithTags:self.formTags selectedTags:selectFormTags typeTitle:@"作业类型:" collectionWidth:ScreenWidth];
        
        WeakifySelf;
        [tagsCell setSelectCallback:^(NSString *tag) {
            if (self.selectFormTag.length > 0)
            {
                self.selectFormTag = @"";
            }
            else
            {
                self.selectFormTag = tag;
            }
            
        }];
        
        [tagsCell setManageCallback:^{
            TagsViewController *tagsVC = [[TagsViewController alloc] initWithNibName:@"TagsViewController" bundle:nil];
            tagsVC.type = TagsHomeworkFormType;
            [weakSelf.navigationController pushViewController:tagsVC animated:YES];
        }];
        
        cell = tagsCell;
    }
    else
    {
        HomeworkTagsTableViewCell *tagsCell = [tableView dequeueReusableCellWithIdentifier:HomeworkTagsTableViewCellId forIndexPath:indexPath];
        tagsCell.type = HomeworkTagsTableViewCellSelectMutiType;
        [tagsCell setupWithTags:self.tags selectedTags:self.selectedTags typeTitle:@"分类标签:" collectionWidth:ScreenWidth];
        
        WeakifySelf;
        [tagsCell setSelectCallback:^(NSString *tag) {
            if ([weakSelf.selectedTags containsObject:tag]) {
                [weakSelf.selectedTags removeObject:tag];
            } else {
                [weakSelf.selectedTags addObject:tag];
            }
        }];
        
        [tagsCell setManageCallback:^{
            TagsViewController *tagsVC = [[TagsViewController alloc] initWithNibName:@"TagsViewController" bundle:nil];
            tagsVC.type = TagsHomeworkTipsType;
            [weakSelf.navigationController pushViewController:tagsVC animated:YES];
        }];
        
        cell = tagsCell;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0.f;
    
    if (indexPath.row == 0) { // 标题
        height = [HomeworkTextTableViewCell cellHeightWithText:self.homeworkTitle];
    } else if (indexPath.row == 1) { // 文本
        height = [HomeworkTextTableViewCell cellHeightWithText:self.text];
    } else if (indexPath.row == 2) { // 批改备注
        height = [HomeworkTextTableViewCell cellHeightWithText:self.teremark];
    } else if (indexPath.row == 3) { // 标签
        height = HomeworkLabelTableViewCellHeight;
    } else if (indexPath.row > 3 && indexPath.row < 3 + self.items.count + 1) { // 材料
        NSInteger row = indexPath.row - 4;
        HomeworkItem *item = self.items[row];
        NSString *type = item.type;
        if ([type isEqualToString:HomeworkItemTypeVideo]) {
            height = HomeworkVideoTableViewCellHeight;
        } else if ([type isEqualToString:HomeworkItemTypeImage]) {
            height = HomeworkImageTableViewCellHeight;
        }else if ([type isEqualToString:HomeworkItemTypeAudio]){
            if ([item.audioCoverUrl length] == 0)
            {
                height = HomeworkAudioTableViewCellHeight;
            }
            else
            {
                height = HomeworkAudioWithMp3TableViewCellHeight;
            }
        }
    } else if (indexPath.row == 3 + self.items.count + 1) { // 添加按钮
        height = HomeworkAddTableViewCellHeight;
    } else if (indexPath.row == 3 + self.items.count + 2) { // 标签
        height = HomeworkLabelTableViewCellHeight;
    } else if (indexPath.row > 3 + self.items.count + 2 &&
               indexPath.row < 3 + self.items.count + 2 + self.answerItems.count + 1) {
        NSInteger row = indexPath.row - (3 + self.items.count + 3);
        HomeworkAnswerItem *item = self.answerItems[row];
        NSString *type = item.type;
        if ([type isEqualToString:HomeworkItemTypeVideo]) {
            height = HomeworkVideoTableViewCellHeight;
        } else if ([type isEqualToString:HomeworkItemTypeImage]) {
            height = HomeworkImageTableViewCellHeight;
        }else if ([type isEqualToString:HomeworkItemTypeAudio]){
            if ([item.audioCoverUrl length] == 0)
            {
                height = HomeworkAudioTableViewCellHeight;
            }
            else
            {
                height = HomeworkAudioWithMp3TableViewCellHeight;
            }
        }
    } else if (indexPath.row == 3 + self.items.count + 2 + self.answerItems.count + 1) {
        height = HomeworkAddTableViewCellHeight;
    }
    else if (indexPath.row == 3 + self.items.count + 2 + self.answerItems.count + 2) { //作业类型
        height = HomeworkTypeTableViewCellHeight;
    }
    else if (indexPath.row == 3 + self.items.count + 2 + self.answerItems.count + 3) { //作业难度
        height = HomeworkDiffcultTableViewCellHeight;
    }
    else if (indexPath.row == 3 + self.items.count + 2 + self.answerItems.count + 4) { //作业时限
        height = HomeworkTimeLimitTableViewCellHeight;
    }
    else if (indexPath.row == 3 + self.items.count + 2 + self.answerItems.count + 5) { //form标签
        height = [HomeworkTagsTableViewCell heightWithTags:self.formTags typeTitle:@"作业类型:" collectionWidth:ScreenWidth] + 45;
    }
    else {
        height = [HomeworkTagsTableViewCell heightWithTags:self.tags typeTitle:@"分类标签:" collectionWidth:ScreenWidth];
    }
    
    return height;
}

@end


