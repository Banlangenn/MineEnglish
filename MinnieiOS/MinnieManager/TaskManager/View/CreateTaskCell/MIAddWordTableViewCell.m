//
//  MIAddWordTableViewCell.m
//  MinnieManager
//
//  Created by songzhen on 2019/6/6.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <objc/runtime.h>
#import "MIAddWordTableViewCell.h"
#import "MIEqualSpaceFlowLayout.h"
#import "MIWordTagCollectionViewCell.h"

static const char keyOfPickerDocument;

NSString * const MIAddWordTableViewCellId = @"MIAddWordTableViewCellId";

@interface MIAddWordTableViewCell ()
<
UIWebViewDelegate,
UIDocumentPickerDelegate,
UICollectionViewDelegate,
UICollectionViewDataSource,
MIEqualSpaceFlowLayoutDelegate
>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) NSInteger collecttionViewWidth;

@property (nonatomic, strong) NSMutableArray *dataArray;


@property (nonatomic, assign) NSInteger createType;
@property (nonatomic, assign) BOOL isEditState;

@end

@implementation MIAddWordTableViewCell


- (void)awakeFromNib {
    [super awakeFromNib];
    
    if (@available(iOS 12.0, *)) {
        // Addresses a separate issue and prevent auto layout warnings due to the temporary width constraint in the xib.
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *leftConstraint = [self.contentView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:0];
        NSLayoutConstraint *rightConstraint = [self.contentView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:0];
        NSLayoutConstraint *topConstraint = [self.contentView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0];
        NSLayoutConstraint *bottomConstraint = [self.contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0];
        
        [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, bottomConstraint]];
    }
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.dataArray = [NSMutableArray array];
}


- (void)setupAwordWithDataArray:(NSArray <WordInfo *> *)dataArray
                 collectionView:(CGFloat)collectionWidth{
   
    _collecttionViewWidth = collectionWidth;
    if (dataArray.count) {
        self.titleLabel.text = [NSString stringWithFormat:@"添加单词:(%lu)",dataArray.count];
    } else {
        self.titleLabel.text = @"添加单词:";
    }
    self.createType = MIHomeworkCreateContentType_AddWords;
    [self.dataArray removeAllObjects];
    [self.dataArray addObjectsFromArray:dataArray];
    // 添加按钮
    WordInfo *wordInfo = [[WordInfo alloc] init];
    wordInfo.english = @"+";
    wordInfo.chinese = @"添加单词";
    [self.dataArray addObject:wordInfo];
    // 批量导入
    WordInfo *excelInfo = [[WordInfo alloc] init];
    excelInfo.english = @"+";
    excelInfo.chinese = @"从文件导入";
    [self.dataArray addObject:excelInfo];
    
    if (!self.collectionView) {
        [self addContentView];
    }
    self.collectionView.frame = CGRectMake(0, 30, _collecttionViewWidth, [MIAddWordTableViewCell heightWithTags:self.dataArray collectionView:collectionWidth]);
 
    [self.collectionView reloadData];
}

- (void)setupParticipateWithClazzArray:(NSArray <Clazz *> *)clazzArray
                          studentArray:(NSArray <User *> *)studentArray
                        collectionView:(CGFloat)collectionWidth{
    
    _collecttionViewWidth = collectionWidth;
    if (clazzArray.count + studentArray.count) {
        self.titleLabel.text = [NSString stringWithFormat:@"添加参与对象:(%lu)",clazzArray.count + studentArray.count];
    } else {
        self.titleLabel.text = @"添加参与对象:";
    }
    self.createType = MIHomeworkCreateContentType_ActivityParticipant;
    [self.dataArray removeAllObjects];
    [self.dataArray addObjectsFromArray:clazzArray];
    [self.dataArray addObjectsFromArray:studentArray];
    [self.dataArray addObject:@" + 添加对象"];
    if (!self.collectionView) {
        [self addContentView];
    }
    self.collectionView.frame = CGRectMake(0, 40, _collecttionViewWidth, [MIAddWordTableViewCell heightWithTags:self.dataArray collectionView:collectionWidth]);

    [self.collectionView reloadData];
}


+ (CGFloat)heightWithTags:(NSArray*)tags collectionView:(CGFloat)collectionWidth{
    
    if (tags.count == 0) {
        return 50.f;
    }
    CGFloat leftSpace = 10;
    CGFloat topSpace = 10;
    CGFloat rightSpace = 10;
    CGFloat minimumInteritemSpacing = 10;
    CGFloat minimumLineSpacing = 10;
    
    CGFloat xOffset = leftSpace;
    CGFloat yOffset = topSpace;
    CGFloat xNextOffset = leftSpace;
    
    CGFloat height = 0;
    
    CGFloat collecttionViewWidth = collectionWidth;
    for (NSInteger idx = 0; idx < tags.count; idx++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
      
        CGSize itemSize ;
        if ([tags[indexPath.row] isKindOfClass:[WordInfo class]]) {
            
           itemSize = [MIWordTagCollectionViewCell cellSizeWithTag:tags[indexPath.row]];
           NSLog(@" ********* %f %f %@",height,itemSize.width,((WordInfo *)tags[indexPath.row]).english);
        } else {
            
            NSString *tag;
            if ([tags[indexPath.row] isKindOfClass:[NSString class]]) {
                tag = tags[indexPath.row];
            } else if ([tags[indexPath.row] isKindOfClass:[WordInfo class]]) {
                
                tag = ((WordInfo *)tags[indexPath.row]).english;
            } else if ([tags[indexPath.row] isKindOfClass:[Clazz class]]) {
                tag = ((Clazz *)tags[indexPath.row]).name;
            } else if ([tags[indexPath.row] isKindOfClass:[User class]]) {
                tag = ((User *)tags[indexPath.row]).nickname;
            }
            itemSize = [MIWordTagCollectionViewCell cellSizeWithTag:tag];
        }
        itemSize.width = itemSize.width + 10;
        
        xNextOffset += (minimumInteritemSpacing + itemSize.width);
        if (xNextOffset >= collecttionViewWidth - rightSpace ) {
           
            xOffset = leftSpace;
            xNextOffset = (leftSpace + minimumInteritemSpacing + itemSize.width);
            yOffset += (itemSize.height + minimumLineSpacing);
        }
        else
        {
            xOffset = xNextOffset - (minimumInteritemSpacing + itemSize.width);
        }
        height = yOffset + itemSize.height + 10;
    }
    return height;
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    MIWordTagCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MIWordTagCollectionViewCellId
                                                                            forIndexPath:indexPath];
    NSString *tag;
    if ([self.dataArray[indexPath.row] isKindOfClass:[WordInfo class]]) {
        WordInfo *word = self.dataArray[indexPath.row];
       
        if (indexPath.row >= self.dataArray.count - 2) {
            [cell setupWithText:word isEditState:self.isEditState isLast:YES];
        } else {
            [cell setupWithText:word isEditState:self.isEditState isLast:NO];
        }
    } else {
        
        if ([self.dataArray[indexPath.row] isKindOfClass:[NSString class]]) {
            tag = self.dataArray[indexPath.row];
        } else if ([self.dataArray[indexPath.row] isKindOfClass:[Clazz class]]) {
            Clazz *clazz = self.dataArray[indexPath.row];
            tag = clazz.name;
        } else if ([self.dataArray[indexPath.row] isKindOfClass:[User class]]) {
            User *student = self.dataArray[indexPath.row];
            tag = student.nickname;
        }
        if (indexPath.row == self.dataArray.count - 1) {
            [cell setupWithText:tag isEditState:self.isEditState isLast:YES];
        } else {
            [cell setupWithText:tag isEditState:self.isEditState isLast:NO];
        }
    }

    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    if (indexPath.row < self.dataArray.count - 2) {
      
        if (self.isEditState) {
            
            id tag = self.dataArray[indexPath.row];
            [self.dataArray removeObject:tag];
            if (self.callback) {
                NSMutableArray *returnArray = [NSMutableArray arrayWithArray:self.dataArray];
                [returnArray removeLastObject];
                [returnArray removeLastObject];
                self.callback(NO,returnArray);
            }
            [self.collectionView reloadData];
        } else {
            if (self.editWordCallBack) {// 点击编辑单词
                self.editWordCallBack(indexPath.row);
            }
        }
    } else {
        
        if (indexPath.row == self.dataArray.count - 2) {// 添加

            if (self.isEditState) {
                self.isEditState = NO;
                [self.collectionView reloadData];
            }
            if (self.callback) {
                NSMutableArray *returnArray = [NSMutableArray arrayWithArray:self.dataArray];
                [returnArray removeLastObject];
                [returnArray removeLastObject];
                self.callback(YES,returnArray);
            }
        } else {// 批量导入

           if (self.isEditState) {
               self.isEditState = NO;
               [self.collectionView reloadData];
           }
            [self chooseExcelFile];

        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.dataArray[indexPath.row] isKindOfClass:[WordInfo class]]) {
        WordInfo *word = self.dataArray[indexPath.row];
        
        CGSize itemSize = [MIWordTagCollectionViewCell cellSizeWithTag:word];
        // 标签长度大于屏幕
        if (itemSize.width > _collecttionViewWidth -30) {
            
            itemSize.width = _collecttionViewWidth - 30;
        }
        return itemSize;
    } else {
       
        NSString *tag;
        if ([self.dataArray[indexPath.row] isKindOfClass:[NSString class]]) {
            tag = self.dataArray[indexPath.row];
        } else if ([self.dataArray[indexPath.row] isKindOfClass:[Clazz class]]) {
            Clazz *clazz = self.dataArray[indexPath.row];
            tag = clazz.name;
        } else if ([self.dataArray[indexPath.row] isKindOfClass:[User class]]) {
            User *student = self.dataArray[indexPath.row];
            tag = student.nickname;
        }
        CGSize itemSize = [MIWordTagCollectionViewCell cellSizeWithTag:tag];
        // 标签长度大于屏幕
        if (itemSize.width > _collecttionViewWidth -30) {
            
            itemSize.width = _collecttionViewWidth - 30;
        }
        return itemSize;
    }
   
}

- (void)addContentView{
    
    MIEqualSpaceFlowLayout *flowLayout = [[MIEqualSpaceFlowLayout alloc] initWithCollectionViewWidth:_collecttionViewWidth];
    flowLayout.delegate = self;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 50, _collecttionViewWidth, 50) collectionViewLayout:flowLayout];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self addSubview:self.collectionView];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MIWordTagCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:MIWordTagCollectionViewCellId];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [self.collectionView addGestureRecognizer:longPress];
}

- (void)longPressAction:(UILongPressGestureRecognizer *)longPress{
    
    if (longPress.state == UIGestureRecognizerStateEnded) {
       
        self.isEditState = !self.isEditState;
        [self.collectionView reloadData];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
 
    if (self.isEditState) {
        self.isEditState = NO;
    }
}

#pragma mark - 从Excel中导入
- (void)chooseExcelFile {
    // 适配ipad版本
    UIAlertControllerStyle alertStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        alertStyle = UIAlertControllerStyleActionSheet;
    } else {
        alertStyle = UIAlertControllerStyleAlert;
    }
    NSString *title= @"选择文件类型";
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title
                                                                     message:nil
                                                              preferredStyle:alertStyle];
    UIAlertAction * fileAction = [UIAlertAction actionWithTitle:@"文件"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                          
        
        UIDocumentPickerViewController * picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"com.microsoft.excel.xls",
        @"com.microsoft.excel.xlsx",
        @"public.data"] inMode:UIDocumentPickerModeImport];
        picker.delegate = self;
        objc_setAssociatedObject(picker , &keyOfPickerDocument, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self presentVC:picker];
                                                        }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];

    [alertVC addAction:fileAction];
    [alertVC addAction:cancelAction];
    [self presentVC:alertVC];
}

- (void)presentVC:(UIViewController *)VC{
    
#if MANAGERSIDE
    
    UIViewController *rootController = self.window.rootViewController;
    rootController.modalPresentationStyle = UIModalPresentationFullScreen;
    [rootController presentViewController:VC animated:YES completion:nil];
#else
    
    VC.modalPresentationStyle = UIModalPresentationFullScreen;
    
    UIViewController *rootController = self.window.rootViewController;
    rootController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [rootController presentViewController:VC
                          animated:YES
                        completion:nil];
#endif
    
}


#pragma mark - UIDocumentPickerDelegate
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    id homeworkItem = objc_getAssociatedObject(controller, &keyOfPickerDocument);
    
    if (controller.documentPickerMode == UIDocumentPickerModeImport)
    {
        // 通过文件协调器读取文件地址
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        WeakifySelf;
        [fileCoordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:nil  byAccessor:^(NSURL * _Nonnull newURL) {
            // 读取文件
            NSString *fileName = [newURL lastPathComponent];
            [weakSelf saveLocalCachesCont:newURL fileName:fileName withObject:homeworkItem];
        }];
    }
}

- (void)saveLocalCachesCont:(NSURL * )fileUrl fileName:(NSString *)name withObject:(id)object
{

//    NSData *fileData = [NSData dataWithContentsOfURL:fileUrl];
    NSString *extension = [fileUrl pathExtension];
    if ([extension isEqualToString:@"xls"] || [extension isEqualToString:@"xlsx"]) {
        
        UIWebView *excelWebView = [[UIWebView alloc] initWithFrame:CGRectZero];
        excelWebView.delegate = self;
        NSURLRequest *request = [NSURLRequest requestWithURL:fileUrl];
        [excelWebView loadRequest:request];
    }
}
#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
    NSString *str = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerText"];
    NSArray *array = [str componentsSeparatedByString:@"\n"];
    for (NSString *string in array) {
        
      NSLog(@"webViewDidFinishLoad %@",[string componentsSeparatedByString:@"\t"].description);
    }
}

@end
