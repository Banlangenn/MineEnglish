//
//  AwardsViewController.m
//  X5
//
//  Created by yebw on 2017/8/28.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "StudentAwardsViewController.h"
#import "ExchangeRecordsViewController.h"
#import "StudentAwardCollectionViewCell.h"
#import "Award.h"
#import "ExchangeAwardView.h"
#import "StudentAwardService.h"
#import "UIView+Load.h"
#import "UIScrollView+Refresh.h"
#import "PushManager.h"

@interface StudentAwardsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, weak) IBOutlet UILabel *starCountLabel;
@property (nonatomic, weak) IBOutlet UIView *awardsCollectionContainerView;
@property (nonatomic, weak) IBOutlet UICollectionView *awardsCollectionView;

@property (nonatomic, strong) NSArray<Award *> *awards;
@property (nonatomic, strong) BaseRequest *awardsRequest;

@end

@implementation StudentAwardsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.starCountLabel.text = [NSString stringWithFormat:@"%@", @(APP.currentUser.starCount)];
    
    [self registerCellNibs];
    
    [self requestData];
}

- (void)dealloc {
    [self.awardsRequest clearCompletionBlock];
    [self.awardsRequest stop];
    self.awardsRequest = nil;
    
    NSLog(@"%s", __func__);
}

- (IBAction)recordsButtonPressed:(id)sender {
    ExchangeRecordsViewController *vc = [[ExchangeRecordsViewController alloc] initWithNibName:NSStringFromClass([ExchangeRecordsViewController class]) bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Private Methods

- (void)registerCellNibs {
    [self.awardsCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([StudentAwardCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:StudentAwardCollectionViewCellCellId];
}

- (void)requestData {
    if (self.awardsRequest != nil) {
        return;
    }
    
    self.awardsCollectionView.hidden = YES;
    [self.awardsCollectionContainerView showLoadingView];
    
    WeakifySelf;
    self.awardsRequest = [StudentAwardService requestAwardsWithCallback:^(Result *result, NSError *error) {
        StrongifySelf;
        
        strongSelf.awardsRequest = nil;
        
        // 显示失败页面
        if (error != nil) {
            [strongSelf.awardsCollectionContainerView showFailureViewWithRetryCallback:^{
                [strongSelf requestData];
            }];
            
            return;
        }
        
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *awards = (NSArray *)(dict[@"list"]);
        if (awards.count == 0) {
            [strongSelf.awardsCollectionContainerView showEmptyViewWithImage:nil
                                                                       title:@"没有可兑换的礼物"
                                                                   linkTitle:nil
                                                           linkClickCallback:nil];
        } else {
            strongSelf.awards = awards;
            
            [strongSelf.awardsCollectionContainerView hideAllStateView];
            strongSelf.awardsCollectionView.hidden = NO;
            [strongSelf.awardsCollectionView reloadData];
        }
    }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.awards.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    StudentAwardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:StudentAwardCollectionViewCellCellId
                                                                              forIndexPath:indexPath];
    Award *award = self.awards[indexPath.row];
    
    [cell setupWithAward:award];
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [StudentAwardCollectionViewCell size];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(16, 12, 16, 12);
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    Award *award = self.awards[indexPath.row];
    [ExchangeAwardView showExchangeAwardViewInView:self.navigationController.view
                                         withAward:award
                                         starCount:APP.currentUser.starCount
                                  exchangeCallback:^{
                                      [HUD showProgressWithMessage:@"正在兑换"];
                                      
                                      [StudentAwardService exchangeAwardWithId:award.awardId
                                                               callback:^(Result *result, NSError *error) {
                                                                   if (error != nil) {
                                                                       if (error.code == 703) {
                                                                           [HUD showErrorWithMessage:@"兑换失败"];
                                                                       } else {
                                                                           [HUD showErrorWithMessage:@"星星数量不够"];
                                                                       }
                                                                   } else {
                                                                       [HUD showWithMessage:@"兑换成功"];
                                                                       
                                                                       APP.currentUser.starCount -= award.price;
                                                                       
                                                                       [PushManager pushText:@"你有新的兑换订单" toUsers:@[@(APP.currentUser.clazz.teacher.userId)]];
                                                                       
                                                                       self.starCountLabel.text = [NSString stringWithFormat:@"%@", @(APP.currentUser.starCount)];
                                                                       
                                                                       [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfProfileUpdated object:nil];
                                                                       
                                                                       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                                           [self recordsButtonPressed:nil];
                                                                       });
                                                                   }
                                                               }];
                                  }];
}

@end

