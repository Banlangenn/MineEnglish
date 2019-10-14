//
//  UnfinishedHomeworksViewController.m
//  X5
//
//  Created by yebw on 2017/8/27.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "ClassesViewController.h"
#import "ClassTableViewCell.h"
#import "Clazz.h"
#import "Constants.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "ClassService.h"
#import "UIScrollView+Refresh.h"
#import "CircleHomeworksViewController.h"
#import "PinyinHelper.h"
#import "HanyuPinyinOutputFormat.h"
#import "ClassManagerViewController.h"

@interface ClassesViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *classesTableView;

@property (nonatomic, strong) BaseRequest *classesRequest;

@property (nonatomic, strong) NSMutableArray <Clazz *> *classes;
@property (nonatomic, strong) NSString *nextUrl;

@property (nonatomic, assign) BOOL shouldReloadWhenAppeard;

@end

@implementation ClassesViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        _classes = [NSMutableArray array];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerCellNibs];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 12.f)];
    self.classesTableView.tableFooterView = footerView;
    
    [self requestClasses];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldReload)
                                                 name:kNotificationKeyOfDeleteClass
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldReload)
                                                 name:kNotificationKeyOfDeleteClassStudents
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldReload)
                                                 name:kNotificationKeyOfAddClassStudents
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldReload)
                                                 name:kNotificationKeyOfAddClass
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldReload)
                                                 name:kNotificationKeyOfRedoHomework
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldReload)
                                                 name:kNotificationKeyOfCorrectHomework
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.shouldReloadWhenAppeard) {
        self.shouldReloadWhenAppeard = NO;
        
        [self.classesRequest stop];
        [self.classesRequest clearCompletionBlock];
        self.classesRequest = nil;
        
        if (self.classes.count > 0) {
            [self.classesTableView headerBeginRefreshing];
        } else {
            [self requestClasses];
        }

    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.classesRequest clearCompletionBlock];
    [self.classesRequest stop];
    self.classesRequest = nil;
    
}

#pragma mark - Private Methods

- (void)shouldReload {
    self.shouldReloadWhenAppeard = YES;
}

- (void)registerCellNibs {
    [self.classesTableView registerNib:[UINib nibWithNibName:@"ClassTableViewCell" bundle:nil] forCellReuseIdentifier:ClassTableViewCellId];
}

- (void)requestClasses {
    if (self.classesRequest != nil) {
        return;
    }
    
    if (self.classes.count == 0) {
        [self.view showLoadingView];
        self.classesTableView.hidden = YES;
    }

    WeakifySelf;
    Teacher *teacher = APP.currentUser;
    BOOL isAll = NO;
    if (teacher.authority == TeacherAuthoritySuperManager) {
        
        isAll = YES;
    } else {
        
        // 超级管理员 显示所有班级   管理员、普通教师：显示所有可见普通教师的班级
        
    }
 
    self.classesRequest = [ClassService requestNewClassesWithFinishState:self.isUnfinished?0:1
                                                           campusName:nil
                                                             callback:^(Result *result, NSError *error) {
                                                                 StrongifySelf;
                                                                 [strongSelf handleRequestResult:result
                                                                                      isLoadMore:NO
                                                                                           error:error];
                                                             }];
}

- (void)loadMoreClasses {
    if (self.classesRequest != nil) {
        return;
    }
    
    WeakifySelf;
    self.classesRequest = [ClassService requestClassesWithNextUrl:self.nextUrl
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
    [self.classesRequest clearCompletionBlock];
    self.classesRequest = nil;
    
    [self.view hideAllStateView];
    
    NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
    NSString *nextUrl = dictionary[@"next"];
    NSArray *classes = dictionary[@"list"];

    if (isLoadMore) {
        [self.classesTableView footerEndRefreshing];
        self.classesTableView.hidden = NO;

        if (error != nil) {
            return;
        }
        
        if (classes.count > 0) {
            [self.classes addObjectsFromArray:[self sortClasses:classes]];
        }
        
        if (nextUrl.length == 0) {
            [self.classesTableView removeFooter];
        }
        
        [self.classesTableView reloadData];
    } else {
        // 停止加载
        [self.classesTableView headerEndRefreshing];
        self.classesTableView.hidden = classes.count==0;
        
        if (error != nil) {
            if (classes.count > 0) {
                [TIP showText:@"加载失败" inView:self.view];
            } else {
                WeakifySelf;
                [self.view showFailureViewWithRetryCallback:^{
                    [weakSelf requestClasses];
                }];
            }
            
            return;
        }
        
        [self.classes removeAllObjects];
        self.nextUrl = nil;

        if (classes.count > 0) {
            self.classesTableView.hidden = NO;

            [self.classes addObjectsFromArray:[self sortClasses:classes]];
            [self.classesTableView reloadData];
            
            [self.classesTableView addPullToRefreshWithTarget:self
                                             refreshingAction:@selector(requestClasses)];
            
            if (nextUrl.length > 0) {
                WeakifySelf;
                [self.classesTableView addInfiniteScrollingWithRefreshingBlock:^{
                    [weakSelf loadMoreClasses];
                }];
            } else {
                [self.classesTableView removeFooter];
            }
        } else {
            WeakifySelf;
            [self.view showEmptyViewWithImage:nil
                                        title:@"暂无班级"
                                centerYOffset:0
                                    linkTitle:nil
                            linkClickCallback:nil
                                retryCallback:^{
                                    [weakSelf.classesRequest stop];
                                    [weakSelf.classesRequest clearCompletionBlock];
                                    weakSelf.classesRequest = nil;

                                    [weakSelf requestClasses];
                                }];
        }
    }
    
    self.nextUrl = nextUrl;
}

- (NSArray *)sortClasses:(NSArray *)classes {
   
    NSMutableArray *tempClasses = [NSMutableArray arrayWithArray:classes];
    HanyuPinyinOutputFormat *outputFormat=[[HanyuPinyinOutputFormat alloc] init];
    [outputFormat setToneType:ToneTypeWithoutTone];
    [outputFormat setVCharType:VCharTypeWithV];
    [outputFormat setCaseType:CaseTypeUppercase];
    [tempClasses enumerateObjectsUsingBlock:^(Clazz * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *pinyin = [[PinyinHelper toHanyuPinyinStringWithNSString:obj.name withHanyuPinyinOutputFormat:outputFormat withNSString:@" "] uppercaseString];
        obj.pinyinName = pinyin;
        
    }];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pinyinName" ascending:YES];
    NSArray *array = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [tempClasses sortUsingDescriptors:array];
    return tempClasses;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.classes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ClassTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ClassTableViewCellId forIndexPath:indexPath];
    
    Clazz *clazz = self.classes[indexPath.row];
    
    [cell setupWithClass:clazz];
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ClassTableViewCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    Clazz *clazz = self.classes[indexPath.row];

    if (self.isManageMode) {
       
//        if (APP.currentUser.canManageClasses) {
        
            ClassManagerViewController *vc = [[ClassManagerViewController alloc] initWithNibName:@"ClassManagerViewController" bundle:nil];
            vc.classId = clazz.classId;
            [self.navigationController pushViewController:vc animated:YES];
//        }
    } else {
        CircleHomeworksViewController *homeworksVC = [[CircleHomeworksViewController alloc] initWithNibName:@"CircleHomeworksViewController" bundle:nil];
        homeworksVC.clazz = clazz;
        [homeworksVC setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:homeworksVC animated:YES];
    }
}

@end


