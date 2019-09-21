//
//  NoticeMessagesViewController.m
//  X5
//
//  Created by yebw on 2017/9/12.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "NoticeMessagesViewController.h"
#import "NoticeMessageTableViewCell.h"
#import "MessageService.h"
#import "UIColor+HEX.h"
#import "UIScrollView+Refresh.h"
#import "NoticeMessageDetailViewController.h"


@interface NoticeMessagesViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *messagesTableView;

@property (nonatomic, strong) NSMutableArray<NoticeMessage *> *messages;
@property (nonatomic, copy) NSString *nextUrl;

@property (nonatomic, strong) BaseRequest *messagesRequest;

@end

@implementation NoticeMessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 11.0, *)) {
        self.messagesTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    self.view.backgroundColor = [UIColor colorWithHex:0xF5F5F5];
    
    self.messages = [NSMutableArray array];
    
    [self registerCellNibs];
    
    [self requestMessages];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestMessages)
                                                 name:kNotificationKeyOfSendNoticeMessage
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.messagesRequest clearCompletionBlock];
    [self.messagesRequest stop];
    self.messagesRequest = nil;
    
    NSLog(@"%s", __func__);
}

#pragma mark - Private Methods

- (void)registerCellNibs {
    [self.messagesTableView registerNib:[UINib nibWithNibName:@"NoticeMessageTableViewCell" bundle:nil] forCellReuseIdentifier:NoticeMessageTableViewCellId];
}

- (void)requestMessages {
    if (self.messagesRequest != nil) {
        return;
    }
    
    [self.messages removeAllObjects];
    self.nextUrl = nil;

    [self.messagesTableView reloadData];
    
    self.messagesTableView.hidden = YES;
    [self.view showLoadingView];
    
    WeakifySelf;
    self.messagesRequest = [MessageService requestNoticeMessagesWithCallback:^(Result *result, NSError *error) {
        StrongifySelf;
        
        strongSelf.messagesRequest = nil;
        if (error != nil) {
            [strongSelf.view showFailureViewWithRetryCallback:^{
                [weakSelf requestMessages];
            }];
        } else {
            NSDictionary *dict = (NSDictionary *)(result.userInfo);
            
            strongSelf.nextUrl = dict[@"next"];
            NSArray *messages = (NSArray *)(dict[@"list"]);
            if (messages.count == 0) {
                [strongSelf.view showEmptyViewWithImage:nil
                                            title:@"暂无通知消息"
                                        linkTitle:nil
                                linkClickCallback:nil];
            } else {
                [strongSelf.messages addObjectsFromArray:messages];

                [strongSelf.view hideAllStateView];
                strongSelf.messagesTableView.hidden = NO;
                [strongSelf.messagesTableView reloadData];
                
                if (strongSelf.nextUrl.length > 0) {
                    [strongSelf.messagesTableView addInfiniteScrollingWithRefreshingBlock:^{
                        [weakSelf loadMoreMessages];
                    }];
                }
            }
        }
    }];
}

- (void)loadMoreMessages {
    if (self.nextUrl.length == 0 || self.messagesRequest != nil) {
        return;
    }
    
    WeakifySelf;
    self.messagesRequest = [MessageService requestNoticeMessagesWithNextUrl:self.nextUrl
                                                                   callback:^(Result *result, NSError *error) {
                                                                       StrongifySelf;
                                                                       
                                                                       strongSelf.messagesRequest = nil;
                                                                       [strongSelf.messagesTableView footerEndRefreshing];
                                                                       
                                                                       if (error != nil) {
                                                                           [TIP showText:@"加载失败" inView:self.navigationController.view];
                                                                       } else {
                                                                           NSDictionary *dict = (NSDictionary *)(result.userInfo);
                                                                           
                                                                           strongSelf.nextUrl = dict[@"next"];
                                                                           NSArray *messages = (NSArray *)(dict[@"list"]);
                                                                           if (messages.count > 0) {
                                                                               [strongSelf.messages addObjectsFromArray:messages];

                                                                               if (strongSelf.nextUrl.length == 0) {
                                                                                   [strongSelf.messagesTableView footerResetNoMoreData];
                                                                               }

                                                                               strongSelf.messagesTableView.hidden = NO;
                                                                               [strongSelf.messagesTableView reloadData];
                                                                           }
                                                                       }
                                                                   }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoticeMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NoticeMessageTableViewCellId];

    NoticeMessage *message = self.messages[indexPath.row];
    [cell setupWithMessage:message];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NoticeMessage *message = self.messages[indexPath.row];
    
    NoticeMessageDetailViewController *messageDetailVC = [[NoticeMessageDetailViewController alloc] initWithNibName:@"NoticeMessageDetailViewController" bundle:nil];
    
    messageDetailVC.messageId = message.messageId;
    WeakifySelf;
    messageDetailVC.deleteCallBack = ^{
        [weakSelf requestMessages];
    };

    [self.navigationController pushViewController:messageDetailVC animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoticeMessage *message = self.messages[indexPath.row];
    
    return [NoticeMessageTableViewCell heightWithMessage:message];
}

@end

