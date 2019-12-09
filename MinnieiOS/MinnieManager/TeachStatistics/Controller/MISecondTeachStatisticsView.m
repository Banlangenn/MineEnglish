//
//  MISecondTeachStatisticsView.m
//  MinnieManager
//
//  Created by songzhen on 2019/7/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "MISecondTeachStatisticsView.h"

#import "Result.h"
#import "PinyinHelper.h"
#import "StudentService.h"
#import "SegmentControl.h"
#import "HanyuPinyinOutputFormat.h"
#import "MISecondReaTimeTaskTableViewCell.h"

@interface MISecondTeachStatisticsView ()<
UIScrollViewDelegate,
UITableViewDelegate,
UITableViewDataSource
>
// 当前选中
@property (nonatomic,strong) NSIndexPath *currentIndexPath;

// 学生
@property (nonatomic,strong) NSArray *sortedKeys;
@property (nonatomic,strong) NSMutableArray *students;
@property (nonatomic,strong) NSMutableDictionary *studentDict;


// 班级列表
@property (nonatomic,strong) NSMutableArray *classes;
@property (nonatomic,strong) NSMutableArray *classNames;
@property (nonatomic,strong) NSMutableDictionary *classDict;
//@property (nonatomic,strong) NSArray *sortedClassKeys;


@property (nonatomic,strong) UIButton *addActivitybtn;

// 0 按名字 1 按班级
@property (nonatomic, assign) NSInteger studentListType;

@property (nonatomic, strong) SegmentControl *segmentControl;
@property (nonatomic, strong) UIScrollView *containerScrollView;

@property (nonatomic, strong) UITableView *leftTableView;
@property (nonatomic, strong) UITableView *rightTableView;


@property (nonatomic, assign) BOOL ignoreScrollCallback;

@end

@implementation MISecondTeachStatisticsView


- (instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
       
        self.students = [NSMutableArray array];
        self.classes = [NSMutableArray array];
        self.classNames = [NSMutableArray array];
        [self configureUI];
    }
    return self;
}

- (void)configureUI{
    
    self.backgroundColor = [UIColor whiteColor];
    self.segmentControl = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SegmentControl class]) owner:nil options:nil] lastObject];
    self.segmentControl.titles = @[@"按名字", @"按班级"];
    self.segmentControl.selectedIndex = 0;
    __weak typeof(self) weakSelf = self;
    self.segmentControl.indexChangeHandler = ^(NSUInteger selectedIndex) {
        [weakSelf showChildPageViewWithIndex:selectedIndex animated:YES shouldLocate:YES];
    };
    [self addSubview:self.segmentControl];
    
    
    _containerScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, kColumnSecondWidth, ScreenHeight - 64)];
    _containerScrollView.pagingEnabled = YES;
    _containerScrollView.showsHorizontalScrollIndicator = NO;
    _containerScrollView.contentSize = CGSizeMake(kColumnSecondWidth * 2, 200);
    _containerScrollView.delegate = self;
    [self addSubview:_containerScrollView];
    
    _leftTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kColumnSecondWidth, ScreenHeight - 64)style:UITableViewStylePlain];
    _leftTableView.delegate = self;
    _leftTableView.dataSource = self;
    [self.containerScrollView addSubview:_leftTableView];
    _leftTableView.separatorColor = [UIColor separatorLineColor];
    _leftTableView.tableFooterView = [UIView new];
    _leftTableView.cellLayoutMarginsFollowReadableWidth = NO;
    
    _rightTableView = [[UITableView alloc] initWithFrame:CGRectMake(kColumnSecondWidth, 0, kColumnSecondWidth, ScreenHeight - 64)style:UITableViewStylePlain];
    _rightTableView.delegate = self;
    _rightTableView.dataSource = self;
    [self.containerScrollView addSubview:_rightTableView];
    _rightTableView.separatorColor = [UIColor separatorLineColor];
    _rightTableView.tableFooterView = [UIView new];
    _rightTableView.cellLayoutMarginsFollowReadableWidth = NO;
    [_rightTableView reloadData];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(kColumnSecondWidth - 0.5, 0, 0.5, [UIScreen mainScreen].bounds.size.height)];
    lineView.backgroundColor = [UIColor separatorLineColor];
    [self addSubview:lineView];
    
    [self.segmentControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@20);
        make.height.equalTo(@44);
        make.centerX.equalTo(self.mas_centerX);
        make.width.mas_equalTo(kColumnSecondWidth);
    }];
}

- (void)showChildPageViewWithIndex:(NSUInteger)index animated:(BOOL)animated shouldLocate:(BOOL)shouldLocate {
    
    self.currentIndexPath = nil;
    
    if (shouldLocate) {
        
        CGPoint offset = CGPointMake(index*kColumnSecondWidth, 0);
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
    if (index == 0 && self.students.count == 0) {
        [self requestStudents];
    }
    if (index == 1 && self.classes.count == 0) {
        [self requestStudentLisByClasst];
    }
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  
    if (self.ignoreScrollCallback) {
        return;
    }
    if ([scrollView isKindOfClass:[UITableView class]]) {
        return;
    }
    
    CGFloat offsetX = scrollView.contentOffset.x;
    NSUInteger leftIndex = (NSInteger)MAX(0, offsetX)/(NSInteger)(kColumnSecondWidth);
    NSUInteger rightIndex = (NSInteger)MAX(0, offsetX+kColumnSecondWidth)/(NSInteger)(kColumnSecondWidth);
    if (rightIndex >= 2) {
        rightIndex = 1;
    }
    
    [self showChildPageViewWithIndex:leftIndex animated:NO shouldLocate:NO];
    if (leftIndex != rightIndex) {
        [self showChildPageViewWithIndex:rightIndex animated:NO shouldLocate:NO];
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

- (void)updateSegmentControlWhenScrollEnded {
    [self.segmentControl setPersent:self.containerScrollView.contentOffset.x / kColumnSecondWidth];
}

- (void)updateSegmentControlWithOffsetX:(CGFloat)x {
    [self.segmentControl setPersent:x / kColumnSecondWidth];
}

#pragma mark - 更新
- (void)updateStudentList{
    
    self.currentIndexPath = nil;
    
    if (self.segmentControl.selectedIndex == 0) {
        [self.rightTableView reloadData];
        [self requestStudents];
    } else {
        [self requestStudentLisByClasst];
        [self.leftTableView reloadData];
    }
}

#pragma mark -
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  
    if (tableView == self.leftTableView) {
        
        return self.sortedKeys.count;
    } else {
        return self.classes.count;
    }
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (tableView == self.leftTableView) {
        
        NSArray *studentsGroup = self.studentDict[self.sortedKeys[section]];
        return studentsGroup.count;
    } else {
        
        StudentsByClass * clazz= self.classes[section];
        return clazz.students.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
  
    return MISecondReaTimeTaskTableViewCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MISecondReaTimeTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MISecondReaTimeTaskTableViewCellId];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MISecondReaTimeTaskTableViewCell class]) owner:nil options:nil] lastObject];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
   
    User *student ;
    if (tableView == self.leftTableView) {
        
        NSArray *studentsGroup = self.studentDict[self.sortedKeys[indexPath.section]];
        student = studentsGroup[indexPath.row];
    } else {
        
        StudentsByClass * clazz= self.classes[indexPath.section];
        
//        [self.classDict setObject:obj forKey:[NSString stringWithFormat:@"%lu",clazz.classId]];
        student = clazz.students[indexPath.row];
    }
    if (self.currentIndexPath == nil) {
        [cell setupTitle:student.nickname icon:student.avatarUrl selectState:NO];
    } else {
        if (self.currentIndexPath.row == indexPath.row && self.currentIndexPath.section == indexPath.section) {
            [cell setupTitle:student.nickname icon:student.avatarUrl selectState:YES];
        } else {
            [cell setupTitle:student.nickname icon:student.avatarUrl selectState:NO];
        }
    }
    return cell;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView{
   
    if (tableView == self.leftTableView) {
        
        return self.sortedKeys;
    } else {
        return nil;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
 
    UIView *headerView =  [[UIView alloc] init];
    headerView.backgroundColor = [UIColor unSelectedColor];
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, kColumnSecondWidth - 40,30)];
    timeLabel.textAlignment = NSTextAlignmentLeft;
    timeLabel.font = [UIFont boldSystemFontOfSize:14];
    timeLabel.textColor = [UIColor normalColor];
    [headerView addSubview:timeLabel];
   
    if (tableView == self.leftTableView) {
       
        timeLabel.text = self.sortedKeys[section];
    } else {
        
        if (section < self.classes.count) {
            
            StudentsByClass * clazz= self.classes[section];
            timeLabel.text = clazz.className;
        }
    }
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.currentIndexPath = indexPath;
    [tableView reloadData];
    
    Student *student;
    if (tableView == self.leftTableView) {
        
        NSArray *studentsGroup = self.studentDict[self.sortedKeys[indexPath.section]];
        student = studentsGroup[indexPath.row];
    } else {
        
        StudentsByClass * clazz= self.classes[indexPath.section];
        student = clazz.students[indexPath.row];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(secondTeachStatisticsViewDidClicledWithStudent:)]) {
        
        [self.delegate secondTeachStatisticsViewDidClicledWithStudent:student];
    }
}

#pragma mark - 请求学生列表 按名字
- (void)requestStudents {

    if (self.students.count + self.classes.count == 0) {
       
        [self showLoadingView];
        self.leftTableView.hidden = YES;
    }
    WeakifySelf;
    [StudentService requestStudentsByTeacherCallback:^(Result *result, NSError *error) {
        
        StrongifySelf;
        [strongSelf handleRequestResult:result error:error];
    }];
}

- (void)handleRequestResult:(Result *)result error:(NSError *)error {

    [self hideAllStateView];
    if (error != nil) {
        WeakifySelf;
        if (self.students.count == 0) {
         
            [self showFailureViewWithRetryCallback:^{
                [weakSelf requestStudents];
            }];
        }
        return;
    }
    
    NSDictionary *dict = (NSDictionary *)(result.userInfo);
    NSArray *students = (NSArray *)(dict[@"list"]);
    
    // 停止加载
    self.leftTableView.hidden = students.count==0;
    
    if (students.count > 0) {
        self.leftTableView.hidden = NO;
        [self.students removeAllObjects];
        [self.students addObjectsFromArray:students];
        [self sortStudents];
        [self.leftTableView reloadData];
    } else {
        [self showEmptyViewWithImage:nil
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
   
    [self.studentDict removeAllObjects];
    for (User *student in self.students) {
        NSString *strFirstLetter = [student.pinyinName substringToIndex:1];
        if (self.studentDict[strFirstLetter] != nil) {
            [self.studentDict[strFirstLetter] addObject:student];
        } else {
            NSMutableArray *group = [NSMutableArray arrayWithObject:student];
            [self.studentDict setObject:group forKey:strFirstLetter];
        }
    }
    
    NSArray *keys = [self.studentDict.allKeys sortedArrayUsingSelector:@selector(compare:)];
    self.sortedKeys = keys;
}

#pragma mark - 请求学生列表 按班级
- (void)requestStudentLisByClasst{
   
    if (self.students.count + self.classes.count == 0) {
        [self showLoadingView];
        self.rightTableView.hidden = YES;
    }
    WeakifySelf;
    [StudentService requestStudentLisByClasstWithCallback:^(Result *result, NSError *error) {
      
        [weakSelf hideAllStateView];
        if (error != nil) {
            if (weakSelf.classes.count == 0) {
                [weakSelf showFailureViewWithRetryCallback:^{
                    [weakSelf requestStudentLisByClasst];
                }];
            }
            return;
        }
        NSDictionary *dict = (NSDictionary *)result.userInfo;
        NSArray *classes = dict[@"list"];
        if (classes.count > 0) {
            
            weakSelf.rightTableView.hidden = NO;
            [weakSelf.classes removeAllObjects];
            [weakSelf.classes addObjectsFromArray:classes];
            [weakSelf sortStudentsByClass];
        } else {
            [weakSelf showEmptyViewWithImage:nil
                                   title:@"暂无学生"
                           centerYOffset:0
                               linkTitle:nil
                       linkClickCallback:nil];
        }
    }];
}
- (void)sortStudentsByClass {
 
    HanyuPinyinOutputFormat *outputFormat=[[HanyuPinyinOutputFormat alloc] init];
    [outputFormat setToneType:ToneTypeWithoutTone];
    [outputFormat setVCharType:VCharTypeWithV];
    [outputFormat setCaseType:CaseTypeUppercase];
    [self.classNames removeAllObjects];
    if (self.classDict == nil) {
        self.classDict = [NSMutableDictionary dictionary];
    }
    [self.classDict removeAllObjects];
    
    WeakifySelf;
    [self.classes enumerateObjectsUsingBlock:^(StudentsByClass * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *pinyin = [[PinyinHelper toHanyuPinyinStringWithNSString:obj.className withHanyuPinyinOutputFormat:outputFormat withNSString:@" "] uppercaseString];
        obj.pinyinName = pinyin;
        [weakSelf.classNames addObject:obj];
        [self.classDict setObject:obj forKey:[NSString stringWithFormat:@"%lu",obj.classId]];
    }];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pinyinName" ascending:YES];
    NSArray *array = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [self.classes sortUsingDescriptors:array];
    
    [self.rightTableView reloadData];
}
@end
