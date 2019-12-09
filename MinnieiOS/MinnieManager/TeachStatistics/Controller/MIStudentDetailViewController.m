//
//  MIStudentDetailViewController.m
//  MinnieManager
//
//  Created by songzhen on 2019/7/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "PublicService.h"
#import "StudentService.h"
#import "MIStudentInfoTableViewCell.h"
#import "MIStudentDetailViewController.h"

@interface MIStudentDetailViewController ()

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *rightLineView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImagV;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *onlineButton;

@property (strong, nonatomic) Student *student;
@property (strong, nonatomic) StudentDetail *studentDetail;

@end

@implementation MIStudentDetailViewController

- (void)viewDidLoad {
   
    [super viewDidLoad];
   
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor emptyBgColor];
    
    self.iconImagV.layer.masksToBounds = YES;
    self.iconImagV.layer.cornerRadius = 12.0;
    
    self.onlineButton.layer.cornerRadius = 4.0;
    self.onlineButton.selected = NO;
    self.onlineButton.backgroundColor = [UIColor detailColor];
    
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)updateStudent:(Student * _Nullable)student{
   
    self.student = student;
    if (student == nil) {
       
        self.headerView.hidden = YES;
        self.tableView.hidden = YES;
        self.rightLineView.hidden = YES;
    } else {
      
        self.headerView.hidden = NO;
        self.tableView.hidden = NO;
        self.rightLineView.hidden = NO;
        
        self.nameLabel.text = self.student.nickname;
        [self.iconImagV sd_setImageWithURL:[self.student.avatarUrl imageURLWithWidth:24] placeholderImage:[UIImage imageNamed: @"attachment_placeholder"]];
        
        [self requestStudentDetailTask];
        [self requestSutdentInfo];
    }
}

#pragma mark -   UITableViewDelegate,UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 5;
}
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 1;
    } else if (section == 2) {
        return 6;
    } else if (section == 3) {
        return 5;
    } else {
        return 6;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
   
    if (indexPath.section == 0) {
        return 160;
    } else {
        return 30;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
       
        MIStudentInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MIStudentInfoTableViewCellId];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MIStudentInfoTableViewCell class]) owner:nil options:nil] lastObject];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [cell setupStudentInfo:self.student];
        return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"studentDetailCellId"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"studentDetailCellId"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (indexPath.section == 1) {

        cell.textLabel.attributedText = [self setupContentTitle:@"综合评价:" text:nil];
    } else if (indexPath.section == 2) {
        
        if (indexPath.row == 0) {
            cell.textLabel.attributedText = [self setupContentTitle:@"待批改数：" text:[NSString stringWithFormat:@"%lu",self.studentDetail.uncorrectHomeworksCount]];
        } else if (indexPath.row == 1) {
            cell.textLabel.attributedText = [self setupContentTitle:@"考试统计：" text:[NSString stringWithFormat:@"%.1f",self.studentDetail.testAvgScore]];
        } else if (indexPath.row == 2) {
            cell.textLabel.attributedText = [self setupContentTitle:@"获得勋章数：" text:[NSString stringWithFormat:@"%lu",self.studentDetail.medalCount]];
        } else if (indexPath.row == 3) {
            cell.textLabel.attributedText = [self setupContentTitle:@"获得点赞数：" text:[NSString stringWithFormat:@"%lu",self.studentDetail.likeCount]];
        } else if (indexPath.row == 4) {
            cell.textLabel.attributedText = [self setupContentTitle:@"星星数：" text:[NSString stringWithFormat:@"%lu",self.studentDetail.starCount]];
        } else {
            cell.textLabel.attributedText = [self setupContentTitle:@"兑换礼品数：" text:[NSString stringWithFormat:@"%lu",self.studentDetail.giftCount]];
        }
    } else if (indexPath.section == 3) {
        
        if (indexPath.row == 0) {
            
            NSInteger finish = 0;
            if (self.studentDetail.homeworks.count >= 7) {
               
                finish = self.studentDetail.allHomeworksCount - ((NSNumber *)self.studentDetail.homeworks[0]).intValue - ((NSNumber *)self.studentDetail.homeworks[6]).intValue;
            }
            cell.textLabel.attributedText = [self setupContentTitle:@"本学期任务完成率：" text:[NSString stringWithFormat:@"%lu/%lu",finish,self.studentDetail.allHomeworksCount]];
        } else if (indexPath.row == 1) {
            cell.textLabel.attributedText = [self setupContentTitle:@"任务平均得分：" text:[NSString stringWithFormat:@"%.1f",self.studentDetail.avgScore]];
        } else if (indexPath.row == 2) {
            cell.textLabel.attributedText = [self setupContentTitle:@"优秀任务数：" text:[NSString stringWithFormat:@"%lu",self.studentDetail.excellentHomeworksCount]];
        } else if (indexPath.row == 3) {
            cell.textLabel.attributedText = [self setupContentTitle:@"过期任务数：" text:[NSString stringWithFormat:@"%lu",self.studentDetail.overdueHomeworksCount]];
        } else {
            cell.textLabel.attributedText = [self setupContentTitle:@"被分享次数：" text:[NSString stringWithFormat:@"%lu",self.studentDetail.shareCount]];
        }
    } else {
        NSString *starCount;
        if (5 - indexPath.row < self.studentDetail.homeworks.count) {
            starCount = self.studentDetail.homeworks[5 - indexPath.row];
        }
        NSString *titleStr = [NSString stringWithFormat:@"%lu星任务数：",5 - indexPath.row];
        cell.textLabel.attributedText = [self setupContentTitle:titleStr text:[NSString stringWithFormat:@"%@",starCount]];
    }
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView *headerView =  [[UIView alloc] init];
    headerView.backgroundColor = [UIColor whiteColor];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 20.0;
}

- (NSAttributedString *)setupContentTitle:(NSString *)title text:(NSString *)text{
    if (text.length == 0) {
        text = @"";
    }
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",title,text]];
    [attStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} range:NSMakeRange(0, attStr.length)];
    [attStr setAttributes:@{NSForegroundColorAttributeName: [UIColor detailColor],
                            NSFontAttributeName:[UIFont systemFontOfSize:14]}
                    range:NSMakeRange(title.length, attStr.length - title.length)];
    return attStr;
    
}

- (void)requestStudentDetailTask{
    
    WeakifySelf;
    [StudentService requestStudentDetailTaskWithStuId:self.student.userId callback:^(Result *result, NSError *error) {
        
        weakSelf.studentDetail = (StudentDetail *)result.userInfo;
        [weakSelf.tableView reloadData];
        if (weakSelf.studentDetail.isOnline) {
            weakSelf.onlineButton.backgroundColor = [UIColor greenBgColor];
        } else {
            weakSelf.onlineButton.backgroundColor = [UIColor detailColor];
        }
        weakSelf.onlineButton.selected = weakSelf.studentDetail.isOnline;
    }];
}

- (void)requestSutdentInfo{

    [PublicService requestStudentInfoWithId:self.student.userId
                                callback:^(Result *result, NSError *error) {
                                    if (error == nil) {
                                        Student *userInfo = (Student *)(result.userInfo);
                                        self.student.phoneNumber = userInfo.phoneNumber;
                                        self.student.gender = userInfo.gender;
                                        self.student.clazz = userInfo.clazz;
                                        [self.tableView reloadData];
                                    }
                                }];
}


@end
