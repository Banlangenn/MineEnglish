//
//  AchieverListViewController.m
//  Minnie
//
//  Created by 栋栋 施 on 2018/11/5.
//  Copyright © 2018年 minnieedu. All rights reserved.
//

#import "AchieverListViewController.h"
#import "AchieverListCollectionViewCell.h"
#import "AchieverListHeaderView.h"
#import "AchieverService.h"
#import "AlertView.h"
@interface AchieverListViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *mCollectionView;
@property (nonatomic, strong)NSMutableArray * achieverLists;
@property (nonatomic, strong)NSMutableArray * achieverListPics;
@property (nonatomic, strong) BaseRequest * achieverRequest;
@end

@implementation AchieverListViewController

- (void)dealloc {
    
    [self.achieverRequest clearCompletionBlock];
    [self.achieverRequest stop];
    self.achieverRequest = nil;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _achieverLists = [NSMutableArray array];
    _achieverListPics = [NSMutableArray array];
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize = CGSizeMake(80, 120);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
  //  layout.minimumLineSpacing = 15;
    layout.minimumInteritemSpacing = (ScreenWidth - 240 - 60) / 2;
    layout.sectionInset = UIEdgeInsetsMake(10, 30, 10, 30);
    layout.headerReferenceSize =  CGSizeMake(ScreenWidth, 40);
    self.mCollectionView.collectionViewLayout = layout;
    
    [self registerCellNib];
    
    [self requestAchievrList];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - private
- (IBAction)backPress:(UIButton *)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)requestAchievrList
{
    if (self.achieverRequest != nil) {
        return;
    }
    
    if (self.achieverLists.count == 0) {
        [self.view showLoadingView];
        self.mCollectionView.hidden = YES;
    }
    WeakifySelf;
    self.achieverRequest = [AchieverService requestMedalDetailWithCallback:^(Result *result, NSError *error) {
        StrongifySelf;
        [strongSelf handleRequestResult:result error:error];
    }];
}

- (void)handleRequestResult:(Result *)result error:(NSError *)error
{
    
    [self.achieverRequest clearCompletionBlock];
    self.achieverRequest = nil;
    
    [self.view hideAllStateView];
    
    WeakifySelf;
    if (error != nil) {
        [self.view showFailureViewWithRetryCallback:^{
            [weakSelf requestAchievrList];
        }];
        return;
    }
    
    UserMedalDto *medalDto = (UserMedalDto *)(result.userInfo);
    NSArray * achievers = medalDto.medalDetails;
    NSArray * achieverpics = medalDto.medalPics;
    self.mCollectionView.hidden = NO;
    [self.achieverLists removeAllObjects];
    [self.achieverLists addObjectsFromArray:achievers];
    [self.achieverListPics removeAllObjects];
    [self.achieverListPics addObjectsFromArray:achieverpics];
    [self.mCollectionView reloadData];
}

- (void)registerCellNib
{
    [self.mCollectionView registerNib:[UINib nibWithNibName:@"AchieverListCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:AchieverListCollectionViewCellId];
    
    [self.mCollectionView registerNib:[UINib nibWithNibName:@"AchieverListHeaderView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:AchieverListCollectionHeaderViewId];
    
}

- (void)showAlertMedalInfo:(UserMedalDetail *)data withPic:(UserMedalPics *)pics atIndex:(NSInteger)index
{
    NSString * picURL;
    NSInteger starCount = 0;
    
    switch (index) {
        case 0:
            picURL = pics.firstPicB;
            data.firstFlag = 2;
            starCount = 5;
            break;
        case 1:
            picURL = pics.secondPicB;
            data.sencondFlag = 2;
            starCount = 10;
            break;
        case 2:
            picURL = pics.thirdPicB;
            data.thirdFlag = 2;
            starCount = 20;
            break;
    }
    WeakifySelf;
    [AlertView showInView:self.view
             withImageURL:picURL
                    title:[NSString stringWithFormat:@"%@勋章已达成",data.medalType]
                  message:[NSString stringWithFormat:@"奖励%zd颗星星",starCount]
                   action:@"确定"
           actionCallback:^{
               [weakSelf receiveMedalForData:data atMedalIndex:index withStartCount:starCount];
           }];
}

- (void)receiveMedalForData:(UserMedalDetail *)data atMedalIndex:(NSInteger)index withStartCount:(NSInteger)count
{
    WeakifySelf;
    [AchieverService updateMedalWithMedalData:data atMedalIndex:index+1 callback:^(Result *result, NSError *error) {
        if (error == nil)
        {
            [weakSelf requestAchievrList];
            //更新小星星
            APP.currentUser.starCount += count;
            
//            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfUpdateStar object:nil];
        }
    }];
}

#pragma mark - CollectionDelegete && Datasource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.achieverLists.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 3;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AchieverListCollectionViewCell * cell = (AchieverListCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:AchieverListCollectionViewCellId forIndexPath:indexPath];
    
    UserMedalDetail * detail = [self.achieverLists objectAtIndex:indexPath.section];
    UserMedalPics * pics = [self.achieverListPics objectAtIndex:indexPath.section];
    [cell setMedalData:detail forMedalPics:pics atIndex:indexPath.item];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    AchieverListHeaderView * headerView = (AchieverListHeaderView *)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:AchieverListCollectionHeaderViewId forIndexPath:indexPath];
    
    UserMedalDetail * detail = [self.achieverLists objectAtIndex:indexPath.section];
    headerView.nameLabel.text = detail.medalType;
    return headerView;
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    UserMedalDetail * detail = [self.achieverLists objectAtIndex:indexPath.section];
    UserMedalPics * pics = [self.achieverListPics objectAtIndex:indexPath.section];
    switch (indexPath.item) {
        case 0:
            if (detail.firstFlag == 1)
            {
                [self showAlertMedalInfo:detail withPic:pics atIndex:indexPath.item];
            }
            break;
        case 1:
            if (detail.sencondFlag == 1)
            {
                [self showAlertMedalInfo:detail withPic:pics atIndex:indexPath.item];
            }
            break;
        case 2:
            if (detail.thirdFlag == 1)
            {
                [self showAlertMedalInfo:detail withPic:pics atIndex:indexPath.item];
            }
            break;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
