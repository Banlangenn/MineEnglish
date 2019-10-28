//
//  CorrectHomeworkViewController.m
//  X5Teacher
//
//  Created by yebw on 2018/2/6.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "PublicService.h"
#import "CorrectHomeworkViewController.h"
#import "HomeworkSessionService.h"
#import "CorrectHomeworkScoreTableViewCell.h"
#import "CorrectHomeworkCommentTableViewCell.h"
#import "CorrectHomeworkHisCommentTableViewCell.h"
#import "CorrectHomeworkAddCommentViewController.h"
#import "HomeworkTagsTableViewCell.h"
#import "TagsViewController.h"
#import "HomeworkSessionService.h"

@interface CorrectHomeworkViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView * mTableView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint * tableViewBottomLayoutConstraint;

@property (nonatomic, assign) NSInteger currentScore; //评分
@property (nonatomic, strong) NSString * commentText; //评语
@property (nonatomic, assign) NSInteger m_circle;     //分享到朋友圈
@property (nonatomic, assign) NSInteger m_scope;      //1:年级；0：所有
@property (nonatomic, strong) NSArray * commentTags; //常用评论列表

@end

@implementation CorrectHomeworkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentScore = -1;
    self.mTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.commentTags = [NSMutableArray array];
    [self registerCellNibs];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestCommentTags)
                                                 name:kNotificationKeyOfAddTags
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestCommentTags)
                                                 name:kNotificationKeyOfDeleteTags
                                               object:nil];
    
    [self requestCommentTags];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"CorrectHomeworkViewController dealloc");
}


- (void)requestCommentTags
{
    [HomeworkSessionService searchHomeworkSessionCommentWithCallback:^(Result *result, NSError *error) {
        if (error != nil) {
            [HUD showErrorWithMessage:@"常用评语请求失败"];
            return ;
        }
        WeakifySelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            weakSelf.commentTags = (NSArray *)(result.userInfo);
            [weakSelf.mTableView reloadData];
        });
    }];
}

- (void)registerCellNibs
{
    [self.mTableView registerNib:[UINib nibWithNibName:@"CorrectHomeworkScoreTableViewCell" bundle:nil] forCellReuseIdentifier:CorrectHomeworkScoreTableViewCellId];
    [self.mTableView registerNib:[UINib nibWithNibName:@"CorrectHomeworkCommentTableViewCell" bundle:nil] forCellReuseIdentifier:CorrectHomeworkCommentTableViewCellId];
    [self.mTableView registerNib:[UINib nibWithNibName:@"HomeworkTagsTableViewCell" bundle:nil] forCellReuseIdentifier:HomeworkTagsTableViewCellId];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)confirmButtonPressed:(id)sender {
    
    UIButton *confirmBtn = sender;
    if (confirmBtn.selected) {
        return;
    }
    confirmBtn.selected = YES;

    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    if (self.currentScore == -1) {
        [HUD showErrorWithMessage:@"请先评分"];
        return;
    }
    
    /* 评语非必选项
    if (self.commentText.length == 0)
    {
        [HUD showErrorWithMessage:@"请先输入评语"];
        return;
    }
    */
    
    if (self.commentText.length > 40)
    {
        [HUD showErrorWithMessage:@"评语最多输入40字"];
        return;
    }
    
    NSString *reviewText = [self.commentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (reviewText.length == 0)
    {
        reviewText = @"";
    }
    WeakifySelf;
    [HUD showProgressWithMessage:@"正在评分..."];
    // 作业评分
    [HomeworkSessionService correctHomeworkSessionWithId:self.homeworkSession.homeworkSessionId
                                                   score:self.currentScore
                                                    redo:0
                                              sendCircle:self.m_circle
                                                    text:reviewText
                                                   scope:self.m_scope
                                                callback:^(Result *result, NSError *error) {

                                                    confirmBtn.selected = NO;
                                                    if (error != nil) {
                                                        if (error.code == 202) {
                                                            [HUD showErrorWithMessage:@"学生未提交作业"];
                                                        } else {
                                                            [HUD showErrorWithMessage:@"评分失败"];
                                                        }
                                                    } else {
                                                        
                                                        [HUD showWithMessage:@"评分成功"];
                                                        weakSelf.homeworkSession.reviewText = reviewText;
                                                        weakSelf.homeworkSession.score = weakSelf.currentScore;
                                                        weakSelf.homeworkSession.isRedo = 0;
#if TEACHERSIDE | MANAGERSIDE
                                                        if (weakSelf.correctHomeworkCallBack) {
                                                            weakSelf.correctHomeworkCallBack(weakSelf.homeworkSession);
                                                        }
                                                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfCorrectHomework object:nil userInfo:@{@"HomeworkSession":weakSelf.homeworkSession}];
#endif
                                                                                                                [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                                                    }
                                                    [weakSelf updateShareVideo];
//                                                    {
//
//                                                        [weakSelf modifyStarWithReviewText:reviewText];
//                                                    }
                                                }];

}
#pragma mark - 更新学生星星数量
- (void)modifyStarWithReviewText:(NSString *)reviewText{
    WeakifySelf;
    NSInteger count = 0;
    if (self.homeworkSession.score >= 0) {
        count = self.currentScore - self.homeworkSession.score;
    } else { // -1未修改过
        count = self.currentScore;
    }
    [PublicService modifyStarCount:count
                        forStudent:self.homeworkSession.student.userId
                            reason:self.homeworkSession.homework.title
                          callback:^(Result *result, NSError *error) {

                              if (error != nil) {
                                  
                                  [HUD showErrorWithMessage:@"评分失败"];
                              } else {

                                  [HUD showWithMessage:@"评分成功"];
                                  weakSelf.homeworkSession.reviewText = reviewText;
                                  weakSelf.homeworkSession.score = weakSelf.currentScore;
                                  weakSelf.homeworkSession.isRedo = 0;
                                  [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfCorrectHomework object:nil userInfo:@{@"HomeworkSession":weakSelf.homeworkSession}];
                                  [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                              }
                          }];
}


#pragma mark - 更新分享视频
- (void)updateShareVideo{
   
    if (self.m_circle && self.shareVedioUrl) {
        [HomeworkSessionService commitHomeworkWithId:self.homeworkSession.homeworkSessionId
                                            imageUrl:nil
                                            videoUrl:self.shareVedioUrl
                                            callback:^(Result *result, NSError *error) {
                                                
                                            }];
    }
}

- (void)keyboardFrameWillChange:(NSNotification *)notification {
    NSValue *endValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect kbFrame = [endValue CGRectValue];
    
    if (kbFrame.origin.y >= ScreenHeight) {
        self.tableViewBottomLayoutConstraint.constant = 0;
    } else {
        self.tableViewBottomLayoutConstraint.constant = kbFrame.size.height;
    }
    
    [UIView animateWithDuration:0.45f
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                     }];
}

#pragma mark - UITableViewDelegate && Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 2)
    {
        return 0.1;
    }
    return 10.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CGFloat firstCellHeight = (ScreenWidth - 24 - 4 * 10) / 5 + 20 + 10 + 39;
#if MANAGERSIDE
    firstCellHeight = (kColumnThreeWidth - 24 - 4 * 10) / 5 + 20 + 10 + 39;
#endif
    if (indexPath.section == 0)
    {
        return firstCellHeight;
    }
    else if (indexPath.section == 1)
    {
        return CorrectHomeworkCommentTableViewCellHeight;
    }
    else
    {
        CGFloat collectionWidth = ScreenWidth;
#if MANAGERSIDE
        collectionWidth = kColumnThreeWidth;
#endif
        return [HomeworkTagsTableViewCell heightWithTags:self.commentTags typeTitle:@"常用评语:" collectionWidth:collectionWidth] + 40;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
     UITableViewCell *cell = nil;
    WeakifySelf;
    if (indexPath.section == 0)
    {
        CorrectHomeworkScoreTableViewCell * scoreCell = [tableView dequeueReusableCellWithIdentifier:CorrectHomeworkScoreTableViewCellId forIndexPath:indexPath];
       
        scoreCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [scoreCell updateRecommendScoreHomeworkLevel:self.homeworkSession.homework.level score:self.homeworkSession.score];
        [scoreCell setScoreCallback:^(NSInteger score)
        {
            weakSelf.currentScore = score;
        }];

        [scoreCell setShareCallback:^(BOOL share, BOOL shareType) {
           
            weakSelf.m_circle = share;
            weakSelf.m_scope = shareType;
        }];
        cell = scoreCell;
    }
    else if (indexPath.section == 1)
    {
        CorrectHomeworkCommentTableViewCell * commentCell = [tableView dequeueReusableCellWithIdentifier:CorrectHomeworkCommentTableViewCellId forIndexPath:indexPath];
        commentCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [commentCell setupCommentInfo:self.homeworkSession.reviewText];
        self.commentText = self.homeworkSession.reviewText;
        [commentCell setCommentCallback:^(NSString * text) {
            weakSelf.commentText = text;
        }];
        cell = commentCell;
    }
    else
    {
        HomeworkTagsTableViewCell * addCommentCell = [tableView dequeueReusableCellWithIdentifier:HomeworkTagsTableViewCellId forIndexPath:indexPath];
        addCommentCell.selectionStyle = UITableViewCellSelectionStyleNone;
        addCommentCell.type = HomeworkTagsTableViewCellSelectNoneType;
        
        CGFloat collectionWidth = ScreenWidth;
#if MANAGERSIDE
        collectionWidth = kColumnThreeWidth;
#endif
        [addCommentCell setupWithTags:self.commentTags selectedTags:@[] typeTitle:@"常用评语:" collectionWidth:collectionWidth];
        
        WeakifySelf;
        [addCommentCell setSelectCallback:^(NSString *tag) {
            
            [weakSelf updateSelectCellWithTag:tag];
//            NSString *commentText = [NSString stringWithFormat:@"%@  %@",(weakSelf.commentText.length == 0 ? @"": weakSelf.commentText),tag];
//            weakSelf.commentText = commentText;
//
//            CorrectHomeworkCommentTableViewCell * commentCell = (CorrectHomeworkCommentTableViewCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
//            [commentCell setupCommentInfo:commentText];
        }];
        
        [addCommentCell setManageCallback:^{
            TagsViewController *tagsVC = [[TagsViewController alloc] initWithNibName:@"TagsViewController" bundle:nil];
            tagsVC.type = TagsCommentType;
            [weakSelf.navigationController pushViewController:tagsVC animated:YES];
        }];
        
        cell = addCommentCell;
        
    }
    return cell;
}

- (void)updateSelectCellWithTag:(NSString *)tag{
   
    NSString *commentText = [NSString stringWithFormat:@"%@  %@",(self.commentText.length == 0 ? @"": self.commentText),tag];
    self.commentText = commentText;
    
    CorrectHomeworkCommentTableViewCell * commentCell = (CorrectHomeworkCommentTableViewCell *)[self.mTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    [commentCell setupCommentInfo:commentText];
}

@end



