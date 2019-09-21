//
//  NoticeMessageDetailViewController.m
//  X5
//
//  Created by yebw on 2017/9/19.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "NoticeMessageDetailViewController.h"
#import "NoticeMessageHeadTableViewCell.h"
#import "NoticeMessageTextItemTableViewCell.h"
#import "NoticeMessageImageItemTableViewCell.h"
#import "MessageService.h"

@interface NoticeMessageDetailViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UITableView *messageTableView;

@property (nonatomic, strong) BaseRequest *messageRequest;
@property (nonatomic, strong) NoticeMessage *message;

@end

@implementation NoticeMessageDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerCellNibs];
    
    [self requestMessage];
}

- (void)dealloc {
    [self.messageRequest clearCompletionBlock];
    [self.messageRequest stop];
    self.messageRequest = nil;
    
    NSLog(@"%s", __func__);
}
- (IBAction)deleteMessageAction:(id)sender {
    
    [MessageService requestDeleteMessagesWithId:self.messageId callback:^(Result *result, NSError *error) {
        
        if (!error) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

#pragma mark - Private Methods

- (void)registerCellNibs {
    [self.messageTableView registerNib:[UINib nibWithNibName:@"NoticeMessageHeadTableViewCell" bundle:nil] forCellReuseIdentifier:NoticeMessageHeadTableViewCellId];
    [self.messageTableView registerNib:[UINib nibWithNibName:@"NoticeMessageTextItemTableViewCell" bundle:nil] forCellReuseIdentifier:NoticeMessageTextItemTableViewCellId];
    [self.messageTableView registerNib:[UINib nibWithNibName:@"NoticeMessageImageItemTableViewCell" bundle:nil] forCellReuseIdentifier:NoticeMessageImageItemTableViewCellId];
}

- (void)requestMessage {
    if (self.messageRequest != nil) {
        return;
    }

    self.messageTableView.hidden = YES;
    [self.contentView showLoadingView];
    
    WeakifySelf;
    self.messageRequest = [MessageService requestNoticeMessageWithId:self.messageId
                                                            callback:^(Result *result, NSError *error) {
                                                                StrongifySelf;
                                                                
                                                                strongSelf.messageRequest = nil;
                                                                
                                                                if (error != nil) {
                                                                    [strongSelf.contentView showFailureViewWithRetryCallback:^{
                                                                        [weakSelf requestMessage];
                                                                    }];
                                                                } else {
                                                                    [strongSelf.contentView hideAllStateView];
                                                                    
                                                                    strongSelf.message = (NoticeMessage *)(result.userInfo);
                                                                    strongSelf.messageTableView.hidden = NO;
                                                                    [strongSelf.messageTableView reloadData];
                                                                }
                                                            }];
}

#pragma mark - UITableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.message == nil) {
        return 0;
    }
    
    return self.message.items.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if (indexPath.row == 0) {
        NoticeMessageHeadTableViewCell *headCell = [tableView dequeueReusableCellWithIdentifier:NoticeMessageHeadTableViewCellId];
        [headCell setupWithMessage:self.message];
        
        cell = headCell;
    } else {
        NSInteger index = indexPath.row - 1;
        NoticeMessageItem *item = self.message.items[index];
        if (item.text.length > 0) {
            NoticeMessageTextItemTableViewCell *textCell = [tableView dequeueReusableCellWithIdentifier:NoticeMessageTextItemTableViewCellId];
            [textCell setupWithMessageItem:item];
            
            cell = textCell;
        } else {
            NoticeMessageImageItemTableViewCell *imageCell = [tableView dequeueReusableCellWithIdentifier:NoticeMessageImageItemTableViewCellId];
            [imageCell setupWithMessageItem:item];
            
            cell = imageCell;
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0.f;
    
    if (indexPath.row == 0) {
        height = [NoticeMessageHeadTableViewCell heightWithMessage:self.message];
    } else {
        NSInteger index = indexPath.row - 1;
        NoticeMessageItem *item = self.message.items[index];
        if (item.text.length > 0) {
            height = [NoticeMessageTextItemTableViewCell heightWithMessageItem:item];
        } else {
            height = [NoticeMessageImageItemTableViewCell heightWithMessageItem:item];
        }
    }
    
    return height;
}

@end

