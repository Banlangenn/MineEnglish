//
//  HeaderTableViewCell.m
//  Manager
//
//  Created by songzhen on 2019/5/27.
//  Copyright © 2019 songzhen. All rights reserved.
//

#import "MIEidtFileView.h"
#import "ParentFileInfo.h"
#import "MIHeaderTableViewCell.h"


NSString * const MIHeaderTableViewCellId = @"MIHeaderTableViewCellId";
CGFloat const MIHeaderTableViewCellHeight = 60.f;

@interface MIHeaderTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (weak, nonatomic) IBOutlet UIView *rightLineView;


@property (nonatomic , strong) NSIndexPath *indexPath;

@property (nonatomic , strong) ParentFileInfo *parentFileInfo;

@property (nonatomic , assign) BOOL isSelected;

@property (nonatomic , assign) NSInteger isParentFile;


@end

@implementation MIHeaderTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self addGestureRecognizer:tap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [self addGestureRecognizer:longPress];
}

- (void)tapAction:(UITapGestureRecognizer *)tap
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerViewDidCellClicked:isParentFile:)]) {
        [self.delegate headerViewDidCellClicked:self.indexPath isParentFile:self.isParentFile];
    }
}

- (void)longPressAction:(UILongPressGestureRecognizer *)pressGest
{
    if (pressGest.state == UIGestureRecognizerStateBegan) {
        
        if (self.isParentFile) {
            // 父级文件夹，展开，情况下，长按编辑
            if (self.parentFileInfo.fileInfo.isOpen) {
               
                if (self.delegate && [self.delegate respondsToSelector:@selector(headerViewEditFileClicked:isParentFile:)]) {
                    [self.delegate headerViewEditFileClicked:self.indexPath isParentFile:self.isParentFile];
                }
            } else {
                // 点击文件
                if (self.delegate && [self.delegate respondsToSelector:@selector(headerViewDidCellClicked:isParentFile:)]) {
                    [self.delegate headerViewDidCellClicked:self.indexPath isParentFile:self.isParentFile];
                }
            }
        } else {
            // 子级文件夹，选中，情况下，长按编辑
            if (self.isSelected) {
              
                if (self.delegate && [self.delegate respondsToSelector:@selector(headerViewEditFileClicked:isParentFile:)]) {
                    [self.delegate headerViewEditFileClicked:self.indexPath isParentFile:self.isParentFile];
                }
            } else {
                // 点击文件
                if (self.delegate && [self.delegate respondsToSelector:@selector(headerViewDidCellClicked:isParentFile:)]) {
                    [self.delegate headerViewDidCellClicked:self.indexPath isParentFile:self.isParentFile];
                }
            }
        }
     
    }
}

- (IBAction)addBtnClicked:(id)sender {
  
    if (self.isParentFile) {
       
        if (self.delegate && [self.delegate respondsToSelector:@selector(headerViewAddClicked:)]) {
            [self.delegate headerViewAddClicked:self.indexPath.section];
        }
    }
}

- (void)setupFilesWithFileInfo:(id)fileInfo indexPath:(NSIndexPath *)indexPath isParentFile:(NSInteger)isParentFile selected:(BOOL)selected{
    
    self.rightLineView.hidden = YES;
    self.indexPath = indexPath;
    self.isParentFile = isParentFile;
    self.backgroundColor = [UIColor whiteColor];
    if (isParentFile) {
        if (![fileInfo isKindOfClass:[ParentFileInfo class]]) return;
        ParentFileInfo *parentFileInfo = fileInfo;
        self.parentFileInfo = parentFileInfo;
        if (parentFileInfo.fileInfo.isOpen) {
            self.titleLabel.textColor = [UIColor mainColor];
            [self.addBtn setImage:[UIImage imageNamed:@"ic_add_blue"] forState:UIControlStateNormal];
        } else {
            self.titleLabel.textColor = [UIColor normalColor];
            [self.addBtn setImage:[UIImage imageNamed:@"ic_add_black"] forState:UIControlStateNormal];
        }
        if (parentFileInfo.subFileList.count == 0) {
            self.addBtn.hidden = YES;
        } else {
            self.addBtn.hidden = NO;
        }
        self.addBtn.enabled = YES;
        [self.addBtn setTitle:@"" forState:UIControlStateNormal];
        self.titleLabel.text = parentFileInfo.fileInfo.fileName;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    } else {
        if (![fileInfo isKindOfClass:[FileInfo class]]) return;
        FileInfo *subFileInfo = fileInfo;
        self.isSelected = selected;
        self.addBtn.enabled = NO;
        [self.addBtn setTitle:[NSString stringWithFormat:@"%lu",subFileInfo.homeworkNum] forState:UIControlStateNormal];
        [self.addBtn setImage:[UIImage imageNamed:@" "] forState:UIControlStateNormal];
        if (selected) {
            self.titleLabel.textColor = [UIColor mainColor];
            self.backgroundColor = [UIColor selectedColor];
            self.rightLineView.hidden = NO;
        } else {
            self.titleLabel.textColor = [UIColor detailColor];
        }
        self.titleLabel.font = [UIFont systemFontOfSize:14];
        self.titleLabel.text = [NSString stringWithFormat:@"    %@",subFileInfo.fileName];
    }
}

- (ParentFileInfo *)parentFileInfo{
    
    if (!_parentFileInfo) {
        
        _parentFileInfo = [[ParentFileInfo alloc] init];
    }
    return _parentFileInfo;
}

@end
