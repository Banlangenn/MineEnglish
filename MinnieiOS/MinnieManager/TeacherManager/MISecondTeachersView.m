//
//  MISecondTeachersView.m
//  MinnieManager
//
//  Created by songzhen on 2019/7/9.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "Result.h"
#import "PinyinHelper.h"
#import "TeacherService.h"
#import "MISecondTeachersView.h"
#import "HanyuPinyinOutputFormat.h"
//#import "TeacherEditViewController.h"
#import "MITeacherAuthorViewController.h"
#import "MISecondReaTimeTaskTableViewCell.h"

@interface MISecondTeachersView ()<
UITableViewDelegate,
UITableViewDataSource
>
// 当前选中
@property (nonatomic,strong) NSIndexPath *currentIndexPath;

@property (nonatomic,strong) UITableView *tableView;
// 教师
@property (nonatomic,strong) NSMutableArray *teachersArray;

@property (nonatomic,strong) NSMutableDictionary *teachersDict;

@property (nonatomic,strong) NSArray *teacherSortedKeys;


@property (nonatomic,strong) UIButton *addActivitybtn;

// 0 实时任务 1教师管理
@property (nonatomic,assign) NSInteger teacherListType;


@end

@implementation MISecondTeachersView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _teachersArray = [NSMutableArray array];
        _teachersDict = [NSMutableDictionary dictionary];
        [self configureUI];
    }
    return self;
}

- (void)configureUI{
    
    _addActivitybtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_addActivitybtn setTitle:@"创建" forState:UIControlStateNormal];
    _addActivitybtn.titleLabel.font = [UIFont systemFontOfSize:14];
    _addActivitybtn.hidden = YES;
    [_addActivitybtn setTitleColor:[UIColor mainColor] forState:UIControlStateNormal];
    
    [_addActivitybtn addTarget:self action:@selector(addTeacherBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_addActivitybtn];
    _addActivitybtn.frame = CGRectMake(10, kNaviBarHeight - 35, 80, 28);
    _addActivitybtn.layer.borderColor = [UIColor mainColor].CGColor;
    _addActivitybtn.layer.borderWidth = 0.5;
    _addActivitybtn.layer.cornerRadius = 4.0;
    _addActivitybtn.layer.masksToBounds = YES;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, kNaviBarHeight, self.frame.size.width, self.frame.size.height - kNaviBarHeight)style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self addSubview:_tableView];
    _tableView.separatorColor = [UIColor separatorLineColor];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(kColumnSecondWidth - 0.5, 0, 0.5, [UIScreen mainScreen].bounds.size.height)];
    lineView.backgroundColor = [UIColor separatorLineColor];
    [self addSubview:lineView];
    
    _tableView.tableFooterView = [UIView new];
    _tableView.cellLayoutMarginsFollowReadableWidth = NO;
    
}

- (void)addTeacherBtnClicked:(UIButton *)btn{
    
    MITeacherAuthorViewController *editVC = [[MITeacherAuthorViewController alloc] initWithNibName:@"MITeacherAuthorViewController" bundle:nil];

    UIView *bgView = [Utils viewOfVCAddToWindowWithVC:editVC width:375.0];
    editVC.closeViewCallBack = ^{
        if (bgView.superview) {
            [bgView removeFromSuperview];
        }
    };
}

- (void)updateTeacherListWithListType:(NSInteger)listType resetIndex:(BOOL)reset{
    
    self.teacherListType = listType;
    if (reset) {
        self.currentIndexPath = nil;
    }
    [self requestTeachers];
    
    self.addActivitybtn.hidden = (self.teacherListType == 0) ? YES : NO;
    
    if (self.teacherListType == 0) {
        
        self.addActivitybtn.hidden = YES;
    } else {
        if (APP.currentUser.authority == TeacherAuthoritySuperManager) {
            self.addActivitybtn.hidden = NO;
        } else {
            self.addActivitybtn.hidden = !APP.currentUser.canManageTeachers;
        }
    }
}

#pragma mark -
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.teacherSortedKeys.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSArray *teachersGroup = self.teachersDict[self.teacherSortedKeys[section]];
    return teachersGroup.count;
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
    NSArray *teachersGroup = self.teachersDict[self.teacherSortedKeys[indexPath.section]];
    Teacher *teacher = teachersGroup[indexPath.row];
    
    if (self.currentIndexPath == nil) {
        [cell setupTitle:teacher.nickname icon:teacher.avatarUrl selectState:NO];
    } else {
        if (self.currentIndexPath.row == indexPath.row && self.currentIndexPath.section == indexPath.section) {
            [cell setupTitle:teacher.nickname icon:teacher.avatarUrl selectState:YES];
        } else {
            [cell setupTitle:teacher.nickname icon:teacher.avatarUrl selectState:NO];
        }
    }
    return cell;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    return self.teacherSortedKeys;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return self.teacherSortedKeys[section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.currentIndexPath = indexPath;
    [tableView reloadData];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(secondTeaManViewDidClicledWithTeacher:listType:)]) {
        
        NSArray *teachersGroup = self.teachersDict[self.teacherSortedKeys[indexPath.section]];
        Teacher *teacher = teachersGroup[indexPath.row];
        [self.delegate secondTeaManViewDidClicledWithTeacher:teacher listType:self.teacherListType];
    }
}

- (void)requestTeachers{
    
    WeakifySelf;
    if (self.teachersArray.count == 0) {
        self.tableView.hidden = YES;
        [self showLoadingView];
    }
    [TeacherService requestTeachersWithCallback:^(Result *result, NSError *error) {
        StrongifySelf;
        if (error != nil) {
            if (strongSelf.teachersArray.count == 0) {
               
                [strongSelf showFailureViewWithRetryCallback:^{
                    [strongSelf requestTeachers];
                }];
            }
            return;
        }
        
        NSDictionary *dict = (NSDictionary *)(result.userInfo);
        NSArray *teachers = (NSArray *)(dict[@"list"]);
        if (teachers.count == 0) {
            [strongSelf showEmptyViewWithImage:nil
                                         title:@"暂无教师"
                                     linkTitle:nil
                             linkClickCallback:nil];
        } else {
            [strongSelf hideAllStateView];
            
            if (strongSelf.teachersArray == nil) {
                strongSelf.teachersArray = [NSMutableArray array];
            }
            [strongSelf.teachersArray removeAllObjects];
            [strongSelf.teachersArray addObjectsFromArray:teachers];
            [strongSelf sortTeachers];
            strongSelf.tableView.hidden = NO;
            [strongSelf.tableView reloadData];
        }
    }];
}


- (void)sortTeachers {
    
    HanyuPinyinOutputFormat *outputFormat=[[HanyuPinyinOutputFormat alloc] init];
    [outputFormat setToneType:ToneTypeWithoutTone];
    [outputFormat setVCharType:VCharTypeWithV];
    [outputFormat setCaseType:CaseTypeUppercase];
    [self.teachersArray enumerateObjectsUsingBlock:^(User * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *pinyin = [[PinyinHelper toHanyuPinyinStringWithNSString:obj.nickname withHanyuPinyinOutputFormat:outputFormat withNSString:@" "] uppercaseString];
        obj.pinyinName = pinyin;
    }];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pinyinName" ascending:YES];
    NSArray *array = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [self.teachersArray sortUsingDescriptors:array];
    
    [self.teachersDict removeAllObjects];
    for (User *student in self.teachersArray) {
        
        if (student.pinyinName.length >= 1) {
        
            NSString *strFirstLetter = [student.pinyinName substringToIndex:1];
            if (self.teachersDict[strFirstLetter] != nil) {
                [self.teachersDict[strFirstLetter] addObject:student];
            } else {
                NSMutableArray *group = [NSMutableArray arrayWithObject:student];
                [self.teachersDict setObject:group forKey:strFirstLetter];
            }
        }
    }
    NSArray *keys = [self.teachersDict.allKeys sortedArrayUsingSelector:@selector(compare:)];
    self.teacherSortedKeys = keys;
}
@end
