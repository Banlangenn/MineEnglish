//
//  MITeacherDetailViewController.m
//  MinnieManager
//
//  Created by songzhen on 2019/7/10.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "TeacherService.h"
#import "MIScoreListViewController.h"
//#import "TeacherEditViewController.h"
#import "MITeacherAuthorViewController.h"
#import "MITeacherOnlineTableViewCell.h"
#import "MITeacherDetailViewController.h"

@interface MITeacherDetailViewController ()<
UITableViewDelegate,
UITableViewDataSource
>
@property (weak, nonatomic) IBOutlet UIImageView *iconImageV;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *setButton;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *rightLineView;

@property (weak, nonatomic) IBOutlet UIButton *onlineButton;

@property (nonatomic,strong) Teacher *teacher;
@property (nonatomic,strong) TeacherDetail *teacherDetail;

@property (nonatomic,strong) NSArray *titleArray;

@property (nonatomic,assign) NSInteger currentIndex;

@end

@implementation MITeacherDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    
    self.currentIndex = -1;
    self.iconImageV.layer.masksToBounds = YES;
    self.iconImageV.layer.cornerRadius = 12.0;
    
    self.setButton.layer.masksToBounds = YES;
    self.setButton.layer.cornerRadius = 4.0;
    self.setButton.layer.borderWidth = 1.0;
    self.setButton.layer.borderColor = [UIColor mainColor].CGColor;
    
    self.onlineButton.layer.cornerRadius = 4.0;
    self.onlineButton.backgroundColor = [UIColor detailColor];
    self.onlineButton.selected = NO;
    
    self.titleArray = @[@"在线时长",@"任务批改总览",@"上课班级",@"任务评分统计"];
    
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // 教师批改作业
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadWhenHomeworkCorrected:)
                                                 name:kNotificationKeyOfCorrectHomework
                                               object:nil];
}


- (void)reloadWhenHomeworkCorrected:(NSNotification *)notification {
    
    [self resetCurrentSelectIndex];
}

- (void)updateTeacher:(Teacher *_Nullable)teacher{
   
    self.teacher = teacher;
    if (teacher == nil) {
        
        self.headerView.hidden = YES;
        self.rightLineView.hidden = YES;
        self.tableView.hidden = YES;
        self.view.backgroundColor = [UIColor emptyBgColor];
    } else {
        
        self.headerView.hidden = NO;
        self.tableView.hidden = NO;
        self.rightLineView.hidden = NO;
        self.view.backgroundColor = [UIColor whiteColor];
        self.tableView.backgroundColor = [UIColor whiteColor];
        
        self.nameLabel.text = self.teacher.nickname;
        [self.iconImageV sd_setImageWithURL:[self.teacher.avatarUrl imageURLWithWidth:24] placeholderImage:[UIImage imageNamed: @"attachment_placeholder"]];
        [self setupEditTeacherBtn];
        [self resetCurrentSelectIndex];
        // 请求用户信息
        [self requestTeacherDetail];
    }
}

- (void)setupEditTeacherBtn{
    
    // 超级管理拥有所有权限
    if (APP.currentUser.authority == TeacherAuthoritySuperManager) {
        
        self.setButton.hidden = NO;
    } else if (APP.currentUser.authority == TeacherAuthorityManager) {
       
        // 管理员无法编辑超级管理员、管理员
        if ( self.teacher.authority == TeacherAuthorityManager ||
            self.teacher.authority == TeacherAuthoritySuperManager
            ) {
            
            self.setButton.hidden = YES;
        } else {
            // 普通教师
            self.setButton.hidden = !APP.currentUser.canManageTeachers;
        }
    } else {
        self.setButton.hidden = YES;
    }
}

- (void)resetCurrentSelectIndex{
    self.currentIndex = -1;
    [self.tableView reloadData];
}

- (IBAction)setAction:(id)sender {
    
    
    MITeacherAuthorViewController *editVC = [[MITeacherAuthorViewController alloc] initWithNibName:@"MITeacherAuthorViewController" bundle:nil];
    
    editVC.teacher = self.teacher;

    UIView *bgView = [Utils viewOfVCAddToWindowWithVC:editVC width:375.0];
    WeakifySelf;
    editVC.closeViewCallBack = ^{
        if (bgView.superview) {
            [bgView removeFromSuperview];
        }
    };
    editVC.editSuccessCallBack = ^(BOOL isDelete, Teacher * _Nonnull newTeacher) {
      
        if (!isDelete) {// 更新教师
            weakSelf.teacher = newTeacher;
        }
        if (bgView.superview) {
            [bgView removeFromSuperview];
        }
        if (weakSelf.editSuccessCallBack) {
            weakSelf.editSuccessCallBack(isDelete);
        }
    };
}

#pragma mark -   UITableViewDelegate,UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 3;
    } else if (section == 2) {
        return self.teacherDetail.onClassList.count;
    } else {
        return self.teacherDetail.onHomeworkList.count;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        return MITeacherOnlineTableViewCellHeight;
    } else if (indexPath.section == 1) {
        return 30;
    } else if (indexPath.section == 2) {
        return 44;
    } else {
        return 44;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        
        MITeacherOnlineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MITeacherOnlineTableViewCellId];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MITeacherOnlineTableViewCell class]) owner:nil options:nil] lastObject];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [cell setupTimeWithTeacher:self.teacherDetail];
        return cell;
    } else if (indexPath.section == 1) {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"teacherDetailCellId"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"studentDetailCellId"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (indexPath.row == 0) {
            cell.textLabel.attributedText = [self setupContentTitle:@"待批改数：" text:[NSString stringWithFormat:@"%lu",self.teacherDetail.uncorrectedHomeworksCount]];
        } else if (indexPath.row == 1) {
            cell.textLabel.attributedText = [self setupContentTitle:@"未提交数：" text:[NSString stringWithFormat:@"%lu",self.teacherDetail.uncommitedHomeworksCount]];
        } else {
            if (self.teacherDetail.correctedHomeworksDetail.count >= 3) {
                
                cell.textLabel.attributedText = [self setupContentTitle:@"已批次数：" text:[NSString stringWithFormat:@"今日%@/本周%@/本月%@",self.teacherDetail.correctedHomeworksDetail[0],self.teacherDetail.correctedHomeworksDetail[1],self.teacherDetail.correctedHomeworksDetail[2]]];
            } else {
                 cell.textLabel.attributedText = [self setupContentTitle:@"已批次数：" text:@""];
            }
        }
        return cell;
    } else {
        
        if (indexPath.section == 2) { // 上课班级
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"onClassCellId"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cellId"];
                cell.textLabel.font = [UIFont systemFontOfSize:14];
                cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.textColor = [UIColor normalColor];
                cell.detailTextLabel.textColor = [UIColor detailColor];
                cell.accessoryView = [UIView new];
            }
            OnClass *classDetail = self.teacherDetail.onClassList[indexPath.row];
            cell.textLabel.text = classDetail.name;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu人",classDetail.studentCount];
            
            return cell;
        } else {// 任务评分统计
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"onHomeworkCellId"];
            
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cellId"];
                cell.textLabel.font = [UIFont systemFontOfSize:14];
                cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.textColor = [UIColor normalColor];
                cell.detailTextLabel.textColor = [UIColor detailColor];
                UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 43.5, kColumnThreeWidth, 0.5)];
                lineView.backgroundColor = [UIColor separatorLineColor];
                [cell addSubview:lineView];
                
                UIView *rightLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3.0, 44)];
                rightLineView.backgroundColor = [UIColor mainColor];
                cell.accessoryView = rightLineView;
            }
            OnHomework *taskDetail = self.teacherDetail.onHomeworkList[indexPath.row];
            cell.textLabel.text = taskDetail.title;
            cell.detailTextLabel.text =[NSString stringWithFormat:@"%.1f/%lu星",taskDetail.avgScore,(long)taskDetail.level];
            if (self.currentIndex == indexPath.row) {
                
                cell.accessoryView.hidden  = NO;
                cell.backgroundColor = [UIColor selectedColor];
            } else {
                cell.accessoryView.hidden  = YES;
                cell.backgroundColor = [UIColor whiteColor];
            }
            return cell;
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView *headerView =  [[UIView alloc] init];
    headerView.backgroundColor = [UIColor whiteColor];
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, kColumnThreeWidth - 40, 40)];
    timeLabel.textAlignment = NSTextAlignmentLeft;
    timeLabel.font = [UIFont boldSystemFontOfSize:16];
    timeLabel.textColor = [UIColor normalColor];
    [headerView addSubview:timeLabel];

    timeLabel.text = self.titleArray[section];
    return headerView;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 40;
}


- (NSAttributedString *)setupContentTitle:(NSString *)title text:(NSString *)text{
    if (text.length == 0) {
        text = @"";
    }
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",title,text]];
    [attStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14],
                            NSForegroundColorAttributeName: [UIColor normalColor]}
                    range:NSMakeRange(0, title.length)];
    [attStr setAttributes:@{
                            NSFontAttributeName:[UIFont systemFontOfSize:14],
                            NSForegroundColorAttributeName: [UIColor detailColor]}
                    range:NSMakeRange(title.length, attStr.length - title.length)];
    return attStr;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 3) {
       
        if (self.currentIndex != indexPath.row) {
            
            self.currentIndex = indexPath.row;
            [tableView reloadData];
        }
        OnHomework *taskDetail = self.teacherDetail.onHomeworkList[indexPath.row];
        MIScoreListViewController *scoreListVC = [[MIScoreListViewController alloc] initWithNibName:NSStringFromClass([MIScoreListViewController class]) bundle:nil];
        scoreListVC.hiddenEditTask = YES;
        scoreListVC.teacher = self.teacher;
        Homework *homework = [[Homework alloc] init];
        homework.homeworkId = taskDetail.homeworkId;
        scoreListVC.homework = homework;
        if (self.pushCallBack) {
            self.pushCallBack(scoreListVC);
        }
        WeakifySelf;
        scoreListVC.cancelCallBack = ^{
            [weakSelf resetCurrentSelectIndex];
        };
        scoreListVC.editTaskCallBack = ^{
            [weakSelf resetCurrentSelectIndex];
        };
    }
}

- (void)requestTeacherDetail{
    
    WeakifySelf;
    [TeacherService getTeacherDetailWithId:self.teacher.userId callback:^(Result *result, NSError *error) {
        
        weakSelf.teacherDetail = (TeacherDetail *)result.userInfo;
        if (weakSelf.teacherDetail.isOnline) {
            weakSelf.onlineButton.backgroundColor = [UIColor greenBgColor];
        } else {
            weakSelf.onlineButton.backgroundColor = [UIColor detailColor];
        }
        weakSelf.onlineButton.selected = weakSelf.teacherDetail.isOnline;
        [weakSelf.tableView reloadData];
    }];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
