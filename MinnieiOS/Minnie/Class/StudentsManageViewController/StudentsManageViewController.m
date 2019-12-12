//
//  ClassViewController.m
//  X5
//
//  Created by yebw on 2017/9/4.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "StudentsManageViewController.h"
#import "StudentCollectionViewCell.h"
#import "ClassService.h"
#import "StudentService.h"
#import "Clazz.h"
#import "AddStudentView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "StudentsWithoutClassViewController.h"
#import "PortraitNavigationController.h"
#import "PushManager.h"

@interface StudentsManageViewController()<UICollectionViewDataSource, UICollectionViewDelegate, StudentsWithoutClassViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UICollectionView *studentsCollectionView;

@property (nonatomic, weak) IBOutlet UIButton *deleteButton;
@property (nonatomic, weak) IBOutlet UIButton *backButton;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *operationsBottomConstraint;

@property (nonatomic, assign) BOOL inDeleteMode;

@property (nonatomic, strong) NSMutableArray *studentsToDelete;

@end

@implementation StudentsManageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _studentsToDelete = [NSMutableArray array];
    
    self.closeButton.hidden = YES;
    self.backButton.hidden = NO;
    self.deleteButton.hidden = YES;
    
    self.customTitleLabel.text = self.clazz.name;
    
    [self registerCellNibs];
    
    if (self.clazz.students.count == 0) {
        [self.containerView showEmptyViewWithImage:nil
                                             title:@"暂无学员"
                                         linkTitle:nil
                                 linkClickCallback:nil];
    }
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - IBAction Methods

- (IBAction)addButtonPressed:(id)sender {
    StudentsWithoutClassViewController *studentsVC = [[StudentsWithoutClassViewController alloc] init];
    
    studentsVC.delegate = self;
    
#if MANAGERSIDE
    [self.navigationController pushViewController:studentsVC animated:YES];
#else
    
    PortraitNavigationController *nc = [[PortraitNavigationController alloc] initWithRootViewController:studentsVC];
    [nc setNavigationBarHidden:YES];

    nc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:nc
                                            animated:YES
                                          completion:^{
                                          }];
#endif
}

- (IBAction)closeButtonPressed:(id)sender {
    // 修改名称
    self.customTitleLabel.text = self.clazz.name;
    
    // 修改左上角按钮，改为叉
    self.backButton.hidden = NO;
    self.closeButton.hidden = YES;
    
    // 右上角添加删除按钮
    self.deleteButton.hidden = YES;
    
    // 修改头像样式
    self.inDeleteMode = NO;
    [self.studentsCollectionView reloadData];
    
    self.operationsBottomConstraint.constant = 0.f;
}

- (IBAction)deleteButtonPressed:(id)sender {
    // 修改名称
    self.customTitleLabel.text = @"移除学员";
    
    // 修改左上角按钮，改为叉
    self.backButton.hidden = YES;
    self.closeButton.hidden = NO;
    
    // 右上角添加删除按钮
    self.deleteButton.hidden = NO;
    
    // 修改头像样式，添加删除按钮
    
    // 添加删除按
    self.inDeleteMode = YES;
    [self.studentsCollectionView reloadData];
    
    self.operationsBottomConstraint.constant = -50.f - (isIPhoneX?34.f:0);
}

// 右上角的删除按钮
- (IBAction)deleteStudentsButtonPressed:(id)sender {
    if (self.studentsToDelete.count == 0) {
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认删除这些学员"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"删除"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [HUD showProgressWithMessage:@"正在删除"];
                                                              
                                                              NSMutableArray *studentIdsToDelete = [NSMutableArray array];
                                                              for (User *student in self.studentsToDelete) {
                                                                  [studentIdsToDelete addObject:@(student.userId)];
                                                              }
                                                              
                                                              [ClassService deleteClassStudentsWithClassId:self.clazz.classId
                                                                                                studentIds:studentIdsToDelete
                                                                                                  callback:^(Result *result, NSError *error) {
                                                                                                      [self handleDeleteResult:result error:error];
                                                                                                  }];
                                                          }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];

    alertController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - StudentsWithoutClassViewControllerDelegate

- (void)studentsDidSelect:(NSArray<User *> *)students {
    NSMutableArray *ids = [NSMutableArray array];
    for (User *user in students) {
        [ids addObject:@(user.userId)];
    }
    
    if (self.clazz.classId > 0) {
        [HUD showProgressWithMessage:@"正在添加学生"];
        
        [ClassService addClassStudentWithClassId:self.clazz.classId
                                      studentIds:ids
                                        callback:^(Result *result, NSError *error) {
                                            if (error != nil) {
                                                [HUD showErrorWithMessage:@"添加失败"];
                                                
                                                return ;
                                            }
                                            
                                            if (ids.count > 0) {
                                                [PushManager pushText:@"欢迎，你已加入MINNIE英语" toUsers:ids];
                                            }
                                            
                                            [HUD hideAnimated:NO];
                                            NSMutableArray *stds = [NSMutableArray arrayWithArray:students];
                                            if (self.clazz.students.count > 0) {
                                                [stds addObjectsFromArray:self.clazz.students];
                                            }
                                            self.clazz.students = stds;
                                            
                                            [self.containerView hideAllStateView];
                                            self.studentsCollectionView.hidden = NO;
                                            [self.studentsCollectionView reloadData];
                                            
                                            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfAddClassStudents object:nil];
                                        }];
    } else {
        NSMutableArray *stds = [NSMutableArray arrayWithArray:students];
        if (self.clazz.students.count > 0) {
            [stds addObjectsFromArray:self.clazz.students];
        }
        self.clazz.students = stds;
        
        [self.containerView hideAllStateView];
        self.studentsCollectionView.hidden = NO;
        [self.studentsCollectionView reloadData];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfAddClassStudents object:nil];
    }
}

#pragma mark - Private Methods

- (void)registerCellNibs {
    [self.studentsCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([StudentCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:StudentCollectionViewCellId];
}

- (void)handleDeleteResult:(Result *)result error:(NSError *)error {
    if (error != nil) {
        [HUD showErrorWithMessage:@"删除学员失败"];
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfDeleteClassStudents object:nil];
    
    [HUD showWithMessage:@"删除学员成功"];
    
    NSMutableArray *students = [NSMutableArray arrayWithArray:self.clazz.students];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (User *student in self.studentsToDelete) {
        NSInteger index = [self.clazz.students indexOfObject:student];
        [indexes addIndex:index];
    }
    [students removeObjectsAtIndexes:indexes];
    self.clazz.students = students;
    
    [self.studentsToDelete removeAllObjects];
    
    if (students.count == 0) {
        [self.containerView showEmptyViewWithImage:nil
                                             title:@"暂无学员"
                                         linkTitle:nil
                                 linkClickCallback:nil];
        self.studentsCollectionView.hidden = YES;
    }
    
    [self.studentsCollectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.clazz.students.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    StudentCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:StudentCollectionViewCellId forIndexPath:indexPath];
    
    User *user = self.clazz.students[indexPath.row];
    
    [cell setupWithUser:user];
    
    BOOL selected = [self.studentsToDelete containsObject:user];
    [cell updateWithDeleteMode:self.inDeleteMode selected:selected];
    
    WeakifySelf;
    cell.deleteCallback = ^(NSUInteger userId, BOOL selected) {
        BOOL s = YES;
        if ([weakSelf.studentsToDelete containsObject:user]) {
            [weakSelf.studentsToDelete removeObject:user];
            s = NO;
        } else {
            [weakSelf.studentsToDelete addObject:user];
        }
        
        StudentCollectionViewCell *cell = (StudentCollectionViewCell *)[weakSelf.studentsCollectionView cellForItemAtIndexPath:indexPath];
        [cell updateWithDeleteMode:weakSelf.inDeleteMode selected:s];
    };
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [StudentCollectionViewCell size];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(20, 20, 20, 20);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 26;
}

@end


