//
//  ExchangeRecordsViewController.m
//  X5
//
//  Created by yebw on 2017/9/4.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "ExchangeRecordsViewController.h"
#import "ExchangeRecordTableViewCell.h"
#import "AwardsService.h"
#import "Constants.h"

@interface ExchangeRecordsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UITableView *recordsTableView;
@property (nonatomic, strong) NSArray <ExchangeRecord *> *records;

@property (nonatomic, strong) BaseRequest *recordsRequest;

@end

@implementation ExchangeRecordsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self registerCellNibs];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"my_exchange_banner"]];
    imageView.clipsToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.frame = CGRectMake(0, 0, ScreenWidth, ScreenWidth * 110.f / 375.f);
    self.recordsTableView.tableHeaderView = imageView;
    
    [self requestData];
}

- (void)dealloc {
    [self.recordsRequest clearCompletionBlock];
    [self.recordsRequest stop];
    self.recordsRequest = nil;
    
    
}

#pragma mark - Private Method

- (void)registerCellNibs {
    [self.recordsTableView registerNib:[UINib nibWithNibName:@"ExchangeRecordTableViewCell" bundle:nil] forCellReuseIdentifier:ExchangeRecordTableViewCellId];
}

- (void)requestData {
    if (self.recordsRequest != nil) {
        return;
    }
    
    self.recordsTableView.hidden = YES;
    [self.containerView showLoadingView];
    
    WeakifySelf;
    self.recordsRequest = [AwardsService requestExchangeRecordsWithCallback:^(Result *result, NSError *error) {
        StrongifySelf;
        
        strongSelf.recordsRequest = nil;
        
        if (error != nil) {
            [strongSelf.containerView showFailureViewWithRetryCallback:^{
                [strongSelf requestData];
            }];
        } else {
            NSDictionary *dict = (NSDictionary *)(result.userInfo);
            strongSelf.records = (NSArray *)(dict[@"list"]);
            
            if (strongSelf.records.count == 0) {
                [strongSelf.containerView showEmptyViewWithImage:nil
                                                           title:@"暂无兑换记录"
                                                       linkTitle:nil
                                               linkClickCallback:nil];
            } else {
                [strongSelf.containerView hideAllStateView];
                
                strongSelf.recordsTableView.hidden = NO;
                [strongSelf.recordsTableView reloadData];
            }
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.records.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExchangeRecordTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ExchangeRecordTableViewCellId forIndexPath:indexPath];
    
    ExchangeRecord *exchangeRecord = self.records[indexPath.row];
    [cell setupWithExchangeRecord:exchangeRecord];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ExchangeRecordTableViewCellHeight;
}

@end

