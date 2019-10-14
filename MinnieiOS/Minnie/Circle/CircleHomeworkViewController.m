//
//  CircleHomeworkViewController.m
//  X5
//
//  Created by yebw on 2017/8/21.
//  Copyright © 2017年 mfox. All rights reserved.
//


#import "Comment.h"
#import "Constants.h"
#import "PushManager.h"
#import <AVKit/AVKit.h>
#import "CircleService.h"
#import "UITextView+Placeholder.h"
#import "CircleVideoTableViewCell.h"
#import "CircleHomeworkViewController.h"
#import "HomeworkDetailCommentTableViewCell.h"
#import "HomeworkDetailLikeUsersTableViewCell.h"

@interface CircleHomeworkViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UITableView *homeworkTableView;

@property (nonatomic, weak) IBOutlet UIView *inputView;
@property (nonatomic, weak) IBOutlet UIImageView *inputBGImageView;
@property (nonatomic, weak) IBOutlet UITextView *inputTextView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *inputViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *inputViewBottomConstraint;

@property (nonatomic, strong) CircleHomework *homework;
@property (nonatomic, weak) Comment *currentOriginalComment;
@property (nonatomic, strong) BaseRequest *requestHomeworkRequest;

@property (nonatomic, weak) IBOutlet CircleContentBaseTableViewCell *contentCell;

@end

@implementation CircleHomeworkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.homeworkTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    [self.inputTextView setTextContainerInset:UIEdgeInsetsZero];
    [self.inputTextView setContentInset:UIEdgeInsetsZero];
    [self.inputTextView.textContainer setLineFragmentPadding:0];
    
    self.inputBGImageView.image = [[UIImage imageNamed:@"inputBG"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14) resizingMode:UIImageResizingModeStretch];
    
    [self registerCellNibs];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20.f)];
    footerView.backgroundColor = [UIColor clearColor];
    self.homeworkTableView.tableFooterView = footerView;
    
    [self requestHomework];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self resizeInputTextView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.requestHomeworkRequest clearCompletionBlock];
    [self.requestHomeworkRequest stop];
    self.requestHomeworkRequest = nil;
    
}

#pragma mark - Private Methods

- (void)registerCellNibs {
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"CircleVideoTableViewCell" bundle:nil] forCellReuseIdentifier:CircleVideoTableViewCellId];
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkDetailLikeUsersTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkDetailLikeUsersTableViewCellId];
    [self.homeworkTableView registerNib:[UINib nibWithNibName:@"HomeworkDetailCommentTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkDetailCommentTableViewCellId];
}

- (void)resizeInputTextView {
    NSInteger lines = 0;
    if (self.inputTextView.font.lineHeight > 0) {
        lines = [self.inputTextView sizeThatFits:self.inputTextView.frame.size].height / self.inputTextView.font.lineHeight;
    }
    
    CGFloat height = lines * self.inputTextView.font.lineHeight;
    self.inputViewHeightConstraint.constant = MIN(height, self.inputTextView.font.lineHeight * 4) + 24.f;
    
    [self.inputView layoutIfNeeded];
}

- (void)addComment:(NSString *)text {
    [self.inputTextView resignFirstResponder];
    
    [HUD showProgressWithMessage:@"正在发送评论"];
    
    [CirlcleService commentHomework:self.homework.homeworkSessionId
                  originalCommentId:self.currentOriginalComment.commentId
                            content:text
                           callback:^(Result *result, NSError *error) {
                               if (error == nil) {
                                   [HUD hideAnimated:NO];
                                   
                                   self.inputTextView.text = nil;
                                   [self resizeInputTextView];
                                   
                                   Comment *comment = (Comment *)(result.userInfo);
                                   NSMutableArray *comments = [NSMutableArray arrayWithArray:self.homework.comments];
                                   [comments addObject:comment];
                                   self.homework.comments = comments;
                                   self.homework.commentCount += 1;
                                   
                                   [self.homeworkTableView reloadData];
                                   
                                   if (self.currentOriginalComment.commentId > 0) {
                                       if (self.currentOriginalComment.user.userId > 0) {
                                           [PushManager pushText:@"你有新的回复" toUsers:@[@(self.currentOriginalComment.user.userId)] withPushType:PushManagerCircle];
                                       }
                                   } else {
                                       [PushManager pushText:@"你有新的评论" toUsers:@[@(self.homework.student.userId)] withPushType:PushManagerCircle];
                                   }
                               } else {
                                   [HUD showErrorWithMessage:@"评论失败"];
                               }
                           }];
}

- (void)requestHomework {
    if (self.requestHomeworkRequest != nil) {
        return;
    }
    
    self.inputView.hidden = YES;
    self.homeworkTableView.hidden = YES;
    [self.contentView showLoadingView];
    
    WeakifySelf;
    self.requestHomeworkRequest = [CirlcleService requestHomeworkWithId:self.homeworkTaskId
                                                               callback:^(Result *result, NSError *error) {
                                                                   StrongifySelf;
                                                                   strongSelf.requestHomeworkRequest = nil;
                                                                   
                                                                   if (error != nil) {
                                                                       if (error.code == 402) {
                                                                           [strongSelf.contentView showEmptyViewWithImage:nil
                                                                                                                    title:@"该同学圈已删除"
                                                                                                                linkTitle:nil
                                                                                                        linkClickCallback:nil];
                                                                       } else {
                                                                           [strongSelf.contentView showFailureViewWithRetryCallback:^{
                                                                               [weakSelf requestHomework];
                                                                           }];
                                                                       }
                                                                       
                                                                       return ;
                                                                   }
                                                                   
                                                                   strongSelf.homework = (CircleHomework *)(result.userInfo);
                                                                   
                                                                   [strongSelf.contentView hideAllStateView];
                                                                   strongSelf.inputView.hidden = NO;
                                                                   strongSelf.homeworkTableView.hidden = NO;
                                                                   [strongSelf.homeworkTableView reloadData];
                                                               }];
}

- (void)videoButtonPressed:(CircleHomework *)homework {
    AVAudioSession *session =[AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc]init];
    NSString *url = homework.videoUrl;
    playerViewController.player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:url]];
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:playerViewController animated:YES completion:nil];
    playerViewController.view.frame = [UIScreen mainScreen].bounds;
    [playerViewController.player play];
}

- (void)likeButtonPressed:(CircleHomework *)homework {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    CircleContentBaseTableViewCell *cell = (CircleContentBaseTableViewCell *)[self.homeworkTableView cellForRowAtIndexPath:indexPath];
    
    [cell updateLikeState:!homework.liked];
    if (homework.liked) {
        User *userToRemove = nil;
        for (User *user in homework.likeUsers) {
            if (user.userId == APP.currentUser.userId) {
                userToRemove = user;
                break;
            }
        }
        if (userToRemove != nil) {
            NSMutableArray *users = [NSMutableArray arrayWithArray:homework.likeUsers];
            [users removeObject:userToRemove];
            homework.likeUsers = users;
            
            [self.homeworkTableView reloadData];
        }
        
        [CirlcleService unlikeHomework:homework.homeworkSessionId
                              callback:nil];
    } else {
        User *userToAdd = nil;
        for (User *user in homework.likeUsers) {
            if (user.userId == APP.currentUser.userId) {
                userToAdd = user;
                break;
            }
        }
        if (userToAdd == nil) {
            if (homework.likeUsers == nil) {
                homework.likeUsers = [NSMutableArray array];
            }
            
            NSMutableArray *users = [NSMutableArray arrayWithArray:homework.likeUsers];
            [users addObject:APP.currentUser];
            homework.likeUsers = users;
            
            [self.homeworkTableView reloadData];
        }
        
        [CirlcleService likeHomework:homework.homeworkSessionId
                            callback:^(Result *result, NSError *error) {
                                if (error == nil) {
                                    [PushManager pushText:@"有人赞了你" toUsers:@[@(homework.student.userId)] withPushType:PushManagerCircle];
                                }
                            }];
    }
    
    homework.liked = !homework.liked;
}

- (void)deleteButtonPressed:(CircleHomework *)homework {
    // 适配ipad版本
    UIAlertControllerStyle alertStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        alertStyle = UIAlertControllerStyleActionSheet;
    } else {
        alertStyle = UIAlertControllerStyleAlert;
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"删除这条同学圈?"
                                                                     message:nil
                                                              preferredStyle:alertStyle];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"删除"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [HUD showProgressWithMessage:@"正在删除"];
                                                             [CirlcleService deleteHomework:homework.homeworkSessionId
                                                                                   callback:^(Result *result, NSError *error) {
                                                                                       if (error == nil) {
                                                                                           [HUD showWithMessage:@"已删除"];
                                                                                           
                                                                                           [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfDeleteHomeworkTask object:nil userInfo:@{@"homeworkId":@(homework.homeworkSessionId)}];
                                                                                           
                                                                                           [self.navigationController popViewControllerAnimated:YES];
                                                                                       } else {
                                                                                           [HUD showErrorWithMessage:@"删除失败"];
                                                                                       }
                                                                                   }];
                                                         }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * _Nonnull action) {
                                                   }];
    
    [alertVC addAction:deleteAction];
    [alertVC addAction:cancel];

    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertVC
                       animated:YES
                     completion:nil];
}

- (void)commentButtonPressed:(CircleHomework *)homework {
    self.currentOriginalComment = nil;
    self.inputTextView.placeholder = nil;
    [self.inputTextView becomeFirstResponder];
}

- (void)replyButtonPressed:(CircleHomework *)homework comment:(Comment *)comment {
    if (comment.user.userId == APP.currentUser.userId) {
        // 适配ipad版本
        UIAlertControllerStyle alertStyle;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            alertStyle = UIAlertControllerStyleActionSheet;
        } else {
            alertStyle = UIAlertControllerStyleAlert;
        }
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"删除该评论？"
                                                                         message:nil
                                                                  preferredStyle:alertStyle];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"删除"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 [HUD showProgressWithMessage:@"正在删除"];
                                                                 [CirlcleService deleteComment:comment.commentId
                                                                                      callback:^(Result *result, NSError *error) {
                                                                                          if (error == nil) {
                                                                                              [HUD hideAnimated:NO];
                                                                                              
                                                                                              [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfDeleteComment object:nil userInfo:@{@"homeworkId":@(homework.homeworkSessionId),
                                                                                                                                                                                                               @"commentId":@(comment.commentId)
                                                                                                                                                                                                               }];
                                                                                              
                                                                                              NSMutableArray *comments = [NSMutableArray arrayWithArray:self.homework.comments];
                                                                                              [comments removeObject:comment];
                                                                                              self.homework.comments = comments;
                                                                                              self.homework.commentCount -= 1;
                                                                                              
                                                                                              [self.homeworkTableView reloadData];
                                                                                          } else {
                                                                                              [HUD showErrorWithMessage:@"删除失败"];
                                                                                          }
                                                                                      }];
                                                             }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                       }];
        
        [alertVC addAction:deleteAction];
        [alertVC addAction:cancel];
        
        alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:alertVC
                           animated:YES
                         completion:nil];
    } else {
        self.inputTextView.placeholder = [NSString stringWithFormat:@"回复 %@", comment.user.nickname];
        
        self.currentOriginalComment = comment;
        [self.inputTextView becomeFirstResponder];
    }
}

#pragma mark - Notification

- (void)keyboardFrameWillChange:(NSNotification *)notification {
    NSValue *endValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect kbFrame = [endValue CGRectValue];
    
    if (kbFrame.origin.y >= ScreenHeight) {
        self.inputViewBottomConstraint.constant = 0;
    } else {
        self.inputViewBottomConstraint.constant = kbFrame.size.height;
    }
    
    [UIView animateWithDuration:0.45f
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                     }];
}


#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self resizeInputTextView];
    
    if (textView.text.length > 0) {
        [textView scrollRangeToVisible:NSMakeRange(textView.text.length - 1, 1)];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [self addComment:textView.text];
        return NO;
    }
    
    return YES;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.homework == nil) {
        return 0;
    }
    
    return 1 + 1 + self.homework.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    WeakifySelf;
    if (indexPath.row == 0) {
        CircleHomework *homework = self.homework;
        if (homework.videoUrl.length > 0) {
            CircleVideoTableViewCell *videoCell = [tableView dequeueReusableCellWithIdentifier:CircleVideoTableViewCellId forIndexPath:indexPath];
            
            [videoCell setupWithHomework:homework];
            
            [videoCell setVideoClickCallback:^{
                [weakSelf videoButtonPressed:homework];
            }];
            
            [videoCell setDeleteClickCallback:^{
                [weakSelf deleteButtonPressed:homework];
            }];
            
            [videoCell setLikeClickCallback:^{
                [weakSelf likeButtonPressed:homework];
            }];
            
            [videoCell setCommentClickCallback:^{
                [weakSelf commentButtonPressed:homework];
            }];
            
            [videoCell setAvatarClickCallback:^{
                
            }];
            
            weakSelf.contentCell = videoCell;
            
            cell = videoCell;
        }
    } else if (indexPath.row == 1) {
        if (self.homework.likeUsers.count == 0) {
            return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        } else {
            HomeworkDetailLikeUsersTableViewCell *likeUsersCell = [tableView dequeueReusableCellWithIdentifier:HomeworkDetailLikeUsersTableViewCellId forIndexPath:indexPath];
            
            [likeUsersCell setupWithLikeUsers:self.homework.likeUsers];
            
            cell = likeUsersCell;;
        }
    } else {
        NSInteger index = indexPath.row - 2;
        Comment *comment = self.homework.comments[index];
        
        HomeworkDetailCommentTableViewCell *commentCell = [tableView dequeueReusableCellWithIdentifier:HomeworkDetailCommentTableViewCellId forIndexPath:indexPath];
        
        [commentCell setupWithComment:comment isFirstOne:(index==0) isLastOne:(index==self.homework.comments.count-1)];
        
        [commentCell setCommentReplyClickCallback:^{
            [weakSelf replyButtonPressed:weakSelf.homework comment:comment];
        }];
        
        cell = commentCell;
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0.f;
    
    if (indexPath.row == 0) {
        CircleHomework *homework = self.homework;
        if (homework.videoUrl.length > 0) {
            height = [CircleVideoTableViewCell cellHeight];
        }
    } else if (indexPath.row == 1) {
        if (self.homework.likeUsers.count > 0) {
            height = [HomeworkDetailLikeUsersTableViewCell heightWithLikeUsers:self.homework.likeUsers];
        }
    } else {
        NSInteger index = indexPath.row - 2;
        Comment *comment = self.homework.comments[index];
        
        height = [HomeworkDetailCommentTableViewCell heightOfComment:comment
                                                          isFirstOne:(index==0)
                                                           isLastOne:(index==self.homework.comments.count-1)];
    }
    
    return height;
}

@end

