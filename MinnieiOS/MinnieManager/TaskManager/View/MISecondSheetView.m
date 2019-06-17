//
//  SecondSheetView.m
//  Manager
//
//  Created by songzhen on 2019/5/27.
//  Copyright © 2019 songzhen. All rights reserved.
//

#import "MIEidtFileView.h"
#import "ManagerServce.h"
#import "ParentFileInfo.h"
#import "MIRootSheetView.h"
#import "MISecondSheetView.h"
#import "MICreateFolderView.h"
#import "MIHeaderTableViewCell.h"
#import "Result.h"
@interface MISecondSheetView ()<
HeaderViewDelegate,
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic,strong) UITableView *tableView;


@property (nonatomic,assign) CGFloat viewWidth;

// 当前选中的二级文件夹 -1为未选中任何文件夹
@property (nonatomic,assign) NSInteger currentIndex;
// 当前展开一级文件 id -1为未展开任何文件夹
@property (nonatomic,assign) NSInteger currentParentFileId;

@property (nonatomic, strong) NSMutableArray *parentFileList;
@end

@implementation MISecondSheetView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _viewWidth = frame.size.width;
        _currentIndex = -1;
        _currentParentFileId = -1;
        self.parentFileList = [NSMutableArray array];
        [self configureUI];
    }
    return self;
}

- (void)configureUI{
    
    UIButton *recordbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [recordbtn setTitle:@"发送记录" forState:UIControlStateNormal];
    recordbtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [recordbtn setTitleColor:[UIColor mainColor] forState:UIControlStateNormal];
    [recordbtn addTarget:self action:@selector(recordbtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:recordbtn];
    recordbtn.frame = CGRectMake(12, kNaviBarHeight - 32, 80, 32);
    recordbtn.layer.masksToBounds = YES;
    recordbtn.layer.cornerRadius = 5.f;
    recordbtn.layer.borderWidth = 0.5;
    recordbtn.layer.borderColor = [UIColor mainColor].CGColor;
    
    UIButton *addFolderbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [addFolderbtn setTitle:@"添加文件夹" forState:UIControlStateNormal];
    addFolderbtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [addFolderbtn setTitleColor:[UIColor detailColor] forState:UIControlStateNormal];
    [addFolderbtn setImage:[UIImage imageNamed:@"ic_add_black"] forState:UIControlStateNormal];
    [addFolderbtn addTarget:self action:@selector(addFolderBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:addFolderbtn];
    addFolderbtn.frame = CGRectMake(12, kNaviBarHeight, 90, kNaviBarHeight);
    
    
    UIView *lineView1 = [[UIView alloc] initWithFrame:CGRectMake( 0, kNaviBarHeight*2 - 1, kFolderModularWidth, 1.0)];
    lineView1.backgroundColor = [UIColor separatorLineColor];
    [self addSubview:lineView1];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, kNaviBarHeight * 2, _viewWidth, ScreenHeight - kNaviBarHeight *2)style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self addSubview:_tableView];
    _tableView.separatorColor = [UIColor separatorLineColor];

    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(kFolderModularWidth - 1, 0, 0.5, ScreenHeight)];
    lineView.backgroundColor = [UIColor separatorLineColor];
    [self addSubview:lineView];

    UIView *footrView = [[UIView alloc] init];
    footrView.backgroundColor = [UIColor clearColor];
    _tableView.tableFooterView = footrView;
    _tableView.cellLayoutMarginsFollowReadableWidth = NO;
}

#pragma mark -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.parentFileList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return MIHeaderTableViewCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return MIHeaderTableViewCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
  
    return 0.1f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    ParentFileInfo *parentInfo = self.parentFileList[section];
    if (parentInfo.fileInfo.isOpen) {
        return parentInfo.subFileList.count;
    } else {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ParentFileInfo *parentInfo = self.parentFileList[indexPath.section];
    FileInfo *subFileInfo = parentInfo.subFileList[indexPath.row];

    MIHeaderTableViewCell *fileCell = [tableView dequeueReusableCellWithIdentifier:MIHeaderTableViewCellId];
    if (fileCell == nil) {
        fileCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIHeaderTableViewCell class]) owner:nil options:nil] lastObject];
        fileCell.selectionStyle = UITableViewCellSelectionStyleNone;
        fileCell.delegate = self;
    }
    BOOL selected = (indexPath.row == _currentIndex) ? YES : NO;
    [fileCell setupFilesWithFileInfo:subFileInfo indexPath:indexPath isParentFile:NO selected:selected];
    return fileCell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    ParentFileInfo *parentFileInfo = self.parentFileList[section];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 60)];
    view.backgroundColor = [UIColor whiteColor];
    MIHeaderTableViewCell *headerView = [[[NSBundle mainBundle] loadNibNamed:@"MIHeaderTableViewCell" owner:self options:nil] lastObject];
    headerView.frame = view.bounds;
    headerView.delegate = self;
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:section];
    [headerView setupFilesWithFileInfo:parentFileInfo indexPath:path isParentFile:YES selected:NO];
    headerView.tag = 1000+section;
    [view addSubview:headerView];
    return view;
}
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//
//    ParentFileInfo *parentInfo = self.parentFileList[indexPath.section];
//    FileInfo *subFileInfo = parentInfo.subFileList[indexPath.row];
//    _currentIndex = indexPath.row;
//    // 任务管理二级文件夹
//    if (self.delegate && [self.delegate respondsToSelector:@selector(secondSheetViewSecondLevelData:index:)]) {
//
//        [self.delegate secondSheetViewSecondLevelData:subFileInfo index:indexPath.row];
//    }
//    [tableView reloadData];
//}


#pragma mark -  HeaderViewDelegate  一级、二级文件展开折叠
- (void)headerViewDidCellClicked:(NSIndexPath *)indexPath isParentFile:(BOOL)isParentFile{
    
    if (isParentFile) {
        
        ParentFileInfo *parentInfo = self.parentFileList[indexPath.section];
        
        if (parentInfo.subFileList.count == 0) {
            parentInfo.fileInfo.isOpen = YES;
        } else {
            parentInfo.fileInfo.isOpen = !parentInfo.fileInfo.isOpen;
        }
        if (parentInfo.fileInfo.isOpen) {
            self.currentParentFileId = parentInfo.fileInfo.fileId;
        } else {
            self.currentParentFileId = -1;
        }
        // 处理折叠文件夹
        [self collapseFolders];
        // 一级文件展开、折叠，不选中二级文件夹
        _currentIndex = -1;
        [_tableView reloadData];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(secondSheetViewFirstLevelData:index:)]) {
            
            [self.delegate secondSheetViewFirstLevelData:parentInfo index:indexPath.section];
        }
    } else {
        
        ParentFileInfo *parentFileInfo = self.parentFileList[indexPath.section];
        FileInfo *subFileInfo = parentFileInfo.subFileList[indexPath.row];
        _currentIndex = indexPath.row;
        [self.tableView reloadData];
        // 任务管理二级文件夹
        if (self.delegate && [self.delegate respondsToSelector:@selector(secondSheetViewSecondLevelData:index:)]) {
            
            [self.delegate secondSheetViewSecondLevelData:subFileInfo index:indexPath.row];
        }
    }
}
#pragma mark - 长按编辑文件夹
- (void)headerViewEditFileClicked:(NSIndexPath *_Nullable)indexPath isParentFile:(BOOL)isParentFile{
    
    // 一级文件夹
    if (isParentFile) {
        
        MIEidtFileView *editFileView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIEidtFileView class]) owner:nil options:nil].lastObject;
        WeakifySelf;
        editFileView.deleteCallback = ^{
            ParentFileInfo *parentFileInfo = weakSelf.parentFileList[indexPath.section];
                weakSelf.currentParentFileId = -1;
            if (indexPath.section < parentFileInfo.subFileList.count) {
                [weakSelf deleteFile:parentFileInfo.fileInfo indexPath:indexPath];
            }
        };
        editFileView.renameCallBack = ^{
            ParentFileInfo *parentFileInfo = weakSelf.parentFileList[indexPath.section];
            if (indexPath.section < parentFileInfo.subFileList.count) {
                [weakSelf renameFileWithFileInfo:parentFileInfo.fileInfo];
            }
        };
        editFileView.frame = [UIScreen mainScreen].bounds;
        
        // header位置
        CGRect rectInTableView = [self.tableView rectForHeaderInSection:indexPath.section];
        CGRect rect = [self.tableView convertRect:rectInTableView toView:[self.tableView superview]];
        CGFloat editViewY = CGRectGetMidY(rect) - 70;
        
        if (editViewY >= [UIScreen mainScreen].bounds.size.height - 120) {
            editViewY = [UIScreen mainScreen].bounds.size.height - 120;
        }
        editFileView.topConstraint.constant = editViewY;
        editFileView.leftContraint.constant = kFolderModularWidth + kRootModularWidth;
        [[UIApplication sharedApplication].keyWindow addSubview:editFileView];
    } else {
        
        MIEidtFileView *editFileView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIEidtFileView class]) owner:nil options:nil].lastObject;
        WeakifySelf;
        editFileView.deleteCallback = ^{
            
            if (indexPath.section < weakSelf.parentFileList.count) {
                ParentFileInfo *parentFileInfo = weakSelf.parentFileList[indexPath.section];
                if (indexPath.row < parentFileInfo.subFileList.count) {
                    FileInfo *subInfo = parentFileInfo.subFileList[indexPath.row];
                    [weakSelf deleteFile:subInfo indexPath:indexPath];
                }
            }
        };
        editFileView.renameCallBack = ^{
           
            if (indexPath.section < weakSelf.parentFileList.count) {
                ParentFileInfo *parentFileInfo = weakSelf.parentFileList[indexPath.section];
                if (indexPath.row < parentFileInfo.subFileList.count) {
                    FileInfo *subInfo = parentFileInfo.subFileList[indexPath.row];
                    [weakSelf renameFileWithFileInfo:subInfo];
                }
            }
        };
        editFileView.frame = [UIScreen mainScreen].bounds;
        
        // header位置
        
        CGRect rectInTableView = [self.tableView rectForRowAtIndexPath:indexPath];
        CGRect rect = [self.tableView convertRect:rectInTableView toView:[self.tableView superview]];
        CGFloat editViewY = CGRectGetMidY(rect) - 70;
        
        if (editViewY >= [UIScreen mainScreen].bounds.size.height - 120) {
            editViewY = [UIScreen mainScreen].bounds.size.height - 120;
        }
        editFileView.topConstraint.constant = editViewY;
        editFileView.leftContraint.constant = kFolderModularWidth + kRootModularWidth;
        [[UIApplication sharedApplication].keyWindow addSubview:editFileView];
    }
}

#pragma mark - 新建二级文件夹
- (void)headerViewAddClicked:(NSInteger)index{
    
    MICreateFolderView *createView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MICreateFolderView class]) owner:nil options:nil] lastObject];
    WeakifySelf;
    createView.sureCallBack = ^(NSString * _Nullable name) {
        
        ParentFileInfo *parentInfo = weakSelf.parentFileList[index];
        FileInfo *fileInfo = [[FileInfo alloc] init];
        fileInfo.fileName = name;
        fileInfo.parentId = parentInfo.fileInfo.fileId;
        fileInfo.depth = 2;
        [weakSelf requestCreateFilesWithFileDto:fileInfo isEidt:NO];
    };
    createView.titleName = @"添加子文件夹";
    createView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    [[UIApplication sharedApplication].keyWindow addSubview:createView];
}

- (void)addSecondLevelFolderIndex:(NSInteger)index{
    
    [self headerViewAddClicked:index];
}

- (void)recordbtnClicked:(UIButton *)btn{
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(toSendRecord)]) {
        
        [self.delegate toSendRecord];
    }
    
}
#pragma mark -  新建一级文件夹
- (void)addFolderBtnClicked:(UIButton *)addBtn{
    
    MICreateFolderView *createView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MICreateFolderView class]) owner:nil options:nil] lastObject];
    WeakifySelf;
    createView.sureCallBack = ^(NSString * _Nullable name) {
        
        // 新建一级文件夹
        FileInfo *fileInfo = [[FileInfo alloc] init];
        fileInfo.fileName = name;
        fileInfo.depth = 1;
        [weakSelf requestCreateFilesWithFileDto:fileInfo isEidt:NO];
    };
    createView.titleName = @"添加父级文件夹";
    createView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    [[UIApplication sharedApplication].keyWindow addSubview:createView];
}

#pragma mark  展开当前文件夹,折叠其他文件
- (void)collapseFolders{
    
    // 其他文件夹折叠
    for (ParentFileInfo *otherFileInfo in self.parentFileList) {
        
        if (self.currentParentFileId != otherFileInfo.fileInfo.fileId) {
           
            otherFileInfo.fileInfo.isOpen = NO;
        } else {
            otherFileInfo.fileInfo.isOpen = YES;
        }
    }
}

#pragma mark - 删除文件夹
- (void)deleteFile:(FileInfo *)fileInfo indexPath:(NSIndexPath *)indexPath{
    
    if (fileInfo.depth == 1) {
        
        ParentFileInfo *parentInfo = self.parentFileList[indexPath.section];
        if (parentInfo.subFileList.count) {
            
            [HUD showErrorWithMessage:@"请先删除子文件夹"];
        } else {
        
            [self requestDelFilesWithFileInfo:parentInfo.fileInfo];
        }
        
    } else if (fileInfo.depth == 2) {
        // 判断是否有任务，有任务先清空任务列表
        ParentFileInfo *parentInfo = self.parentFileList[indexPath.section];
        FileInfo *subFileInfo = parentInfo.subFileList[indexPath.row];
        [self requestDelFilesWithFileInfo:subFileInfo];
    }
}

#pragma mark - 编辑文件夹
- (void)renameFileWithFileInfo:(FileInfo *)fileInfo{
    
    MICreateFolderView *createView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MICreateFolderView class]) owner:nil options:nil] lastObject];
    WeakifySelf;
    createView.sureCallBack = ^(NSString * _Nullable name) {
        
        fileInfo.fileName = name;
        [weakSelf requestCreateFilesWithFileDto:fileInfo isEidt:YES];
    };
    createView.titleName = @"编辑文件名";
    createView.fileName = fileInfo.fileName;
    createView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    [[UIApplication sharedApplication].keyWindow addSubview:createView];
}

- (void)updateFileListInfo{
    
    self.currentIndex = -1;
    self.currentParentFileId = -1;
    [self requestGetParentFilesInfo];
}

#pragma mark - 获取文件夹列表
- (void)requestGetParentFilesInfo{
    // 获取一级文件夹列表
    WeakifySelf;
    [ManagerServce requestGetFilesWithFileId:0 callback:^(Result *result, NSError *error) {
    
        if (error) return ;
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *fileInfoList = (NSArray *)(dict[@"list"]);
        [weakSelf.parentFileList removeAllObjects];
        [weakSelf.parentFileList addObjectsFromArray:fileInfoList];
        [weakSelf collapseFolders];
        [weakSelf.tableView reloadData];
    }];
}

- (void)requestCreateFilesWithFileDto:(FileInfo *)fileInfo isEidt:(BOOL)isEdit{

    if (fileInfo.fileName.length == 0) {
        [HUD showErrorWithMessage:@"文件夹名称不能为空"];
        return;
    }
    // 创建一级文件夹列表
    WeakifySelf;
    [ManagerServce requestCreateFilesWithFileDto:fileInfo callback:^(Result *result, NSError *error) {
        if (error) {
            if (isEdit) {
                [HUD showWithMessage:@"编辑失败"];
            } else {
                [HUD showWithMessage:@"创建失败"];
            }
            return ;
        } else {
           
            if (fileInfo.depth == 1) {
                if (fileInfo.isOpen) {
                    
                    weakSelf.currentParentFileId =fileInfo.fileId;
                } else {
                    weakSelf.currentParentFileId = -1;
                }
            }
            if (isEdit) {
                [HUD showWithMessage:@"编辑成功"];
            } else {
                [HUD showWithMessage:@"创建成功"];
            }
            [weakSelf requestGetParentFilesInfo];
        }
    }];
}


- (void)requestDelFilesWithFileInfo:(FileInfo *)fileInfo{
   
    WeakifySelf;
    [ManagerServce requestDelFilesWithFileId:fileInfo.fileId callback:^(Result *result, NSError *error) {
        if (error) {
            [HUD showWithMessage:@"删除失败"];
            return ;
        } else {
            [HUD showWithMessage:@"删除成功"];
            [weakSelf requestGetParentFilesInfo];
        }
    }];
}

@end