//
//  ClassSelectorViewController.m
//  X5Teacher
//
//  Created by yebw on 2017/12/27.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "ClassSelectorViewController.h"
#import "ClassService.h"
#import "ClassSelectorTableViewCell.h"
#import "UIScrollView+Refresh.h"

#import "PinyinHelper.h"
#import "HanyuPinyinOutputFormat.h"

@interface ClassSelectorViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray<Clazz *> *classes;

@property (nonatomic, copy) NSString *nextUrl;

@property (nonatomic, weak) IBOutlet UITableView *classesTableView;

@property (nonatomic, strong) BaseRequest *classesRequest;

@end

@implementation ClassSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.classes = [NSMutableArray array];
    if (self.selectedClasses == nil) {
        self.selectedClasses = [NSMutableArray array];
    }
    
    [self registerCellNibs];
    
    [self requestClasses];
}

- (void)dealloc {
    [self.classesRequest clearCompletionBlock];
    [self.classesRequest stop];
    self.classesRequest = nil;
    
    
}

- (void)registerCellNibs {
    [self.classesTableView registerNib:[UINib nibWithNibName:@"ClassSelectorTableViewCell" bundle:nil] forCellReuseIdentifier:ClassSelectorTableViewCellId];
}

- (void)unselectAll {
    [self.selectedClasses removeAllObjects];
    [self.classesTableView reloadData];
}

- (void)requestClasses {
    if (self.classesRequest != nil) {
        return;
    }
    
    [self.view showLoadingView];
    self.classesTableView.hidden = YES;
    
    WeakifySelf;
    self.classesRequest = [ClassService requestNewClassesWithFinishState:0
                                                           campusName:nil
                                                             callback:^(Result *result, NSError *error) {
                                                                 StrongifySelf;
                                                                 [strongSelf handleRequestResult:result error:error];
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
                                                             [strongSelf handleRequestResult:result error:error];
                                                         }];
}

- (void)handleRequestResult:(Result *)result error:(NSError *)error {
    self.classesRequest = nil;
    
    [self.view hideAllStateView];
    
    NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
    NSString *nextUrl = dictionary[@"next"];
    NSArray *classes = dictionary[@"list"];
    
    BOOL isLoadMore = self.nextUrl.length > 0;
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
        
        if (classes.count > 0) {
            self.classesTableView.hidden = NO;
            
            [self.classes addObjectsFromArray:[self sortClasses:classes]];
            [self.classesTableView reloadData];
            
            if (nextUrl.length > 0) {
                WeakifySelf;
                [self.classesTableView addInfiniteScrollingWithRefreshingBlock:^{
                    [weakSelf loadMoreClasses];
                }];
            } else {
                [self.classesTableView removeFooter];
            }
        } else {
            [self.view showEmptyViewWithImage:nil
                                        title:@"暂无班级"
                                centerYOffset:0
                                    linkTitle:nil
                            linkClickCallback:nil];
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
    ClassSelectorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ClassSelectorTableViewCellId forIndexPath:indexPath];
    
    Clazz *clazz = self.classes[indexPath.row];
    
    [cell setupWithClazz:clazz];
    [cell setChoice:[self.selectedClasses containsObject:clazz]];
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ClassSelectorTableViewCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    Clazz *clazz = self.classes[indexPath.row];
    ClassSelectorTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([self.selectedClasses containsObject:clazz]) {
        [self.selectedClasses removeObject:clazz];
        [cell setChoice:NO];
    } else {
        [self.selectedClasses addObject:clazz];
        [cell setChoice:YES];
    }
    
    if (self.selectCallback != nil) {
        self.selectCallback(self.selectedClasses.count);
    }
}

@end

