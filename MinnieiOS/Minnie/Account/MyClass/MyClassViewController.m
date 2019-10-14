//
//  ClassViewController.m
//  X5
//
//  Created by yebw on 2017/9/4.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "Clazz.h"
#import "ClassService.h"
#import "MyClassViewController.h"
#import "StudentCollectionViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CircleHomeworksViewController.h"
@interface MyClassViewController ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UICollectionView *studentsCollectionView;
@property (nonatomic, strong) Clazz *Clazz;

@property (nonatomic, strong) BaseRequest *classRequest;


@end

@implementation MyClassViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerCellNibs];
    
    [self requestData];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc {
    [self.classRequest clearCompletionBlock];
    [self.classRequest stop];
    self.classRequest = nil;
    
    
}

#pragma mark - Private Methods

- (void)registerCellNibs {
    [self.studentsCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([StudentCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:StudentCollectionViewCellId];
}

- (void)requestData {
    if (self.classRequest != nil) {
        return;
    }
    
    self.studentsCollectionView.hidden = YES;
    [self.containerView showLoadingView];
    
    WeakifySelf;
    self.classRequest = [ClassService requestClassWithId:self.classId
                                                callback:^(Result *result, NSError *error) {
                                                    StrongifySelf;
                                                    strongSelf.classRequest = nil;
                                                    
                                                    if (error != nil) {
                                                        [strongSelf.containerView showFailureViewWithRetryCallback:^{
                                                            [strongSelf requestData];
                                                        }];
                                                        
                                                        return;
                                                    }
                                                    
                                                    Clazz *cls = (Clazz *)(result.userInfo);
                                                    strongSelf.customTitleLabel.text = cls.name;
                                                    if (cls.classId == 0) {
                                                        [strongSelf.containerView showFailureViewWithRetryCallback:^{
                                                            [strongSelf requestData];
                                                        }];
                                                    } else {
                                                        strongSelf.Clazz = cls;
                                                    
                                                        [strongSelf.containerView hideAllStateView];
                                                        strongSelf.studentsCollectionView.hidden = NO;
                                                        [strongSelf.studentsCollectionView reloadData];
                                                    }
                                                }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.Clazz.students.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    StudentCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:StudentCollectionViewCellId forIndexPath:indexPath];
    
    User *user = self.Clazz.students[indexPath.row];
    
    [cell setupWithUser:user];

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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    User *user = self.Clazz.students[indexPath.row];
    
    CircleHomeworksViewController *circleVC = [[CircleHomeworksViewController alloc] initWithNibName:@"CircleHomeworksViewController" bundle:nil];
    circleVC.userId = user.userId;
    circleVC.userName = user.nickname;
    [self.navigationController pushViewController:circleVC animated:YES];
}

@end

