//
//  StudentSelectorViewController.m
//  X5Teacher
//
//  Created by yebw on 2017/12/27.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "StudentSelectorViewController.h"
#import "StudentSelectorTableViewCell.h"
#import "StudentService.h"
#import "PinYin4Objc.h"
@interface StudentSelectorViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *studentsTableView;
@property (nonatomic, strong) NSMutableArray<User *> *students;
@property (nonatomic, strong) NSMutableDictionary *studentDict;
@property (nonatomic, strong) NSArray *sortedKeys;

@property (nonatomic, strong) BaseRequest *studentsRequest;

@end

@implementation StudentSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.students = [NSMutableArray array];
    if (self.selectedStudents == nil) {
        self.selectedStudents = [NSMutableArray array];
    }
    
    [self registerCellNibs];
    [self requestStudents];
}

- (void)dealloc {
    [self.studentsRequest clearCompletionBlock];
    [self.studentsRequest stop];
    self.studentsRequest = nil;
    
    NSLog(@"%s", __func__);
}

- (void)registerCellNibs {
    [self.studentsTableView registerNib:[UINib nibWithNibName:@"StudentSelectorTableViewCell" bundle:nil] forCellReuseIdentifier:StudentSelectorTableViewCellId];
}

- (void)unselectAll {
    [self.selectedStudents removeAllObjects];
    [self.studentsTableView reloadData];
}

- (void)requestStudents {
    if (self.studentsRequest != nil) {
        return;
    }
    
    [self.view showLoadingView];
    self.studentsTableView.hidden = YES;
    
    WeakifySelf;
    if (!self.classStateMode) {
        
        self.studentsRequest = [StudentService requestStudentsByTeacherCallback:^(Result *result, NSError *error) {
            StrongifySelf;
            [strongSelf handleRequestResult:result error:error];
        }];
    } else {
        if (self.inClass == 1) {
            
            self.studentsRequest = [StudentService requestStudentsByTeacherCallback:^(Result *result, NSError *error) {
                StrongifySelf;
                [strongSelf handleRequestResult:result error:error];
            }];
        } else {
           // 未入学 、 待处理
            self.studentsRequest = [StudentService requestStudentsWithClassState:self.inClass
                                                                        callback:^(Result *result, NSError *error) {
                                                                            StrongifySelf;
                                                                            [strongSelf handleRequestResult:result error:error];
                                                                        }];
        }
    }
    
}

- (void)requestMoveStudents {
   
    // 适配ipad版本
    UIAlertControllerStyle alertStyle;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        alertStyle = UIAlertControllerStyleActionSheet;
    } else {
        alertStyle = UIAlertControllerStyleAlert;
    }
    NSString *title = @"移动到未入学";
    if (self.inClass == 0) {
        title = @"移动到待处理";
    }
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil
                                                                     message:nil
                                                              preferredStyle:alertStyle];
    
    WeakifySelf;
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:title
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [weakSelf requestStudents];
                                                         }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [weakSelf requestStudents];
                                                         }];
    
    [alertVC addAction:sureAction];
    [alertVC addAction:cancelAction];
    [self presentViewController:alertVC
                       animated:YES
                     completion:nil];
}

- (void)handleRequestResult:(Result *)result error:(NSError *)error {
    self.studentsRequest = nil;
    
    [self.view hideAllStateView];
    
    if (error != nil) {
        WeakifySelf;
        [self.view showFailureViewWithRetryCallback:^{
            [weakSelf requestStudents];
        }];
        
        return;
    }
    
    NSDictionary *dict = (NSDictionary *)(result.userInfo);
    NSArray *students = (NSArray *)(dict[@"list"]);
    
    // 停止加载
    self.studentsTableView.hidden = students.count==0;
    
    
    if (students.count > 0) {
        self.studentsTableView.hidden = NO;
        
        [self.students addObjectsFromArray:students];
        [self sortStudents];
        [self.studentsTableView reloadData];
    } else {
        [self.view showEmptyViewWithImage:nil
                                    title:@"暂无学生"
                            centerYOffset:0
                                linkTitle:nil
                        linkClickCallback:nil];
    }
}

- (void)sortStudents {
    if (self.studentDict == nil) {
        self.studentDict = [NSMutableDictionary dictionary];
    }
    HanyuPinyinOutputFormat *outputFormat=[[HanyuPinyinOutputFormat alloc] init];
    [outputFormat setToneType:ToneTypeWithoutTone];
    [outputFormat setVCharType:VCharTypeWithV];
    [outputFormat setCaseType:CaseTypeUppercase];
    [self.students enumerateObjectsUsingBlock:^(User * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *pinyin = [[PinyinHelper toHanyuPinyinStringWithNSString:obj.nickname withHanyuPinyinOutputFormat:outputFormat withNSString:@" "] uppercaseString];
        obj.pinyinName = pinyin;
    
    }];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pinyinName" ascending:YES];
    NSArray *array = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [self.students sortUsingDescriptors:array];
    
    
    for (User *student in self.students) {
        if (student.pinyinName.length > 0) {
          
            NSString *strFirstLetter = [student.pinyinName substringToIndex:1];
            if (self.studentDict[strFirstLetter] != nil) {
                [self.studentDict[strFirstLetter] addObject:student];
            } else {
                NSMutableArray *group = [NSMutableArray arrayWithObject:student];
                [self.studentDict setObject:group forKey:strFirstLetter];
            }
        }
    }
    
    NSArray *keys = [self.studentDict.allKeys sortedArrayUsingSelector:@selector(compare:)];
    self.sortedKeys = keys;
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sortedKeys[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
    NSString *key = self.sortedKeys[section];
    NSArray *group = self.studentDict[key];
    
    return group.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *key = self.sortedKeys[indexPath.section];
    NSArray *group = self.studentDict[key];
    User *student = group[indexPath.row];
    
    StudentSelectorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:StudentSelectorTableViewCellId forIndexPath:indexPath];
    [cell setupWithStudent:student];
    [cell setChoice:[self.selectedStudents containsObject:student]];
    [cell setReviewMode:self.reviewMode];
    if (self.inClass != 1) {
        WeakifySelf;
        cell.longPressCallBack = ^{
            [weakSelf requestMoveStudents];
        };
    }
    if (self.showClassName) {
        [cell setClassName:@"(武义1班)"];
    }
    return cell;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.sortedKeys;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.sortedKeys indexOfObject:title];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.studentDict.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return StudentSelectorTableViewCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSString *key = self.sortedKeys[indexPath.section];
    User *student = self.studentDict[key][indexPath.row];
    
    if (self.reviewMode) {
        if (self.previewCallback != nil) {
            self.previewCallback(student.userId);
        }
        
        return;
    }
    
    StudentSelectorTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([self.selectedStudents containsObject:student]) {
        [self.selectedStudents removeObject:student];
        [cell setChoice:NO];
    } else {
        [self.selectedStudents addObject:student];
        [cell setChoice:YES];
    }
    
    if (self.selectCallback != nil) {
        self.selectCallback(self.selectedStudents.count);
    }
}

@end




