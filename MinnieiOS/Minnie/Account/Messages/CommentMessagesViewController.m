//
//  CommentMessagesViewController.m
//  X5
//
//  Created by yebw on 2017/9/12.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "CommentMessagesViewController.h"
#import "CommentMessageTableViewCell.h"
#import "MessageService.h"
#import "UIColor+HEX.h"
#import "UIScrollView+Refresh.h"
#import "CircleHomeworkViewController.h"

@interface CommentMessagesViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *messagesTableView;

@property (nonatomic, strong) NSMutableArray<Comment *> *messages;
@property (nonatomic, copy) NSString *nextUrl;

@property (nonatomic, strong) BaseRequest *messagesRequest;

@end

@implementation CommentMessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithHex:0xF5F5F5];
    if (@available(iOS 11.0, *)) {
        self.messagesTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    self.messages = [NSMutableArray array];
    
    [self registerCellNibs];
    
    [self requestMessages];
}

- (void)dealloc {
    [self.messagesRequest clearCompletionBlock];
    [self.messagesRequest stop];
    self.messagesRequest = nil;
    
    
}

#pragma mark - Private Methods

- (void)registerCellNibs {
    [self.messagesTableView registerNib:[UINib nibWithNibName:@"CommentMessageTableViewCell" bundle:nil] forCellReuseIdentifier:CommentMessageTableViewCellId];
}

- (void)requestMessages {
    if (self.messagesRequest != nil) {
        return;
    }
    
    self.messagesTableView.hidden = YES;
    [self.view showLoadingView];

    WeakifySelf;
    self.messagesRequest = [MessageService requestCommentMessagesWithCallback:^(Result *result, NSError *error) {
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
                                                  title:@"暂无评论消息"
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
    self.messagesRequest = [MessageService requestCommentMessagesWithNextUrl:self.nextUrl
                                                                   callback:^(Result *result, NSError *error) {
                                                                       StrongifySelf;
                                                                       
                                                                       strongSelf.messagesRequest = nil;
                                                                       [strongSelf.messagesTableView footerEndRefreshing];
                                                                       
                                                                       if (error != nil) {
                                                                           [HUD showErrorWithMessage:@"加载失败"];
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
    CommentMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CommentMessageTableViewCellId];
    
    Comment *message = self.messages[indexPath.row];
    [cell setupWithMessage:message];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    Comment *message = self.messages[indexPath.row];
    
    CircleHomeworkViewController *homeworkVC = [[CircleHomeworkViewController alloc] initWithNibName:@"CircleHomeworkViewController" bundle:nil];
    homeworkVC.homeworkTaskId = message.homeworkSessionId;
    [self.navigationController pushViewController:homeworkVC animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CommentMessageTableViewCellHeight;
}

@end


