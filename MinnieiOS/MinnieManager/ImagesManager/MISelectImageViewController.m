//
//  MISelectImageViewController.m
//  MinnieManager
//
//  Created by songzhen on 2019/8/26.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "ManagerServce.h"
#import "FileUploader.h"
#import <AVKit/AVKit.h>
#import "MILookImagesViewController.h"
#import "MISelectImageCollectionViewCell.h"
#import "MISelectImageViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface MISelectImageViewController ()<
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UIButton *uploadBtn;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *toastBgView;

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) NSMutableArray *imgaes;

@property (assign, nonatomic) NSInteger currentIndex;
@end

@implementation MISelectImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _currentIndex = -1;
    self.imgaes = [NSMutableArray array];
    [self registerCellNibs];
    [self requestWelcomesImages];
    
    
    self.toastBgView.layer.cornerRadius = 5;
    self.toastBgView.layer.masksToBounds = YES;
    
    self.view.backgroundColor = [UIColor unSelectedColor];
    self.collectionView.backgroundColor = [UIColor unSelectedColor];
//    self.uploadBtn.layer.borderColor = [UIColor separatorLineColor].CGColor;
//    self.uploadBtn.layer.borderWidth = 1.0;
}

- (IBAction)uploadImagesAction:(id)sender {
    
    if (self.imgaes.count >= 4) {
        
        [HUD showErrorWithMessage:@"最多添加四张图片"];
        return;
    }
    [self addImageItem];
}
- (IBAction)saveAction:(id)sender {
    
    [ManagerServce uploadWelcomesWithImages:self.imgaes callback:^(Result *result, NSError *error) {
        
        if (!error) {
            [HUD showWithMessage:@"保存成功"];
        }
    }];
}

- (void)saveImages{
   
    WeakifySelf;
    [ManagerServce uploadWelcomesWithImages:self.imgaes callback:^(Result *result, NSError *error) {
        
        if (!error) {
            [HUD showWithMessage:@"保存成功"];
        }
    }];
}


- (void)registerCellNibs {
    
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MISelectImageCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:MISelectImageCollectionViewCellId];
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imgaes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MISelectImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MISelectImageCollectionViewCellId
                                                                                     forIndexPath:indexPath];
    NSString *imageStr = self.imgaes[indexPath.row];
    [cell setupImage:imageStr index:indexPath.row + 1];
    
    WeakifySelf;
    cell.imageCallBack = ^(NSInteger index) {
        
        NSString *imageStr = weakSelf.imgaes[index - 1];
        weakSelf.currentIndex = index - 1;
        if (weakSelf.imageCallBack) {
            weakSelf.imageCallBack(imageStr);
        }
    };
    
    cell.deleteCallBack = ^(NSInteger index) {
        if (index - 1 < self.imgaes.count) {
            if (index - 1 == self.currentIndex) {
                
                weakSelf.currentIndex = -1;
                if (self.imageCallBack) {
                    self.imageCallBack(@"");
                }
            }
            [self.imgaes removeObjectAtIndex:index - 1];
            [self.collectionView reloadData];
        }
    };
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat width = floor((kColumnThreeWidth - 3 * 12.f)/2.f);
    CGFloat height = width *3/2;
    return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(16, 32, 16, 32);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 12;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 12;
}


#pragma mark - UIImagePickerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
//    NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    [self handlePhotoPickerResult:picker didFinishPickingMediaWithInfo:info];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
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

- (void)uploadImageForPath:(UIImage *)image
{
    WeakifySelf;
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
                [weakSelf.imgaes addObject:imageUrl];
                [weakSelf.collectionView reloadData];
                if (weakSelf.imgaes.count > 0) {
                    weakSelf.label.hidden = NO;
                } else {
                    weakSelf.label.hidden = YES;
                }
            }];
        });
    });
}

- (void)addImageItem {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeImage];
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}


- (void)requestWelcomesImages{
    
    [ManagerServce getWelcomesImagesWithType:0 callback:^(Result *result, NSError *error) {
        
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *list = (NSArray *)(dict[@"urls"]);
        
        [self.imgaes removeAllObjects];
        [self.imgaes addObjectsFromArray:list];
        if (self.imgaes.count > 0) {
            self.label.hidden = NO;
        } else {
            self.label.hidden = YES;
        }
        [self.collectionView reloadData];
    }];
}


- (void)updateData{
    
    [self requestWelcomesImages];
}

@end
