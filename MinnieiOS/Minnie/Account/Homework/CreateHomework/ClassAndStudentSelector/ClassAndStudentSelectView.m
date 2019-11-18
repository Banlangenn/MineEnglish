//
//  ClassAndStudentSelectView.m
//  Minnie
//
//  Created by songzhen on 2019/6/26.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "ClassService.h"
#import "StudentService.h"
#import "SegmentControl.h"
#import "TeacherService.h"
#import "HomeworkService.h"
#import "ClassSelectorTableViewCell.h"
#import "StudentSelectorTableViewCell.h"
//#import "UIScrollView+Refresh.h"
#import "PinyinHelper.h"
#import "HanyuPinyinOutputFormat.h"
#import "ClassAndStudentSelectView.h"


@interface ClassAndStudentSelectView ()<
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic, assign) BOOL ignoreScrollCallback;

@property (weak, nonatomic) IBOutlet UITableView *classTableView;
@property (weak, nonatomic) IBOutlet UITableView *studentTableView;

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UIScrollView *containerScrollView;
@property (nonatomic, weak) IBOutlet UIView *customTitleView;
@property (nonatomic, weak) IBOutlet UIButton *sendButton;
@property (nonatomic, weak) SegmentControl *segmentControl;

@property (nonatomic, strong) NSArray *teachers;

@property (nonatomic, strong) NSMutableArray *classes;
@property (nonatomic, strong) NSArray *classtSortedKeys;
@property (nonatomic, strong) NSMutableDictionary *classDict;

@property (nonatomic, strong) NSMutableArray *students;
@property (nonatomic, strong) NSArray *studentSortedKeys;
@property (nonatomic, strong) NSMutableDictionary *studentDict;

@property (nonatomic, strong) NSMutableArray *selectedClasses;
@property (nonatomic, strong) NSMutableArray *selectedStudents;


@property (nonatomic, assign) CGFloat screenWidth;

@end

@implementation ClassAndStudentSelectView

-(void)awakeFromNib{
    
    [super awakeFromNib];
    
    self.classes = [NSMutableArray array];
    self.classDict = [NSMutableDictionary dictionary];
    
    self.students = [NSMutableArray array];
    self.studentDict = [NSMutableDictionary dictionary];
    
    self.selectedClasses = [NSMutableArray array];
    self.selectedStudents = [NSMutableArray array];
    
    self.classTableView.delegate = self;
    self.classTableView.dataSource = self;
    self.studentTableView.delegate = self;
    self.studentTableView.dataSource = self;
    self.containerScrollView.delegate = self;
    
    UIView *classFooterView = [UIView new];
    classFooterView.backgroundColor = [UIColor clearColor];
    self.classTableView.tableFooterView = classFooterView;
    
    UIView *studentFooterView = [UIView new];
    studentFooterView.backgroundColor = [UIColor clearColor];
    self.studentTableView.tableFooterView = studentFooterView;
    
    self.screenWidth = 375;
    self.sendButton.enabled = NO;
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [self registerCellNibs];
    
    self.segmentControl = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SegmentControl class]) owner:nil options:nil] lastObject];
    self.segmentControl.titles = @[@"班级",@"个人"];
    self.segmentControl.selectedIndex = 0;
   
    WeakifySelf;
    self.segmentControl.indexChangeHandler = ^(NSUInteger selectedIndex) {
        [weakSelf showChildPageViewControllerWithIndex:selectedIndex animated:YES shouldLocate:YES];
    };
    [self.customTitleView addSubview:self.segmentControl];
    [self showChildPageViewControllerWithIndex:0 animated:NO shouldLocate:YES];
   
    [self requestClasses];
    [self requestStudents];
    
}
- (void)registerCellNibs {
    
    [self.classTableView registerNib:[UINib nibWithNibName:@"ClassSelectorTableViewCell" bundle:nil] forCellReuseIdentifier:ClassSelectorTableViewCellId];
    [self.studentTableView registerNib:[UINib nibWithNibName:@"StudentSelectorTableViewCell" bundle:nil] forCellReuseIdentifier:StudentSelectorTableViewCellId];
}

- (void)showSelectView{
    
    [self.segmentControl mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.customTitleView);
        make.top.mas_equalTo(self.customTitleView.mas_top).offset(20);
    }];
    self.frame = [UIScreen mainScreen].bounds;
    [[UIApplication sharedApplication].keyWindow addSubview:self];
}

#pragma mark - IBActions
- (IBAction)backButtonPressed:(id)sender {
    
    if (self.superview) {
        [self removeFromSuperview];
    }
    if (self.cancelBack) {
        self.cancelBack();
    }
}

- (IBAction)sendButtonPressed:(id)sender {

    if (self.selectBack) {
       
        self.selectBack((NSArray<Clazz *> *)self.selectedClasses, (NSArray<User *> *)self.selectedStudents);
    }
    
    if (self.superview) {
       
        [self removeFromSuperview];
    }
}

- (void)showChildPageViewControllerWithIndex:(NSUInteger)index animated:(BOOL)animated shouldLocate:(BOOL)shouldLocate {

    self.sendButton.enabled = ((self.selectedClasses.count + self.selectedStudents.count) > 0) ? YES : NO;
    if (shouldLocate) {
      
        CGPoint offset = CGPointMake(index*self.screenWidth, 0);
        if (animated) {
            self.ignoreScrollCallback = YES;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 [self.containerScrollView setContentOffset:offset];
                             } completion:^(BOOL finished) {
                                 self.ignoreScrollCallback = NO;
                             }];
        } else {
            // 说明：不使用dispatch_async的话viewDidLoad中直接调用[self.containerScrollView setContentOffset:offset];
            // 会导致contentoffset并未设置的问题
            dispatch_async(dispatch_get_main_queue(), ^{
                self.ignoreScrollCallback = YES;
                [self.containerScrollView setContentOffset:offset];
                self.ignoreScrollCallback = NO;
            });
        }
    }
}

- (void)updateSegmentControlWithOffsetX:(CGFloat)x {
    
    [self.segmentControl setPersent:x / self.screenWidth];
}

- (void)updateSegmentControlWhenScrollEnded {
    
    [self.segmentControl setPersent:self.containerScrollView.contentOffset.x / self.screenWidth];
    NSInteger index = MAX(0, ceil(2 * self.containerScrollView.contentOffset.x / self.screenWidth) - 1);
    [self indexDidChange:index];
}

- (void)indexDidChange:(NSInteger)index {
    
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    if (self.ignoreScrollCallback) {
        return;
    }
    CGFloat offsetX = self.containerScrollView.contentOffset.x;
    
    NSUInteger leftIndex = (NSInteger)MAX(0, offsetX)/(NSInteger)(self.screenWidth);
    NSUInteger rightIndex = (NSInteger)MAX(0, offsetX+self.screenWidth)/(NSInteger)(self.screenWidth);
    
    [self showChildPageViewControllerWithIndex:leftIndex animated:NO shouldLocate:NO];
    if (leftIndex != rightIndex) {
        [self showChildPageViewControllerWithIndex:rightIndex animated:NO shouldLocate:NO];
    }
    [self updateSegmentControlWithOffsetX:offsetX];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.ignoreScrollCallback) {
        return;
    }
    if (!decelerate) {
        [self updateSegmentControlWhenScrollEnded];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.ignoreScrollCallback) {
        return;
    }
    
    [self updateSegmentControlWhenScrollEnded];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (self.ignoreScrollCallback) {
        return;
    }
    
    [self updateSegmentControlWhenScrollEnded];
}


#pragma mark - UITableViewDataSource  UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   
    if (tableView == self.classTableView) {
        NSString *key = self.classtSortedKeys[section];
        NSArray *group = self.classDict[key];
        return group.count;
    } else {
        NSString *key = self.studentSortedKeys[section];
        NSArray *group = self.studentDict[key];
        return group.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == self.classTableView) {
        return ClassSelectorTableViewCellHeight;
    } else {
        return StudentSelectorTableViewCellHeight;
    } ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 
    if (tableView == self.classTableView) {
       
        NSString *key = self.classtSortedKeys[indexPath.section];
        NSArray *group = self.classDict[key];
        Clazz *clazz = group[indexPath.row];
        
        ClassSelectorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ClassSelectorTableViewCellId forIndexPath:indexPath];
        [cell setupWithClazz:clazz];
        [cell setChoice:[self.selectedClasses containsObject:clazz]];
        return cell;
    } else {
       
        NSString *key = self.studentSortedKeys[indexPath.section];
        NSArray *group = self.studentDict[key];
        User *student = group[indexPath.row];
        
        StudentSelectorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:StudentSelectorTableViewCellId forIndexPath:indexPath];
        [cell setupWithStudent:student];
        [cell setChoice:[self.selectedStudents containsObject:student]];
        [cell setReviewMode:NO];
        return cell;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  
    if (tableView == self.studentTableView) {
        return self.studentSortedKeys[section];
    } else {
        return self.classtSortedKeys[section];
    }
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    
    if (tableView == self.studentTableView) {
        return self.studentSortedKeys;
    } else {
        return self.classtSortedKeys;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (tableView == self.studentTableView) {
        return [self.studentSortedKeys indexOfObject:title];
    } else {
        return [self.classtSortedKeys indexOfObject:title];;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
   
    if (tableView == self.studentTableView) {
        return self.studentDict.count;
    } else {
        return self.classDict.count;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
 
    if (tableView == self.classTableView) {
       
        if (self.selectedStudents.count) {
            
            [self.selectedStudents removeAllObjects];
            [self.studentTableView reloadData];
        }
        NSString *key = self.classtSortedKeys[indexPath.section];
        Clazz *clazz = self.classDict[key][indexPath.row];
        ClassSelectorTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if ([self.selectedClasses containsObject:clazz]) {
            [self.selectedClasses removeObject:clazz];
            [cell setChoice:NO];
        } else {
            [self.selectedClasses addObject:clazz];
            [cell setChoice:YES];
        }
    } else {
      
        if (self.selectedClasses.count) {
           
            [self.selectedClasses removeAllObjects];
            [self.classTableView reloadData];
        }
       
        NSString *key = self.studentSortedKeys[indexPath.section];
        User *student = self.studentDict[key][indexPath.row];
    
        StudentSelectorTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if ([self.selectedStudents containsObject:student]) {
            [self.selectedStudents removeObject:student];
            [cell setChoice:NO];
        } else {
            [self.selectedStudents addObject:student];
            [cell setChoice:YES];
        }
    }
    self.sendButton.enabled = ((self.selectedClasses.count + self.selectedStudents.count) > 0) ? YES : NO;
}

#pragma mark - 请求班级列表 && 学生列表
- (void)requestClasses {
    WeakifySelf;
    [ClassService requestNewClassesWithFinishState:0
                                     campusName:nil
                                       callback:^(Result *result, NSError *error) {
                                           StrongifySelf;
                                           [strongSelf handleClassRequestResult:result error:error];
                                       }];
}


- (void)handleClassRequestResult:(Result *)result error:(NSError *)error {

    NSDictionary *dictionary = (NSDictionary *)(result.userInfo);
    NSArray *classes = dictionary[@"list"];
  
    // 停止加载
    if (error != nil) {
        if (classes.count > 0) {
            [TIP showText:@"加载失败" inView:self.classTableView];
        } else {
            WeakifySelf;
            [self.classTableView showFailureViewWithRetryCallback:^{
                [weakSelf requestClasses];
            }];
        }
        return;
    }
    
    if (classes.count > 0) {
        
        [self.classes addObjectsFromArray:classes];
        [self sortClasses];
        [self.classTableView reloadData];
    } else {
        [self.classTableView showEmptyViewWithImage:nil
                                              title:@"暂无班级"
                                      centerYOffset:0
                                          linkTitle:nil
                                  linkClickCallback:nil];
    }
}

- (void)requestStudents {

    self.studentTableView.hidden = YES;
    WeakifySelf;
    [StudentService requestStudentsWithClassState:1
                                         callback:^(Result *result, NSError *error) {
                                             StrongifySelf;
                                             [strongSelf handleStudentRequestResult:result error:error];
                                         }];
    
}
- (void)sortClasses {
 
    HanyuPinyinOutputFormat *outputFormat=[[HanyuPinyinOutputFormat alloc] init];
    [outputFormat setToneType:ToneTypeWithoutTone];
    [outputFormat setVCharType:VCharTypeWithV];
    [outputFormat setCaseType:CaseTypeUppercase];
    [self.classes enumerateObjectsUsingBlock:^(Clazz * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *pinyin = [[PinyinHelper toHanyuPinyinStringWithNSString:obj.name withHanyuPinyinOutputFormat:outputFormat withNSString:@" "] uppercaseString];
        obj.pinyinName = pinyin;
        
    }];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pinyinName" ascending:YES];
    NSArray *array = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [self.classes sortUsingDescriptors:array];
    
    
    for (Clazz *clazz in self.classes) {
        NSString *strFirstLetter = [clazz.pinyinName substringToIndex:1];
        if (self.classDict[strFirstLetter] != nil) {
            [self.classDict[strFirstLetter] addObject:clazz];
        } else {
            NSMutableArray *group = [NSMutableArray arrayWithObject:clazz];
            [self.classDict setObject:group forKey:strFirstLetter];
        }
    }
    NSArray *keys = [self.classDict.allKeys sortedArrayUsingSelector:@selector(compare:)];
    self.classtSortedKeys = keys;
}

- (void)handleStudentRequestResult:(Result *)result error:(NSError *)error {

    if (error != nil) {
        WeakifySelf;
        [self.studentTableView showFailureViewWithRetryCallback:^{
            [weakSelf requestStudents];
        }];
        return;
    }
    
    NSDictionary *dict = (NSDictionary *)(result.userInfo);
    NSArray *students = (NSArray *)(dict[@"list"]);
    
    // 停止加载
    if (students.count > 0) {
        self.studentTableView.hidden = NO;
        [self.students addObjectsFromArray:students];
        [self sortStudents];
        [self.studentTableView reloadData];
    } else {
        [self.studentTableView showEmptyViewWithImage:nil
                                    title:@"暂无学生"
                            centerYOffset:0
                                linkTitle:nil
                        linkClickCallback:nil];
    }
}

- (void)sortStudents {
  
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
       
        if (student.pinyinName.length >= 1) {

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
    self.studentSortedKeys = keys;
}

@end
