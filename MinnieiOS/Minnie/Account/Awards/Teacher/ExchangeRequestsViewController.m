//
//  ExchangeRequestsViewController.m
//  X5
//
//  Created by yebw on 2017/9/4.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "ExchangeRequestsViewController.h"
#import "ExchangeRequestTableViewCell.h"
#import "AwardsService.h"
#import "Constants.h"
#import "UIScrollView+Refresh.h"
#import "TeacherAwardsViewController.h"
#import "UIColor+HEX.h"
#import "PinyinHelper.h"
#import "HanyuPinyinOutputFormat.h"

@interface ExchangeRequestsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UITableView *requestsTableView;
@property (nonatomic, weak) IBOutlet UIButton *manageButton;
@property (weak, nonatomic) IBOutlet UIButton *recordHistoryBtn;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (nonatomic, strong) BaseRequest *listRequest;

@property (nonatomic, strong) NSMutableArray <ExchangeRecord *> *requests;

@property (nonatomic, strong) NSMutableArray <ExchangeAwardListRecord *> *awardListByClass;

@property (nonatomic, copy) NSString *nextUrl;

@end

@implementation ExchangeRequestsViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _requests = [NSMutableArray array];
    _awardListByClass = [NSMutableArray array];
    [self configureUI];
    [self registerCellNibs];
    if (self.isAwardListByClass) {

        WeakifySelf;
        [self.requestsTableView addPullToRefreshWithRefreshingBlock:^{
            [weakSelf requestAwardListByClass];
        }];
        [self requestAwardListByClass];
    } else {
        [self requestData];
    }
}

- (void)configureUI{
    
    if (self.isAwardListByClass) {
        self.exchanged = NO;
        self.customTitleLabel.text = @"";
        self.manageButton.hidden = YES;
        self.recordHistoryBtn.hidden = YES;
        self.backButton.enabled = NO;
        [self.backButton setTitle:@"兑换列表" forState:UIControlStateNormal];
        [self.backButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
    } else {
        
        [self.backButton setTitle:@"" forState:UIControlStateNormal];
        [self.backButton setImage:[UIImage imageNamed:@"navbar_back"] forState:UIControlStateNormal];
        
        if (self.exchanged) {
            [self.customTitleLabel setText:@"兑换历史"];
            self.manageButton.hidden = YES;
            
            self.recordHistoryBtn.hidden = YES;
            
        } else {
            [self.customTitleLabel setText:@"星兑换"];
            self.manageButton.hidden = NO;
            
            self.recordHistoryBtn.hidden = NO;
        }
    }
}

- (IBAction)recordHistoryClick:(UIButton *)sender {
    ExchangeRequestsViewController *vc = [[ExchangeRequestsViewController alloc] initWithNibName:@"ExchangeRequestsViewController" bundle:nil];
    
    vc.exchanged = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)dealloc {
    [self.listRequest clearCompletionBlock];
    [self.listRequest stop];
    self.listRequest = nil;
    
    
}

- (IBAction)manageButtonPressed:(id)sender {
    TeacherAwardsViewController *vc = [[TeacherAwardsViewController alloc] initWithNibName:@"TeacherAwardsViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Private Method

- (void)registerCellNibs {
    [self.requestsTableView registerNib:[UINib nibWithNibName:@"ExchangeRequestTableViewCell" bundle:nil]
                 forCellReuseIdentifier:ExchangeRequestTableViewCellId];
}

#pragma mark - 获取兑换列表 (学生端、教师端)
- (void)requestData {
    if (self.listRequest != nil) {
        return;
    }
    
    self.requestsTableView.hidden = YES;
    [self.containerView showLoadingView];

    WeakifySelf;
    self.listRequest = [AwardsService requestExchangeRequestsWithState:self.exchanged
                                                             callback:^(Result *result, NSError *error) {
                                                                 StrongifySelf;
                                                                 
                                                                 [strongSelf handleRequestResult:result error:error];
                                                             }];
}

- (void)loadMore {
    if (self.listRequest != nil) {
        return;
    }
    
    WeakifySelf;
    self.listRequest = [AwardsService requestExchangeRequestsWithMoreUrl:self.nextUrl
                                                               callback:^(Result *result, NSError *error) {
                                                                   StrongifySelf;
                                                                   
                                                                   [strongSelf handleRequestResult:result error:error];
                                                               }];
}

- (void)handleRequestResult:(Result *)result error:(NSError *)error {
    self.listRequest = nil;
    
    [self.containerView hideAllStateView];
    
    NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
    NSString *nextUrl = dictionary[@"next"];
    NSArray *records = dictionary[@"list"];

    BOOL isLoadMore = self.nextUrl.length > 0;
    if (isLoadMore) {
        [self.requestsTableView footerEndRefreshing];
        self.requestsTableView.hidden = NO;

        if (error != nil) {
            return;
        }
        
        if (records.count > 0) {
            [self.requests addObjectsFromArray:records];
        }
        
        if (nextUrl.length == 0) {
            [self.requestsTableView removeFooter];
        }
        
        [self.requestsTableView reloadData];
    } else {
        // 停止加载
        [self.requestsTableView headerEndRefreshing];
        self.requestsTableView.hidden = records.count==0;
        
        if (error != nil) {
            if (records.count > 0) {
                [TIP showText:@"加载失败" inView:self.view];
            } else {
                WeakifySelf;
                [self.containerView showFailureViewWithRetryCallback:^{
                    [weakSelf requestData];
                }];
            }
            
            return;
        }
        
        if (records.count > 0) {
            self.requestsTableView.hidden = NO;
            
            [self.requests addObjectsFromArray:records];
            [self.requestsTableView reloadData];
            
            if (nextUrl.length > 0) {
                WeakifySelf;
                [self.requestsTableView addInfiniteScrollingWithRefreshingBlock:^{
                    [weakSelf loadMore];
                }];
            } else {
                [self.requestsTableView removeFooter];
            }
        } else {
            if (!self.exchanged) {
                [self.containerView showEmptyViewWithImage:nil
                                                     title:@"暂无兑换信息"
                                             centerYOffset:-20
                                                 linkTitle:@"兑换历史"
                                         linkClickCallback:^{
                                             [self recordHistoryClick:nil];
                                         }];
            } else {
                [self.containerView showEmptyViewWithImage:nil
                                                     title:@"暂无兑换信息"
                                             centerYOffset:-20
                                                 linkTitle:nil
                                         linkClickCallback:nil];
            }
        }
    }
    
    self.nextUrl = nextUrl;
}

#pragma mark - 获取兑换列表（管理端）
- (void)requestAwardListByClass {
    
    WeakifySelf;
    self.nextUrl = nil;
    [AwardsService requestexchangeAwardByClassWithState:0
                                                nextUrl:nil
                                               callback:^(Result *result, NSError *error) {
                                                         
                                                         [weakSelf.requestsTableView headerEndRefreshing];
                                                         StrongifySelf;
                                                         [strongSelf handleRequestByClassResult:result error:error];
    }];
}
- (void)loadMoreAwardListByClass {
    
    WeakifySelf;
    [AwardsService requestexchangeAwardByClassWithState:0
                                                nextUrl:self.nextUrl
                                               callback:^(Result *result, NSError *error) {
                                                         
                                                         [weakSelf.requestsTableView headerEndRefreshing];
                                                         StrongifySelf;
                                                         [strongSelf handleRequestByClassResult:result error:error];
    }];
}

- (void)handleRequestByClassResult:(Result *)result error:(NSError *)error {
    
    [self.containerView hideAllStateView];
    NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
    NSString *nextUrl = dictionary[@"next"];
    NSArray *records = dictionary[@"list"];
    
  
    BOOL isLoadMore = self.nextUrl.length > 0;
    if (isLoadMore) {
        
        [self.requestsTableView footerEndRefreshing];
        self.requestsTableView.hidden = NO;

        if (error != nil) {
            return;
        }
        
        if (records.count > 0) {
            [self.awardListByClass addObjectsFromArray:records];
            [self sortAwardsByClass];
        }
        
        if (nextUrl.length == 0) {
            [self.requestsTableView removeFooter];
        }
        
        [self.requestsTableView reloadData];
    } else {

      [self.requestsTableView footerEndRefreshing];
        WeakifySelf;
         if (error != nil) {
             [self.containerView showFailureViewWithRetryCallback:^{
                 [weakSelf requestAwardListByClass];
             }];
             return;
         }
        if (records.count > 0) {
            
            self.requestsTableView.hidden = NO;
            [self.awardListByClass removeAllObjects];
            [self.awardListByClass addObjectsFromArray:records];
            [self sortAwardsByClass];
            
            if (nextUrl.length > 0) {
                WeakifySelf;
                [self.requestsTableView addInfiniteScrollingWithRefreshingBlock:^{
                    [weakSelf loadMoreAwardListByClass];
                }];
            } else {
                [self.requestsTableView removeFooter];
            }
        } else {
            if (self.awardListByClass.count == 0) {

                [self.containerView showEmptyViewWithImage:nil
                                                     title:@"暂无兑换信息"
                                             centerYOffset:-20
                                                 linkTitle:nil
                                         linkClickCallback:nil retryCallback:^{
                                             [weakSelf requestAwardListByClass];
                }];
            }
        }
    }

    self.nextUrl = nextUrl;
}
- (void)sortAwardsByClass {
    
    HanyuPinyinOutputFormat *outputFormat=[[HanyuPinyinOutputFormat alloc] init];
    [outputFormat setToneType:ToneTypeWithoutTone];
    [outputFormat setVCharType:VCharTypeWithV];
    [outputFormat setCaseType:CaseTypeUppercase];
    [self.awardListByClass enumerateObjectsUsingBlock:^(ExchangeAwardListRecord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *pinyin = [[PinyinHelper toHanyuPinyinStringWithNSString:obj.className withHanyuPinyinOutputFormat:outputFormat withNSString:@" "] uppercaseString];
        obj.pinyinName = pinyin;
    }];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pinyinName" ascending:YES];
    NSArray *array = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [self.awardListByClass sortUsingDescriptors:array];
    [self.requestsTableView reloadData];
}

#pragma mark - 兑换操作
- (void)giveAwardWithRequestId:(NSInteger)exchangeId {
    
#if TEACHERSIDE
    if (!APP.currentUser.canExchangeRewards) {
        [HUD showErrorWithMessage:@"无操作权限"];
        return;
    }
#endif
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认兑换"
                                                                             message:@"请将礼物交给兑换的小朋友后确认"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                             
                                                              [HUD showProgressWithMessage:@"正在兑换"];
                                                              [AwardsService giveAwardWithId:exchangeId
                                                                                   callback:^(Result *result, NSError *error) {
                                                                                      
                                                                                       if (error != nil) {
                                                                                           [HUD showErrorWithMessage:@"兑换失败"];
                                                                                           return;
                                                                                       }
                                                                                       [HUD showWithMessage:@"兑换成功"];
                                                                                       
                                                                                       if (self.isAwardListByClass) {
                                                                                           [self requestAwardListByClass];
                                                                                       } else {
                                                                                           [self.requests removeAllObjects];
                                                                                           self.nextUrl = nil;
                                                                                           [self requestData];
                                                                                       }
                                                                                   }];
                                                          }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];

    alertController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource && UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
   
    if (self.isAwardListByClass) {
        
        return self.awardListByClass.count;
    } else {
        
        return 1;
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
    if (self.isAwardListByClass) {
        
        ExchangeAwardListRecord *exchangeRequest = self.awardListByClass[section];
        return exchangeRequest.awardList.count;
    } else {
       
        return self.requests.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    ExchangeRequestTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ExchangeRequestTableViewCellId forIndexPath:indexPath];

    if (self.isAwardListByClass) {
        
        ExchangeAwardListRecord *exchangeRequest = self.awardListByClass[indexPath.section];
        ExchangeAwardInfo *changeInfo = exchangeRequest.awardList[indexPath.row];
        WeakifySelf;
        cell.exchangeCallback = ^{
            [weakSelf giveAwardWithRequestId:changeInfo.awardId];
        };
        [cell setupWithExchangeByClassRequest:changeInfo];
    } else {
     
        ExchangeRecord *exchangeRequest = self.requests[indexPath.row];
        exchangeRequest.state = self.exchanged?1:0;
        WeakifySelf;
        cell.exchangeCallback = ^{
            [weakSelf giveAwardWithRequestId:exchangeRequest.exchangeRequestId];
        };
        [cell setupWithExchangeRequest:exchangeRequest];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ExchangeRequestTableViewCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if (self.isAwardListByClass) {
        
        UIView *headerView =  [[UIView alloc] init];
        headerView.backgroundColor = [UIColor unSelectedColor];
        
        // 列表宽度
        CGFloat width = (ScreenWidth - kRootModularWidth)/2.0 - 80;
        
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, width - 30 - 50 ,30)];
        timeLabel.textAlignment = NSTextAlignmentLeft;
        timeLabel.font = [UIFont boldSystemFontOfSize:14];
        timeLabel.textColor = [UIColor normalColor];
        [headerView addSubview:timeLabel];
        
        
        UILabel *campusLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 15 - 50 , 0, 50,30)];
        campusLabel.textAlignment = NSTextAlignmentRight;
        campusLabel.font = [UIFont boldSystemFontOfSize:14];
        campusLabel.textColor = [UIColor normalColor];
        [headerView addSubview:campusLabel];
        
        ExchangeAwardListRecord *exchangeRequest = self.awardListByClass[section];
        timeLabel.text = exchangeRequest.className;
        campusLabel.text = exchangeRequest.campus;
        
        return headerView;
    } else {
        return nil;
    }
}

@end

