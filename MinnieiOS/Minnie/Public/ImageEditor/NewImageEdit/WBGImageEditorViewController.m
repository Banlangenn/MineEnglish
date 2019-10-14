//
//  WBGImageEditorViewController.m
//  CLImageEditorDemo
//
//  Created by Jason on 2017/2/27.
//  Copyright © 2017年 CALACULU. All rights reserved.
//

#import "WBGImageEditorViewController.h"
#import "WBGImageToolBase.h"
#import "WBGDrawTool.h"
#import "UIView+YYAdd.h"
#import "YYCategories.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Masonry.h"
NSString * const kColorPanNotificaiton = @"kColorPanNotificaiton";
NSString * const kColorPanRemoveNotificaiton = @"kColorPanRemoveNotificaiton";

#pragma mark - WBGImageEditorViewController

@interface WBGImageEditorViewController () <UINavigationBarDelegate, UIScrollViewDelegate> {
    
    __weak IBOutlet NSLayoutConstraint *topBarTop;
    
    CGFloat bottomHeight;
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topbarConstraint;  //区分x还是普通的顶部
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomBarConstraint;  //滚动区域距离底部的距离
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topDoneConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBackConstraint;

@property (nonatomic, strong, nullable) WBGImageToolBase *currentTool;
@property (weak, nonatomic) IBOutlet UIView *topBar;
@property (weak, nonatomic) IBOutlet UIButton *savePicButton;

//@property (strong, nonatomic) DrawImageView *drawingView;

@property (strong, nonatomic) IBOutlet WBGColorPan *colorPan;
@property (nonatomic, strong) WBGDrawTool *drawTool;
@property (nonatomic, assign) EditorMode currentMode;

@property (nonatomic, strong) UITapGestureRecognizer * tapGesture;

@property (nonatomic, assign) BOOL bEditing;
@property (nonatomic, assign) BOOL bFirstLoad;
@end

@implementation WBGImageEditorViewController

- (id)init
{
    self = [self initWithNibName:@"WBGImageEditorViewController" bundle:[NSBundle bundleForClass:self.class]];
    if (self){
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tapAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addTapGesture
{
    if (!_tapGesture)
    {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [self.view addGestureRecognizer:_tapGesture];
    }
}

- (void)removeTapGesture
{
    [self.view removeGestureRecognizer:_tapGesture];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.backButton.layer.cornerRadius = 10.0;
    self.doneButton.layer.cornerRadius = 10.0;
    self.backButton.backgroundColor =  [[UIColor blackColor]colorWithAlphaComponent:0.5f];
    self.doneButton.backgroundColor =  [[UIColor blackColor]colorWithAlphaComponent:0.5f];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self addTapGesture];
    [self addNotication];
    // Do any additional setup after loading the view from its nib.
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [flowLayout setMinimumInteritemSpacing:0.f];
    [flowLayout setMinimumLineSpacing:0.f];
    [flowLayout setSectionInset:UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f)];
    [flowLayout setItemSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.mCollectionView.collectionViewLayout = flowLayout;
    self.mCollectionView.pagingEnabled = YES;
    self.mCollectionView.showsVerticalScrollIndicator = NO;
    self.mCollectionView.showsHorizontalScrollIndicator = NO;
    [self registerCellNib];
    self.mCollectionView.backgroundColor = [UIColor blackColor];
    
    BOOL iPHONEX = ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO);
    
    
    if (iPHONEX)
    {
        bottomHeight = 70.0f;
        self.topbarConstraint.constant = 44.0f;
        self.topDoneConstraint.constant = 24.0f;
        self.topBackConstraint.constant = 24.0f;
    }
    else
    {
        bottomHeight = 50.0f;
        self.topbarConstraint.constant = 20.0f;
    }
    self.bottomBarConstraint.constant = bottomHeight;
    self.colorPan.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 50);
    [self.view addSubview:self.colorPan];
    

}

- (void)addNotication
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undo) name:kColorPanRemoveNotificaiton object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undo) name:kColorPanNotificaiton object:nil];
    
}

- (void)registerCellNib
{
    [self.mCollectionView registerNib:[UINib nibWithNibName:@"WBGImageEditorCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:WBGImageEditorCollectionViewCellId];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self.mCollectionView setContentOffset:CGPointMake(self.selectIndex * ScreenWidth, 0)];
     self.editorContent = (WBGImageEditorCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectIndex inSection:0]];
}

#pragma mark - 初始化 &getter
- (WBGDrawTool *)drawTool {
    if (_drawTool == nil) {
        _drawTool = [[WBGDrawTool alloc] initWithImageEditor:self];
        _drawTool.pathWidth = 5.0f;
    }
    return _drawTool;
}


#pragma mark - Property
- (void)setCurrentTool:(WBGImageToolBase *)currentTool {
    
    if (currentTool == nil)
    {
        [_currentTool cleanup];
        _currentTool = nil;
    }
    else
    {
        if(_currentTool != currentTool) {
            [_currentTool cleanup];
            _currentTool = currentTool;
            [_currentTool setup];
            
        }
    }
}

#pragma mark- ImageTool setting
+ (NSString*)defaultIconImagePath {
    return nil;
}

+ (CGFloat)defaultDockedNumber {
    return 0;
}

+ (NSString *)defaultTitle {
    return @"";
}

+ (BOOL)isAvailable {
    return YES;
}

+ (NSArray *)subtools {
    return [NSArray new];
}

+ (NSDictionary*)optionalInfo {
    return nil;
}

#pragma mark - UICollectionDelegate && Datasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (self.originalImageUrls.count > 0)
    {
        return self.originalImageUrls.count;
    }
    return self.thumbnailImages.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
    WBGImageEditorCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:WBGImageEditorCollectionViewCellId forIndexPath:indexPath];
    if (self.originalImageUrls.count > 0) {
        UIImage *thumImage;
        if (indexPath.item < self.thumbnailImages.count) {
            thumImage = [self.thumbnailImages objectAtIndex:indexPath.item];
        } else {
            thumImage = [UIImage imageNamed:@"activity_placeholder"];
        }
        [cell setupThumbImage:thumImage withOrignImageURLURL:[self.originalImageUrls objectAtIndex:indexPath.item]];
    } else {
        
        [cell setupThumbImage:[self.thumbnailImages objectAtIndex:indexPath.item] withOrignImageURLURL:nil];
    }
    return cell;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    NSLog(@")
    int autualIndex = scrollView.contentOffset.x  / scrollView.bounds.size.width;
    self.selectIndex = autualIndex;
    
    self.editorContent = (WBGImageEditorCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectIndex inSection:0]];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if(!decelerate){
        //这里复制scrollViewDidEndDecelerating里的代码
        int autualIndex = scrollView.contentOffset.x  / scrollView.bounds.size.width;
        self.selectIndex = autualIndex;
        
        self.editorContent = (WBGImageEditorCollectionViewCell *)[self.mCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectIndex inSection:0]];
    }
}

- (CGRect)caculateDrawImageFrameWithImage:(UIImage *)image{
    
    CGFloat imagH = image.size.height;
    CGFloat imagW = image.size.width;
    CGFloat screnH = [UIScreen mainScreen].bounds.size.height - 80;
    CGFloat screnW = [UIScreen mainScreen].bounds.size.width;
    CGFloat drawW = 0.0 ;
    CGFloat drawH = 0.0 ;
    if (imagH/imagW < screnH/screnW) {
        
        drawW = screnW;
        drawH = imagH/imagW * drawW;
    } else {
        drawH = screnH;
        drawW = imagW/imagH * drawH;
    }
    return CGRectMake(0, 0, drawW, drawH);
}

#pragma mark - Actions
///发送
- (IBAction)sendAction:(UIButton *)sender {

    self.bEditing = !self.bEditing;
    
    if (self.bEditing)
    {
        self.savePicButton.hidden = YES;
        [self removeTapGesture];
        [self.drawTool backToInital];
        [self.doneButton setTitle:@"完成" forState:UIControlStateNormal];
        self.mCollectionView.scrollEnabled = NO;
        if (!self.drawingView) {
            self.drawingView = [[DrawImageView alloc] init];
            self.drawingView.backgroundColor = [UIColor clearColor];
            self.drawingView.userInteractionEnabled = YES;
            self.drawingView.frame = [self caculateDrawImageFrameWithImage:self.editorContent.imageView.image];
        }
        self.drawingView.center = self.editorContent.imageView.center;
        
        [self startPanDrawMode];
        [self.editorContent.imageView.superview addSubview:self.drawingView];
        
        [UIView animateWithDuration:0.5 animations:^{
            self.colorPan.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - self->bottomHeight, [UIScreen mainScreen].bounds.size.width, 50);
        }];
    }
    else
    {
        [self.doneButton setTitle:@"编辑" forState:UIControlStateNormal];
        self.colorPan.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 50);
        self.savePicButton.hidden = NO;
        [self stopPanDrawmode];
        
        if (self.onlyForSend) {
            [self send];
            
            return;
        }
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
        
        UIAlertAction *sendAction = [UIAlertAction actionWithTitle:@"发送"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               [self send];
                                                           }];
        
        UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               [self save];
                                                           }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                          
                                                           WBGDrawTool *tool = (WBGDrawTool *)self.currentTool;
                                                           [tool backToLastDraw];
                                                       }];
        
        [alertVC addAction:sendAction];
        [alertVC addAction:saveAction];
        [alertVC addAction:cancel];
        alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:alertVC
                           animated:YES
                         completion:nil];
        
    }
}


- (void)save
{
    [self buildClipImageShowHud:YES clipedCallback:^(UIImage *clipedImage) {
        UIImageWriteToSavedPhotosAlbum(clipedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }];
}
- (IBAction)savePressed:(id)sender {
    [self save];
}

- (void)send {
    
    [self buildClipImageShowHud:YES clipedCallback:^(UIImage *clipedImage) {
        [self dismissViewControllerAnimated:YES
                                 completion:^{
                                     if (self.sendCallback != nil) {
                                         self.sendCallback(clipedImage);
                                     }
                                 }];
    }];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error == nil) {
  
        [HUD showWithMessage:@"保存成功"];
    }
}

///涂鸦模式
- (void)startPanDrawMode {
    if (_currentMode == EditorDrawMode) {
        return;
    }
    //先设置状态，然后在干别的
    self.currentMode = EditorDrawMode;
    self.currentTool = self.drawTool;
}

- (void)stopPanDrawmode
{
    if (_currentMode == EditorNonMode) {
        return;
    }

    self.currentMode = EditorNonMode;
    self.currentTool = nil;
}


- (IBAction)backAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)undo{
    if (self.currentMode == EditorDrawMode) {
        WBGDrawTool *tool = (WBGDrawTool *)self.currentTool;
        [tool backToLastDraw];
    }
}


- (void)hiddenColorPan:(BOOL)yesOrNot animation:(BOOL)animation {
    [UIView animateWithDuration:animation ? .25f : 0.f delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:yesOrNot ? UIViewAnimationOptionCurveEaseOut : UIViewAnimationOptionCurveEaseIn animations:^{
        self.colorPan.hidden = yesOrNot;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark -

+ (UIImage *)createViewImage:(UIView *)shareView {
    UIGraphicsBeginImageContextWithOptions(shareView.bounds.size, NO, [UIScreen mainScreen].scale);
    [shareView.layer renderInContext:UIGraphicsGetCurrentContext()];
    shareView.layer.affineTransform = shareView.transform;
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)buildClipImageShowHud:(BOOL)showHud clipedCallback:(void(^)(UIImage *clipedImage))clipedCallback {
    if (showHud) {
        //ShowBusyTextIndicatorForView(self.view, @"生成图片中...", nil);
    }
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.editorContent.imageView.image.size.width, self.editorContent.imageView.image.size.height),
                                               NO,
                                               self.editorContent.imageView.image.scale);
    
        [self.editorContent.imageView.image drawAtPoint:CGPointZero];
        CGFloat viewToimgW = self.editorContent.imageView.width/self.editorContent.imageView.image.size.width;
        __unused CGFloat drawX = self.editorContent.imageView.left/viewToimgW;
        [_drawingView.image drawInRect:CGRectMake(0, 0, self.editorContent.imageView.image.size.width, self.editorContent.imageView.image.size.height)];
        UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        UIImage *image = [UIImage imageWithCGImage:tmp.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        clipedCallback(image);
    
}

+ (UIImage *)screenshot:(UIView *)view orientation:(UIDeviceOrientation)orientation usePresentationLayer:(BOOL)usePresentationLayer
{
    __block CGSize targetSize = CGSizeZero;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGSize size = view.bounds.size;
        targetSize = CGSizeMake(size.width * view.layer.transformScaleX, size.height *  view.layer.transformScaleY);
    });
    
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, [UIScreen mainScreen].scale);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    dispatch_async(dispatch_get_main_queue(), ^{
        [view drawViewHierarchyInRect:CGRectMake(0, 0, targetSize.width, targetSize.height) afterScreenUpdates:NO];
    });
    CGContextRestoreGState(ctx);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end

#pragma mark - Class WBGWColorPan
@interface WBGColorPan ()
@property (nonatomic, strong) UIColor *currentColor;
@property (nonatomic, strong) NSArray * colors;

@property (nonatomic, weak) IBOutlet UIImageView *redImageView;
@property (nonatomic, weak) IBOutlet UIImageView *redSelectedImageView;
@property (nonatomic, weak) IBOutlet UIImageView *whiteImageView;
@property (nonatomic, weak) IBOutlet UIImageView *whiteSelectedImageView;
@property (nonatomic, weak) IBOutlet UIImageView *blackImageView;
@property (nonatomic, weak) IBOutlet UIImageView *blackSelectedImageView;
@property (nonatomic, weak) IBOutlet UIImageView *blueImageView;
@property (nonatomic, weak) IBOutlet UIImageView *blueSelectedImageView;


@end

@implementation WBGColorPan

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.currentColor = [UIColor colorWithHex:0xFF4858];
        @weakify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(self)
            [self configUI];
        });
    }
    return self;
}


- (IBAction)clearAction:(UIButton *)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kColorPanRemoveNotificaiton object:nil];
}

- (void)configUI
{
    self.colors = @[[UIColor colorWithHex:0xFF4858], [UIColor whiteColor], [UIColor colorWithHex:0x333333],[UIColor colorWithHex:0x0098FE]];
    
    self.redImageView.layer.cornerRadius = 13.f;
    self.redImageView.layer.masksToBounds = YES;
    self.redSelectedImageView.layer.cornerRadius = 18.f;
    self.redSelectedImageView.layer.masksToBounds = YES;
    self.redSelectedImageView.layer.borderColor = [UIColor colorWithHex:0xCCCCCC].CGColor;
    self.redSelectedImageView.layer.borderWidth = 2;
    
    self.whiteImageView.layer.cornerRadius = 13.f;
    self.whiteImageView.layer.masksToBounds = YES;
    self.whiteImageView.layer.borderColor = [UIColor colorWithHex:0x999999].CGColor;
    self.whiteImageView.layer.borderWidth = 0.5;
    self.whiteSelectedImageView.layer.cornerRadius = 18.f;
    self.whiteSelectedImageView.layer.masksToBounds = YES;
    self.whiteSelectedImageView.layer.borderColor = [UIColor colorWithHex:0xCCCCCC].CGColor;
    self.whiteSelectedImageView.layer.borderWidth = 2;
    
    self.blackImageView.layer.cornerRadius = 13.f;
    self.blackImageView.layer.masksToBounds = YES;
    self.blackSelectedImageView.layer.cornerRadius = 18.f;
    self.blackSelectedImageView.layer.masksToBounds = YES;
    self.blackSelectedImageView.layer.borderColor = [UIColor colorWithHex:0xCCCCCC].CGColor;
    self.blackSelectedImageView.layer.borderWidth = 2;
    
    
    self.blueImageView.layer.cornerRadius = 13.f;
    self.blueImageView.layer.masksToBounds = YES;
    self.blueSelectedImageView.layer.cornerRadius = 18.f;
    self.blueSelectedImageView.layer.masksToBounds = YES;
    self.blueSelectedImageView.layer.borderColor = [UIColor colorWithHex:0xCCCCCC].CGColor;
    self.blueSelectedImageView.layer.borderWidth = 2;
    
}

- (IBAction)colorBtnAction:(UIButton *)sender {
    NSInteger tag = sender.tag - 100;
    
    self.redSelectedImageView.hidden = tag!=0;
    self.whiteSelectedImageView.hidden = tag!=1;
    self.blackSelectedImageView.hidden = tag!=2;
    self.blueSelectedImageView.hidden = tag!=3;
    if (tag < self.colors.count) {
        self.currentColor = [self.colors objectAtIndex:tag];
    }
}

@end

