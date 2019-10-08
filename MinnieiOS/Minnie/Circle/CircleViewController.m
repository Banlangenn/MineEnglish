//
//  CircleViewController.m
//  X5
//
//  Created by yebw on 2017/10/8.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "Constants.h"
#import "Application.h"
#import <AVKit/AVKit.h>
#import "PushManager.h"
#import "CircleHomework.h"
#import "WebViewController.h"
#import "UIScrollView+Refresh.h"
#import "UITextView+Placeholder.h"
#import <SDWebImage/UIImageView+WebCache.h>

#import "CircleViewController.h"
#import "CircleVideoTableViewCell.h"
#import "CircleBottomTableViewCell.h"
#import "CircleCommentTableViewCell.h"
#import "CircleLikeUsersTableViewCell.h"
#import "CircleHomeworkViewController.h"
#import "CircleHomeworksViewController.h"
#import "CircleMoreCommentsTableViewCell.h"

@interface CircleViewController ()
<
UITableViewDataSource,
UITableViewDelegate
>

@property (nonatomic, strong) BaseRequest *homeworksRequest;

@property (nonatomic, strong) NSMutableArray<CircleHomework *> *homeworks;
@property (nonatomic, copy) NSString *nextUrl;

@property (nonatomic, weak) IBOutlet UITableView *homeworksTableView;
@property (nonatomic, weak) IBOutlet UIView *inputView;
@property (nonatomic, weak) IBOutlet UIImageView *inputBGImageView;
@property (nonatomic, weak) IBOutlet UITextView *inputTextView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *inputViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *inputViewBottomConstraint;

@property (nonatomic, weak) CircleHomework *currentHomework;
@property (nonatomic, weak) Comment *currentOriginalComment; // 当前回复的评论

@property (nonatomic, assign) BOOL shouldReloadWhenAppeard;

@end


@implementation CircleViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        _homeworks = [NSMutableArray array];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.homeworks removeAllObjects];
#if MANAGERSIDE || TEACHERSIDE
#else
    [self.homeworks addObjectsFromArray:APP.circleList];
#endif
    
    self.homeworksTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    [self.inputTextView setTextContainerInset:UIEdgeInsetsZero];
    [self.inputTextView setContentInset:UIEdgeInsetsZero];
    [self.inputTextView.textContainer setLineFragmentPadding:0];
    
    self.inputBGImageView.image = [[UIImage imageNamed:@"inputBG"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14) resizingMode:UIImageResizingModeStretch];
    
    [self registerCellNibs];
   
    CGFloat width = ScreenWidth;
#if MANAGERSIDE
    width = (ScreenWidth - kRootModularWidth)/2.0;
#endif
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 20.f)];
    footerView.backgroundColor = [UIColor clearColor];
    self.homeworksTableView.tableFooterView = footerView;
    
    [self requestHomeworks];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload)
                                                 name:kNotificationKeyOfDeleteHomeworkTask
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadWhenAppeared:)
                                                 name:kNotificationKeyOfAddComment
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadWhenAppeared:)
                                                 name:kNotificationKeyOfDeleteComment
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadWhenAppeared:)
                                                 name:kNotificationKeyOfProfileUpdated
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self resizeInputTextView];
    
    if (self.shouldReloadWhenAppeard) {
        if (self.homeworks.count == 0) {
            [self requestHomeworks];
        } else {
            [self.homeworksTableView headerBeginRefreshing];
        }
        
        self.shouldReloadWhenAppeard = NO;
    }
}

- (void)reload {
    [self.homeworksRequest clearCompletionBlock];
    [self.homeworksRequest stop];
    self.homeworksRequest = nil;
    
    [self requestHomeworks];
}

- (void)dealloc {
    [self.homeworksRequest clearCompletionBlock];
    [self.homeworksRequest stop];
    self.homeworksRequest = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"%s", __func__);
}

#pragma mark - Private Methods

- (void)registerCellNibs {
    [self.homeworksTableView registerNib:[UINib nibWithNibName:@"CircleVideoTableViewCell" bundle:nil] forCellReuseIdentifier:CircleVideoTableViewCellId];
    [self.homeworksTableView registerNib:[UINib nibWithNibName:@"CircleLikeUsersTableViewCell" bundle:nil] forCellReuseIdentifier:CircleLikeUsersTableViewCellId];
    [self.homeworksTableView registerNib:[UINib nibWithNibName:@"CircleCommentTableViewCell" bundle:nil] forCellReuseIdentifier:CircleCommentTableViewCellId];
    [self.homeworksTableView registerNib:[UINib nibWithNibName:@"CircleMoreCommentsTableViewCell" bundle:nil] forCellReuseIdentifier:CircleMoreCommentsTableViewCellId];
    [self.homeworksTableView registerNib:[UINib nibWithNibName:@"CircleBottomTableViewCell" bundle:nil] forCellReuseIdentifier:CircleBottomTableViewCellId];
}

- (void)reloadWhenAppeared:(NSNotificationCenter *)notification {
    self.shouldReloadWhenAppeard = YES;
}

- (void)requestHomeworks {
    if (self.homeworksRequest != nil) {
        return;
    }
    
    if (self.homeworks.count == 0) {
        self.homeworksTableView.hidden = YES;
        [self.view showLoadingView];
    }
    
    WeakifySelf;
    if (self.userId > 0) {
        self.homeworksRequest = [CirlcleService requestHomeworksWithUserId:self.userId
                                                                  callback:^(Result *result, NSError *error) {
                                                                      StrongifySelf;
                                                                      
                                                                      [strongSelf handleRequestResult:result
                                                                                           isLoadMore:NO
                                                                                                error:error];
                                                                  }];
    } else if (self.classId > 0) {
        self.homeworksRequest = [CirlcleService requestHomeworksWithClassId:self.classId
                                                                   callback:^(Result *result, NSError *error) {
                                                                       StrongifySelf;
                                                                       
                                                                       [strongSelf handleRequestResult:result
                                                                                            isLoadMore:NO
                                                                                                 error:error];
                                                                   }];
    } else {
#if TEACHERSIDE || MANAGERSIDE
#else
        if (self.circleType == CircleSchool) {
            self.homeworksRequest = [CirlcleService requestAllHomeworksWithCallback:^(Result *result, NSError *error) {
                StrongifySelf;
                [strongSelf handleRequestResult:result
                                     isLoadMore:NO
                                          error:error];
            }];
        } else {
            self.homeworksRequest = [CirlcleService requestHomeworksWithLevel:APP.currentUser.clazz.classLevel + 1
                                                                       callback:^(Result *result, NSError *error) {
                                                                           StrongifySelf;
                                                                           
                                                                           [strongSelf handleRequestResult:result
                                                                                                isLoadMore:NO
                                                                                                     error:error];
                                                                       }];
        }
#endif
    }
}

- (void)loadMoreHomeworks {
    if (self.homeworksRequest != nil) {
        return;
    }
    
    WeakifySelf;
    self.homeworksRequest = [CirlcleService loadMoreHomeworksWithURL:self.nextUrl
                                                            callback:^(Result *result, NSError *error) {
                                                                StrongifySelf;
                                                                [strongSelf handleRequestResult:result
                                                                                     isLoadMore:YES
                                                                                          error:error];
                                                            }];
}

- (void)handleRequestResult:(Result *)result
                 isLoadMore:(BOOL)isLoadMore
                      error:(NSError *)error {
    [self.homeworksRequest clearCompletionBlock];
    [self.homeworksRequest stop];
    self.homeworksRequest = nil;
    
    [self.view hideAllStateView];
    
    NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
    NSString *nextUrl = dictionary[@"next"];
    NSArray *homeworks = dictionary[@"list"];
    
    if (isLoadMore) {
        [self.homeworksTableView footerEndRefreshing];
        self.homeworksTableView.hidden = NO;
        
        if (error != nil) {
            return;
        }
        
        if (homeworks.count > 0) {
            [self.homeworks addObjectsFromArray:homeworks];
        }
        
        if (nextUrl.length == 0) {
            [self.homeworksTableView removeFooter];
        }
        
        [self.homeworksTableView reloadData];
    } else {
        // 停止加载
        [self.homeworksTableView headerEndRefreshing];
        self.homeworksTableView.hidden = homeworks.count==0;
        
        if (error != nil) {
            if (homeworks.count > 0) {
                [TIP showText:@"加载失败" inView:self.view];
            } else {
                WeakifySelf;
                [self.view showFailureViewWithRetryCallback:^{
                    [weakSelf requestHomeworks];
                }];
            }
            
            return;
        }
        
        self.currentOriginalComment = nil;
        [self.homeworks removeAllObjects];
        self.nextUrl = nil;
        
        if (homeworks.count > 0) {
            self.homeworksTableView.hidden = NO;
            
            [self.homeworks addObjectsFromArray:homeworks];
            [self.homeworksTableView reloadData];
            
            [self.homeworksTableView addPullToRefreshWithTarget:self
                                               refreshingAction:@selector(requestHomeworks)];
            
            if (nextUrl.length > 0) {
                WeakifySelf;
                [self.homeworksTableView addInfiniteScrollingWithRefreshingBlock:^{
                    [weakSelf loadMoreHomeworks];
                }];
            } else {
                [self.homeworksTableView removeFooter];
            }
            
            APP.circleList = self.homeworks;
            
        } else {
            WeakifySelf;
            [self.view showEmptyViewWithImage:nil
                                        title:@"暂无同学圈内容"
                                centerYOffset:0
                                    linkTitle:nil
                            linkClickCallback:nil
                                retryCallback:^{
                                    [weakSelf requestHomeworks];
                                }];
        }
    }
    
    self.nextUrl = nextUrl;
}

- (void)addComment:(NSString *)text {
    [self.inputTextView resignFirstResponder];
    
    [HUD showProgressWithMessage:@"正在发送评论"];
    
    [CirlcleService commentHomework:self.currentHomework.homeworkSessionId
                  originalCommentId:self.currentOriginalComment.commentId
                            content:text
                           callback:^(Result *result, NSError *error) {
                               if (error == nil) {
                                   [HUD hideAnimated:NO];
                                   
                                   self.inputTextView.text = nil;
                                   
                                   Comment *comment = (Comment *)(result.userInfo);
                                   NSMutableArray *comments = [NSMutableArray arrayWithArray:self.currentHomework.comments];
                                   [comments addObject:comment];
                                   self.currentHomework.comments = comments;
                                   self.currentHomework.commentCount++;
                                   
                                   if (self.currentOriginalComment.commentId > 0) {
                                       if (self.currentOriginalComment.user.userId > 0) {
                                           [PushManager pushText:@"你有新的回复" toUsers:@[@(self.currentOriginalComment.user.userId)] withPushType:PushManagerCircle];
                                       }
                                   } else {
                                       [PushManager pushText:@"你有新的评论" toUsers:@[@(self.currentHomework.student.userId)] withPushType:PushManagerCircle];
                                   }
                                   
                                   [self.homeworksTableView reloadData];
                               } else {
                                   [HUD showErrorWithMessage:@"评论失败"];
                               }
                           }];
}

- (void)resizeInputTextView {
    NSInteger lines = 0;
    if (self.inputTextView.font.lineHeight > 0) {
        lines = [self.inputTextView sizeThatFits:self.inputTextView.frame.size].height / self.inputTextView.font.lineHeight;
    }
    
    CGFloat height = lines * self.inputTextView.font.lineHeight;
    self.inputViewHeightConstraint.constant = MIN(height, self.inputTextView.font.lineHeight * 4) + 36.f;
    
    [self.inputView layoutIfNeeded];
}

- (void)videoButtonPressed:(CircleHomework *)homework {
    self.currentHomework = homework;
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
    self.currentHomework = homework;
    
    NSInteger section = [self.homeworks indexOfObject:homework];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    
    CircleContentBaseTableViewCell *cell = (CircleContentBaseTableViewCell *)[self.homeworksTableView cellForRowAtIndexPath:indexPath];
    
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
            
           // [cell updateLikeState:NO];
            [self.homeworksTableView reloadData];
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
            
           // [cell updateLikeState:YES];
            [self.homeworksTableView reloadData];
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
    self.currentHomework = homework;
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
                                                             [self doDelete:homework];
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

- (void)doDelete:(CircleHomework *)homework {
    [HUD showProgressWithMessage:@"正在删除"];
    [CirlcleService deleteHomework:homework.homeworkSessionId
                          callback:^(Result *result, NSError *error) {
                              if (error == nil) {
                                  [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfDeleteHomeworkTask object:nil userInfo:@{@"homeworkId":@(homework.homeworkSessionId)}];
                                  
                                  [HUD hideAnimated:NO];
                                  
                                  self.currentHomework = nil;
                                  
                                  NSInteger index = [self.homeworks indexOfObject:homework];
                                  if (index < self.homeworks.count) {
                                      [self.homeworks removeObjectAtIndex:index];
                                  }
                                  
                                  [self.homeworksTableView beginUpdates];
                                  [self.homeworksTableView deleteSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationFade];
                                  [self.homeworksTableView endUpdates];
                                  
                                  if (self.homeworks.count == 0) {
                                      self.homeworksTableView.hidden = YES;
                                      
                                      WeakifySelf;
                                      [self.view showEmptyViewWithImage:nil
                                                                  title:@"暂无同学圈内容"
                                                          centerYOffset:0
                                                              linkTitle:nil
                                                      linkClickCallback:nil
                                                          retryCallback:^{
                                                              [weakSelf requestHomeworks];
                                                          }];
                                  }
                                  
                              } else {
                                  [HUD showErrorWithMessage:@"删除失败"];
                              }
                          }];
}

- (void)commentButtonPressed:(CircleHomework *)homework {
    self.currentHomework = homework;
    
    self.currentOriginalComment = nil;
    self.inputTextView.placeholder = nil;
    [self.inputTextView becomeFirstResponder];
}

- (void)avatarButtonPressed:(CircleHomework *)homework
{
    if (self.bSkipAvater)
    {
        return;
    }
    
    CircleHomeworksViewController *circleVC = [[CircleHomeworksViewController alloc] initWithNibName:@"CircleHomeworksViewController" bundle:nil];
    circleVC.userId = homework.student.userId;
    circleVC.userName = homework.student.nickname;
    [circleVC setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:circleVC animated:YES];
    
}


- (void)replyButtonPressed:(CircleHomework *)homework comment:(Comment *)comment {
    self.currentHomework = homework;
    
    if (comment.user.userId == APP.currentUser.userId) {
        // 适配ipad版本
        UIAlertControllerStyle alertStyle;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            alertStyle = UIAlertControllerStyleActionSheet;
        } else {
            alertStyle = UIAlertControllerStyleAlert;
        }
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil
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
                                                                                              
                                                                                              NSMutableArray *comments = [NSMutableArray arrayWithArray:self.currentHomework.comments];
                                                                                              [comments removeObject:comment];
                                                                                              self.currentHomework.comments = comments;
                                                                                              self.currentHomework.commentCount = self.currentHomework.commentCount - 1;
                                                                                              
                                                                                              [self.homeworksTableView reloadData];
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

- (void)moreCommentButtonPressed:(CircleHomework *)homework {
    self.currentHomework = homework;
    
    CircleHomeworkViewController *vc = [[CircleHomeworkViewController alloc] initWithNibName:@"CircleHomeworkViewController" bundle:nil];
    vc.homeworkTaskId = homework.homeworkSessionId;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Notifications

- (void)keyboardFrameWillChange:(NSNotification *)notification {
    NSValue *endValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect kbFrame = [endValue CGRectValue];
    
    if (kbFrame.origin.y >= ScreenHeight) {
        self.inputViewBottomConstraint.constant = -100;
    } else {
        if (self.userId == 0 && self.classId == 0) {
            self.inputViewBottomConstraint.constant = kbFrame.size.height - kTabBarHeight;
        } else {
            self.inputViewBottomConstraint.constant = kbFrame.size.height;
        }
    }
    [UIView animateWithDuration:0.45f
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                     }];
}

- (void)homeworkDidDelete:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSInteger homeworkId = [userInfo[@"homeworkId"] integerValue];
    
    for (CircleHomework *homework in self.homeworks) {
        if (homework.homeworkSessionId == homeworkId) {
            [self.homeworks removeObject:homework];
            
            if (self.homeworks.count == 0) {
                self.homeworksTableView.hidden = YES;
                WeakifySelf;
                [self.view showEmptyViewWithImage:nil
                                            title:@"暂无同学圈内容"
                                    centerYOffset:0
                                        linkTitle:nil
                                linkClickCallback:nil
                                    retryCallback:^{
                                        [weakSelf requestHomeworks];
                                    }];
            } else {
                self.homeworksTableView.hidden = NO;
            }
            
            [self.homeworksTableView reloadData];
            
            break;
        }
    }
}

- (void)commentDidDelete:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSInteger homeworkId = [userInfo[@"homeworkId"] integerValue];
    NSInteger commentId = [userInfo[@"commentId"] integerValue];
    
    
    for (CircleHomework *homework in self.homeworks) {
        if (homework.homeworkSessionId == homeworkId) {
            NSMutableArray *comments = [NSMutableArray arrayWithArray:homework.comments];
            for (Comment *comment in comments) {
                if (comment.commentId == commentId) {
                    if (homework.commentCount > 0) {
                        homework.commentCount --;
                    }
                    
                    [comments removeObject:comment];
                    break;
                }
            }
            
            homework.comments = comments;
            [self.homeworksTableView reloadData];
            break;
        }
    }
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.homeworks.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    CircleHomework *homework = self.homeworks[section];
    
    NSInteger number = 1; // 同学圈内容
    
    number ++; // 点赞区域始终有，根据高度来确定显不显示
    
    if (homework.comments.count > 0) {
        number += homework.comments.count; // 返回的评论，可能不是全部
        if (homework.comments.count < homework.commentCount) { // 查看全部的按钮
            number += 1;
        }
    }
    
    number ++; // 最后圆角白底
    
    return number;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    WeakifySelf;
    CircleHomework *homework = self.homeworks[indexPath.section];
    if (indexPath.row == 0) { //
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
                [weakSelf avatarButtonPressed:homework];
            }];
            
            cell = videoCell;
        }
    } else if (indexPath.row == 1) {
        if (homework.likeUsers.count == 0) {
            UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:@"BlankLikeUsersCellId"];
            if (blankCell == nil) {
                blankCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"BlankLikeUsersCellId"];
            }
            
            cell = blankCell;
        } else {
            CircleLikeUsersTableViewCell *likeUsersCell = [tableView dequeueReusableCellWithIdentifier:CircleLikeUsersTableViewCellId forIndexPath:indexPath];
            
            [likeUsersCell setupWithLikeUsers:homework.likeUsers];
            cell = likeUsersCell;
        }
    } else {
        NSArray *comments = homework.comments;
        NSInteger index = indexPath.row - 2;
        if (index < comments.count) {
            CircleCommentTableViewCell *commentCell = [tableView dequeueReusableCellWithIdentifier:CircleCommentTableViewCellId forIndexPath:indexPath];
            
            Comment *comment = homework.comments[index];
            BOOL isLastOne = (homework.comments.count-1) == index;
            [commentCell setupWithComment:comment
                               isFirstOne:index==0
                                isLastOne:isLastOne
                                  hasMore:homework.comments.count<homework.commentCount];
            
            [commentCell setCommentReplyClickCallback:^{
                [weakSelf replyButtonPressed:homework comment:comment];
            }];
            
            cell = commentCell;
        } else {
            if (comments.count < homework.commentCount && index == comments.count) {
                CircleMoreCommentsTableViewCell *moreCell = [tableView dequeueReusableCellWithIdentifier:CircleMoreCommentsTableViewCellId forIndexPath:indexPath];
                
                [moreCell setMoreButtonClickCallback:^{
                    [weakSelf moreCommentButtonPressed:homework];
                }];
                
                cell = moreCell;
            } else {
                CircleBottomTableViewCell *bottomCell = [tableView dequeueReusableCellWithIdentifier:CircleBottomTableViewCellId forIndexPath:indexPath];
                
                cell = bottomCell;
            }
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CircleHomework *homework = self.homeworks[indexPath.section];
    
    if (indexPath.row == 0) { // 内容区域
        if (homework.videoUrl.length > 0) {
            return [CircleVideoTableViewCell cellHeight];
        }
        
        return 0;
    } else if (indexPath.row == 1) { // 点赞用户区域
        if (homework.likeUsers.count == 0) {
            return 0.f;
        }
        return [CircleLikeUsersTableViewCell heightWithLikeUsers:homework.likeUsers];
    } else {
        NSArray *comments = homework.comments;
        NSInteger index = indexPath.row - 2;
        if (index < comments.count) {
            Comment *comment = comments[index];
            BOOL isLastOne = (comments.count-1) == index;
            return [CircleCommentTableViewCell heightOfComment:comment isFirstOne:index==0 isLastOne:isLastOne];
        } else {
            if (index==comments.count && homework.commentCount>comments.count) {
                return CircleMoreCommentsTableViewCellHeight;
            } else {
                return CircleBottomTableViewCellHeight;
            }
        }
    }
}

@end


