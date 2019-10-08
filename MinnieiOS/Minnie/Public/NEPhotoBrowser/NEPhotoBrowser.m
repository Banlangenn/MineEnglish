//
//  NEPhotoBrowser.m
//  NECatoonReader
//
//  Created by hubo on 15/9/13.
//  Copyright (c) 2015年 netease. All rights reserved.
//

#import "NEPhotoBrowser.h"
#import "NEPhotoBrowserView.h"
#import "FLAnimatedImageView.h"

static CGFloat const kPhotoBrowserImageViewMargin = 10.0; // 图片间的间距
static NSInteger const kTagOfCustomPhotoBrowserView = 1100;

@interface NEPhotoBrowser() <UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate>

@property (strong, nonatomic) UIViewController *appearViewController;

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UILabel *indexLabel;
@property (strong, nonatomic) UIButton *saveImageButton;

@property (assign, nonatomic) BOOL isHadShowedPhotoBrowser; // 是否已经显示图集
@property (assign, nonatomic) NSInteger currentImageIndex; // 当前图片index
@end

@implementation NEPhotoBrowser

- (void)viewDidLoad {
    [super viewDidLoad];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_9_0) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
#pragma clang diagnostic pop

    _currentImageIndex = _clickedImageIndex;

    if (_backgroundColor != nil) {
        self.view.backgroundColor = _backgroundColor;
    } else {
        self.view.backgroundColor = [UIColor blackColor];
    }
    self.view.alpha = 0.f;

    __typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.25f animations:^{
        weakSelf.view.alpha = 1.f;
    } completion:^(BOOL finished) {
    }];

    [self addCollectionView];
    [self addToolbars];
    [self updateFrames];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!_isHadShowedPhotoBrowser) {
        [self showPhotoBrowser];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_9_0) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
#pragma clang diagnostic pop

    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self updateFrames];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Public

- (void)showInContext:(UIViewController * __nonnull)context {
    self.appearViewController = context;
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    [context presentViewController:self animated:NO completion:nil];
}

#pragma mark - Private UI About

- (void)showPhotoBrowser {
    UIImageView *appearImageView = [[UIImageView alloc] initWithFrame:self.clickedImageViewRect];
    appearImageView.contentMode = _clickedImageView.contentMode;
    appearImageView.clipsToBounds = YES;
    appearImageView.image = [self placeholderImageForIndex:_currentImageIndex];
    [self.view addSubview:appearImageView];

    CGRect targetFrame = CGRectZero;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat placeHolderHeight = 0.f;
    CGFloat placeHolderWidth = 0.f;

    // 进入全屏看大图，实际图片宽度<＝100时，按照＊3后显示，其它尺寸按宽度全屏显示
    CGFloat imageWidth = appearImageView.image.size.width;
    CGFloat imageHeight = appearImageView.image.size.height;
    if (imageWidth <= 100 && !self.isScaleToScreenWidth) {
        // 小图显示
        placeHolderHeight = (imageWidth * 3) / scale;
        placeHolderWidth = (imageHeight * 3) / scale;
    } else {
        // 大图全屏显示
        placeHolderHeight = (appearImageView.image.size.height * [UIScreen mainScreen].bounds.size.width) / appearImageView.image.size.width;
        placeHolderWidth = [UIScreen mainScreen].bounds.size.width;
    }

    if (placeHolderHeight <= [UIScreen mainScreen].bounds.size.height) {
        targetFrame = CGRectMake(([UIScreen mainScreen].bounds.size.width - placeHolderWidth) * 0.5, ([UIScreen mainScreen].bounds.size.height - placeHolderHeight) * 0.5f , placeHolderWidth, placeHolderHeight);
    } else {
        targetFrame = CGRectMake(([UIScreen mainScreen].bounds.size.width - placeHolderWidth) * 0.5, 0.f, placeHolderWidth, placeHolderHeight);
    }

    // 动画显示
    _collectionView.hidden = YES;
    _indexLabel.hidden = YES;
    _saveImageButton.hidden = YES;
    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveLinear animations:^{
        [appearImageView setFrame:targetFrame];
    } completion:^(BOOL finished) {
        self.isHadShowedPhotoBrowser = YES;
        [appearImageView removeFromSuperview];

        self.collectionView.hidden = NO;
        self.indexLabel.hidden = NO;
        self.saveImageButton.hidden = NO;
        [self.collectionView reloadData];
    }];
}

- (void)hidePhotoBrowser:(UITapGestureRecognizer *)recognizer {
    NEPhotoBrowserView *currentBrowserView  = (NEPhotoBrowserView *)recognizer.view;
    FLAnimatedImageView *currentImageView = currentBrowserView.imageView;

    UIImageView *disappearImageView = [[UIImageView alloc] initWithFrame:currentImageView.frame];
    disappearImageView.contentMode = _clickedImageView.contentMode;
    disappearImageView.clipsToBounds = YES;
    disappearImageView.image = currentImageView.image;
    [self.view.window addSubview:disappearImageView];

    [currentBrowserView removeFromSuperview];

    // 动画消失
    CGRect disappearImageViewRect = CGRectZero;
    if (_currentImageIndex == _clickedImageIndex) {
        disappearImageViewRect = self.clickedImageViewRect;
    } else {
        disappearImageViewRect = [self getSubImageViewRectWithIndex:_currentImageIndex];
    }

    [self dismissViewControllerAnimated:NO completion:^{
        if (CGRectGetMinY(disappearImageViewRect) != 0 &&
            CGRectGetWidth(disappearImageViewRect) != 0 &&
            CGRectGetHeight(disappearImageViewRect) != 0) {
            [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveLinear animations:^{
                disappearImageView.frame = disappearImageViewRect;
            } completion:^(BOOL finished) {
                [disappearImageView removeFromSuperview];
            }];
        } else {
            [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveLinear animations:^{
                [disappearImageView setAlpha:0.f];
            } completion:^(BOOL finished) {
                [disappearImageView removeFromSuperview];
            }];
        }
    }];
}

- (void)addCollectionView {
    if (_collectionView != nil) {
        return;
    }

    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [flowLayout setMinimumInteritemSpacing:0.f];
    [flowLayout setMinimumLineSpacing:0.f];
    [flowLayout setSectionInset:UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f)];
    [flowLayout setItemSize:CGSizeMake([UIScreen mainScreen].bounds.size.width + kPhotoBrowserImageViewMargin, [UIScreen mainScreen].bounds.size.height)];

    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.pagingEnabled = YES;
    _collectionView.hidden = YES;
    _collectionView.bounces = YES;

    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"NECBrowserUICollectionViewCell"];
    [self.view addSubview:_collectionView];
}

- (void)addToolbars {
    if (_indexLabel == nil && [self numberOfPhotos] > 1 && !_hiddenIndexLabel) {
        _indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(25.f, [UIScreen mainScreen].bounds.size.height - 50.f, 100.f, 25.f)];

        _indexLabel.textAlignment = NSTextAlignmentLeft;
        if (_indexLabelTextColor != nil) {
            _indexLabel.textColor = _indexLabelTextColor;
        } else {
            _indexLabel.textColor = [UIColor colorWithRed:255.f/255.f green:255.f/255.f blue:255.f/255.f alpha:0.3f];
        }
        if (_indexLabelFont != nil) {
            _indexLabel.font = _indexLabelFont;
        } else {
            _indexLabel.font = [UIFont boldSystemFontOfSize:12];
        }

        NSString *indexSting = [NSString stringWithFormat:@"%@/",@(1)];
        NSString *text = [NSString stringWithFormat:@"%@%@",indexSting,@([self numberOfPhotos])];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
        NSRange range = [text rangeOfString:indexSting];
        if (range.length > 0) {
            if (_indexLabelTextColorForCurrent != nil) {
                [attributedString addAttribute:NSForegroundColorAttributeName value:_indexLabelTextColorForCurrent range:range];
            } else {
                [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255.f/255.f green:255.f/255.f blue:255.f/255.f alpha:0.6f] range:range];
            }

            if (_indexLabelFontForCurrent != nil) {
                [attributedString addAttribute:NSFontAttributeName value:_indexLabelFontForCurrent range:range];
            } else {
                [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:22.f] range:range];
            }
        }
        [_indexLabel setAttributedText:attributedString];

        [self.view addSubview:_indexLabel];
    }

    if (_saveImageButton == nil && !_hiddenSaveImageButton) {
        _saveImageButton = [[UIButton alloc] init];
        if (_saveImageForNormal != nil) {
            [_saveImageButton setImage:_saveImageForNormal forState:UIControlStateNormal];
        } else {
            [_saveImageButton setImage:[UIImage imageNamed:[@"NEPhotoBrowser.bundle" stringByAppendingPathComponent:@"default_save_image"]] forState:UIControlStateNormal];
        }
        if (_saveImageForHighlight != nil) {
            [_saveImageButton setImage:_saveImageForHighlight forState:UIControlStateHighlighted];
        } else {
            [_saveImageButton setImage:[UIImage imageNamed:[@"NEPhotoBrowser.bundle" stringByAppendingPathComponent:@"default_save_image_pressed"]] forState:UIControlStateHighlighted];
        }
        [_saveImageButton addTarget:self action:@selector(saveImageButtonDidPressed) forControlEvents:UIControlEventTouchUpInside];
        [_saveImageButton setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 58.f, [UIScreen mainScreen].bounds.size.height - 58.f, 42.f, 42.f)];

        [self.view addSubview:_saveImageButton];
    }
}

- (void)updateFrames {
    CGRect rect = self.view.bounds;
    rect.size.width += kPhotoBrowserImageViewMargin;
    _collectionView.bounds = rect;
    _collectionView.center = CGPointMake((([UIScreen mainScreen].bounds.size.width + kPhotoBrowserImageViewMargin) * 0.5f), [UIScreen mainScreen].bounds.size.height * 0.5);

    _collectionView.contentOffset = CGPointMake(_currentImageIndex * _collectionView.frame.size.width, 0.f);

    _indexLabel.frame = CGRectMake(25.f, [UIScreen mainScreen].bounds.size.height - 50.f, 100.f, 25.f);
    _saveImageButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 58.f, [UIScreen mainScreen].bounds.size.height - 58.f, 44.f, 44.f);
}

// 计算当前点击imageView在当前viewController在frame，用来动画显示和消失
- (CGRect)clickedImageViewRect {
    // 外面传入了rect则使用传入的，否则使用自动计算的
    if (CGRectGetMinY(_clickedImageViewRect) != 0 &&
        CGRectGetWidth(_clickedImageViewRect) != 0 &&
        CGRectGetHeight(_clickedImageViewRect) != 0) {
        return _clickedImageViewRect;
    } else {
        UIViewController *appearViewController = self.appearViewController;
        CGRect appearImageViewRect = [appearViewController.view convertRect:self.clickedImageView.frame fromView:self.clickedImageView.superview];
//        if (!appearViewController.navigationController.navigationBar.isHidden) {
//            appearImageViewRect.origin.y += 64.f;
//        }
//        if (!appearViewController.tabBarController.tabBar.isHidden) {
//            appearImageViewRect.origin.y += 64.f;
//        }

        return appearImageViewRect;
    }
}

//  获取_imageViewsContainerView subview对应的frame，用来动画消失
- (CGRect)getSubImageViewRectWithIndex:(NSInteger)index {
    if (_imageViewsContainerView == nil) {
        return CGRectZero;
    }

    CGRect disappearImageViewRect = CGRectZero;
    UIViewController *appearViewController = self.appearViewController;

    if ([_imageViewsContainerView isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)_imageViewsContainerView;
        UICollectionViewCell *indexCell = [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        if (indexCell != nil) {
            disappearImageViewRect = [appearViewController.view convertRect:indexCell.frame fromView:collectionView];
            if (!appearViewController.navigationController.navigationBar.isHidden) {
                // 加上navigationBar的y轴偏移
                disappearImageViewRect.origin.y += 64.f;
            }

            // 加上appearViewController.view的y轴偏移
            disappearImageViewRect.origin.y += CGRectGetMinY(appearViewController.view.frame);
        }
    } else if ([_imageViewsContainerView isKindOfClass:[UIView class]]) {
        if (index >= _imageViewsContainerView.subviews.count) {
            return CGRectZero;
        }

        UIView *subView = self.imageViewsContainerView.subviews[index];
        if (![subView isKindOfClass:[UIImageView class]]) {
            return CGRectZero;
        }
        subView = (UIImageView *)subView;
        disappearImageViewRect = [appearViewController.view convertRect:subView.frame fromView:self.clickedImageView.superview];
        if (!appearViewController.navigationController.navigationBar.isHidden) {
            // 加上navigationBar的y轴偏移
            disappearImageViewRect.origin.y += 64.f;
        }
        // 加上appearViewController.view的y轴偏移
        disappearImageViewRect.origin.y += CGRectGetMinY(appearViewController.view.frame);

        // 加载tabbar的偏移
        if (!appearViewController.tabBarController.tabBar.isHidden) {
            disappearImageViewRect.origin.y += 64.f;
        }

        return disappearImageViewRect;
    }

    return disappearImageViewRect;
}

#pragma mark - Save Image

- (void)saveImageButtonDidPressed {
    int currentImageIndex = _collectionView.contentOffset.x / _collectionView.bounds.size.width;
    UICollectionViewCell *currentCell = [_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:currentImageIndex inSection:0]];
    NEPhotoBrowserView *currentBrowerView = [currentCell.contentView viewWithTag:kTagOfCustomPhotoBrowserView];

    if (currentBrowerView != nil && currentBrowerView.isHadLoadedImage) {
        UIImageWriteToSavedPhotosAlbum(currentBrowerView.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        if ([_delegate respondsToSelector:@selector(photoBrowser:willSavePhotoWithView:)]) {
            [_delegate photoBrowser:self willSavePhotoWithView:currentBrowerView];
        }
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        if ([_delegate respondsToSelector:@selector(photoBrowser:savePhotoErrorWithError:)]) {
            [_delegate photoBrowser:self savePhotoErrorWithError:error];
        }
    } else {
        if ([_delegate respondsToSelector:@selector(photoBrowser:didSavePhotoSuccessWithImage:)]) {
            [_delegate photoBrowser:self didSavePhotoSuccessWithImage:image];
        }
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self numberOfPhotos];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NECBrowserUICollectionViewCell" forIndexPath:indexPath];

    NEPhotoBrowserView *view = [cell.contentView viewWithTag:kTagOfCustomPhotoBrowserView];
    if (view == nil) {
        view = [[NEPhotoBrowserView alloc] initWithFrame:CGRectMake(0.f, 0.f, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        view.isScaleToScreenWidth = self.isScaleToScreenWidth;
        [view setTag:kTagOfCustomPhotoBrowserView];

        // 单击隐藏
        __weak __typeof__(self) weakSelf = self;
        view.singleTapBlock = ^(UITapGestureRecognizer *recognizer){
            __strong __typeof__(self) strongSelf = weakSelf;
            [strongSelf hidePhotoBrowser:recognizer];
        };

        [cell.contentView addSubview:view];
    }

    // 还原图片zoomScale
    for (UICollectionViewCell *aCell in _collectionView.visibleCells) {
        NEPhotoBrowserView *aView = [aCell.contentView viewWithTag:kTagOfCustomPhotoBrowserView];
        if (aView != nil) {
            [view resetImageView];
        }
    }

    // 加载图片
    if (indexPath.row == _clickedImageIndex) {
        view.hideLoadingView = YES; // 有默认缩略图则不显示loading
    } else {
        view.hideLoadingView = NO;
    }

    if ([self imageURLForIndex:indexPath.row]) {
        [view loadImageWithURL:[self imageURLForIndex:indexPath.row] placeholderImage:[self placeholderImageForIndex:indexPath.row]];
    } else {
        view.imageView.image = [self placeholderImageForIndex:indexPath.row];
    }

    return cell;
}

#pragma mark - ScrollviewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int currentImageIndex = (scrollView.contentOffset.x + scrollView.bounds.size.width * 0.5f) / scrollView.bounds.size.width;

    _indexLabel.text = [NSString stringWithFormat:@"%@/%@", @(currentImageIndex + 1), @([self numberOfPhotos])];
    NSString *indexSting = [NSString stringWithFormat:@"%@/", @(currentImageIndex + 1)];
    NSString *allText = [NSString stringWithFormat:@"%@%@", indexSting, @([self numberOfPhotos])];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:allText];
    NSRange range = [allText rangeOfString:indexSting];

    if (range.length > 0) {
        if (_indexLabelTextColorForCurrent != nil) {
            [attributedString addAttribute:NSForegroundColorAttributeName value:_indexLabelTextColorForCurrent range:range];
        } else {
            [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255.f/255.f green:255.f/255.f blue:255.f/255.f alpha:0.6f] range:range];
        }

        if (_indexLabelFontForCurrent != nil) {
            [attributedString addAttribute:NSFontAttributeName value:_indexLabelFontForCurrent range:range];
        } else {
            [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:22.f] range:range];
        }
    }
    [_indexLabel setAttributedText:attributedString];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    int autualIndex = scrollView.contentOffset.x  / scrollView.bounds.size.width;
    if (_currentImageIndex != autualIndex) {
        if ([_delegate respondsToSelector:@selector(photoBrowser:scrollToIndex:)]) {
            [_delegate photoBrowser:self scrollToIndex:autualIndex];
        }
    }
    _currentImageIndex = autualIndex;
}

#pragma mark - DataSource Get

- (NSInteger)numberOfPhotos {
    if ([_dataSource respondsToSelector:@selector(numberOfPhotosInPhotoBrowser:)]) {
        return [_dataSource numberOfPhotosInPhotoBrowser:self];
    }

    return 1;
}

- (NSURL *)imageURLForIndex:(NSInteger)index {
    if ([_dataSource respondsToSelector:@selector(photoBrowser:imageURLForIndex:)]) {
        return [_dataSource photoBrowser:self imageURLForIndex:index];
    }

    return nil;
}

- (UIImage *)placeholderImageForIndex:(NSInteger)index {
    if (_clickedImageView != nil && index == _clickedImageIndex) {
        return _clickedImageView.image;
    } else if ([_dataSource respondsToSelector:@selector(photoBrowser:placeholderImageForIndex:)]) {
        return [_dataSource photoBrowser:self placeholderImageForIndex:index];
    } else {
        return [UIImage imageNamed:[@"NEPhotoBrowser.bundle" stringByAppendingPathComponent:@"default_placeholder"]];
    }
}

#pragma mark - System Autorotate

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
