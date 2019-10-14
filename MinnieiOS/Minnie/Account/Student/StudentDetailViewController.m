//
//  FullfillProfileViewController.m
//  X5
//
//  Created by yebw on 2017/9/17.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "StudentDetailViewController.h"
#import "Student.h"
#import "PublicService.h"
#import "StudentDetailCell.h"
#import "StudentRemarkTableViewCell.h"
#import "StudentAwardService.h"
#import "EditStudentMarkView.h"
#import "StudentDetailHeaderCell.h"
#import "ModifyStarCountViewController.h"
#import "EditContentViewController.h"

@interface StudentDetailViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate,UITableViewDelegate,UITableViewDataSource,UITableViewDelegate,StudentDetailCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *mTableView;
@property (nonatomic, strong) NSArray * titleArray;
@property (nonatomic, strong) Student * user;

@property (nonatomic, strong) BaseRequest *request;

@end

@implementation StudentDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.mTableView sizeToFit];
    self.mTableView.tableFooterView = [[UIView alloc] init];
    self.titleArray = @[@"姓名:",@"电话号码:",@"班级:",@"性别:",@"年级",@"作业完成率:",@"被警告次数:",@"星星数:",@"备注："];
    
    [self registerNibCell];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self requestUserInfo];
}

- (void)registerNibCell
{
    [self.mTableView registerNib:[UINib nibWithNibName:@"StudentDetailCell" bundle:nil] forCellReuseIdentifier:StudentDetailCellId];
    
    [self.mTableView registerNib:[UINib nibWithNibName:@"StudentDetailHeaderCell" bundle:nil] forCellReuseIdentifier:StudentDetailHeaderCellId];
    
    [self.mTableView registerNib:[UINib nibWithNibName:@"StudentRemarkTableViewCell" bundle:nil] forCellReuseIdentifier:StudentRemarkCellId];
    
}

- (void)requestUserInfo {
    [self.view showLoadingView];
    self.mTableView.hidden = YES;
    
    WeakifySelf;
    self.request = [PublicService requestStudentInfoWithId:self.userId
                                                  callback:^(Result *result, NSError *error) {
                                                      StrongifySelf;
                                                      strongSelf.request = nil;
                                                      
                                                      if (error == nil) {
                                                          [strongSelf.view hideAllStateView];
                                                          
                                                          strongSelf.mTableView.hidden = NO;
                                                          
                                                          strongSelf.user = (Student *)(result.userInfo);
                                                          
                                                          [strongSelf.mTableView reloadData];
                                                          
                                                      } else {
                                                          [strongSelf.view showFailureViewWithRetryCallback:^{
                                                              [weakSelf requestUserInfo];
                                                          }];
                                                      }
                                                  }];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.titleArray.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        return 140;
    } else if (indexPath.row == 9) {
        
        if (self.user.stuRemark.length) {
            
            CGFloat height = 80.0;
            if (self.user.stuRemark.length) {
               height = [self heightForString:self.user.stuRemark] + 60;
            }
            return height;
        }
        return 80.0;
    }
    else
    {
        return 80.0;
    }
}

- (float) heightForString:(NSString *)value{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 5;
    // 计算文本的大小
    NSStringDrawingOptions options =  NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
    CGSize rect = [value boundingRectWithSize:CGSizeMake(ScreenWidth - 40,MAXFLOAT) options:options attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0],NSParagraphStyleAttributeName:style} context:nil].size;
    return rect.height + 16.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        StudentDetailHeaderCell * cell = [tableView dequeueReusableCellWithIdentifier:StudentDetailHeaderCellId forIndexPath:indexPath];
        [cell setHeaderURL:self.user.avatarUrl];
        return cell;
    } else if (indexPath.row == 9){
     
        StudentRemarkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:StudentRemarkCellId forIndexPath:indexPath];
        WeakifySelf;
        cell.callback = ^{
            
            EditContentViewController *remarkVC = [[EditContentViewController alloc] initWithNibName:NSStringFromClass([EditContentViewController class]) bundle:nil];
            remarkVC.userId = weakSelf.userId;
            [remarkVC setupEditContentType:EditContentType_StuRemark
                               placeholder:@"备注的学生信息"
                                   content:weakSelf.user.stuRemark];
            [weakSelf.navigationController pushViewController:remarkVC animated:YES];
        };
        if (indexPath.row - 1 < self.titleArray.count) {
            [cell setCellTitle:[self.titleArray objectAtIndex:indexPath.row - 1] withContent:self.user.stuRemark];
        }
        return cell;
    }
    else
    {
        NSString * content;
        StudentDetailCell * cell = [tableView dequeueReusableCellWithIdentifier:StudentDetailCellId forIndexPath:indexPath];
        cell.delegate = self;
        cell.modifyBtn.hidden = YES;
        cell.markImageV.hidden = YES;
        if (indexPath.row == 1)
        {
            if ([self.user.nickname isEqual:self.user.username] || self.user.nickname.length==0) {
                content = nil;
            } else {
                content = self.user.nickname;
            }
            cell.modifyBtn.hidden = NO;
            cell.markImageV.hidden = NO;
            cell.markImageV.image = [UIImage imageNamed:[NSString stringWithFormat:@"icon_stu_label%ld",(long)self.user.stuLabel]];
            [cell setModifybtnTitle:@"编辑标注" tag:indexPath.row];
        }
        else if (indexPath.row == 2)
        {
            content = self.user.username;
        }
        else if (indexPath.row == 3)
        {
            content = self.user.clazz.name;
        }
        else if (indexPath.row == 4)
        {
            if (self.user.gender == 1) {
                content = @"男";
            } else if (self.user.gender == -1) {
                content = @"女";
            } else {
                content = @"保密";
            }
        }
        else if (indexPath.row == 5)
        {
            content = self.user.grade;
        }
        else if (indexPath.row == 6)
        {
            NSUInteger unfinshed = [self.user.homeworks[0] unsignedIntegerValue];
            NSUInteger passed = [self.user.homeworks[1] unsignedIntegerValue];
            NSUInteger goodJob = [self.user.homeworks[2] unsignedIntegerValue];
            NSUInteger veryNice = [self.user.homeworks[3] unsignedIntegerValue];
            NSUInteger great = [self.user.homeworks[4] unsignedIntegerValue];
            NSUInteger perfect = [self.user.homeworks[5] unsignedIntegerValue];
            NSUInteger hardworking = [self.user.homeworks[6] unsignedIntegerValue];
            
            NSUInteger totalCount = unfinshed + passed + goodJob + veryNice + great + perfect + hardworking;
            
            content = [NSString stringWithFormat:@"%lu/%zd",totalCount - unfinshed ,totalCount];
        }
        else if (indexPath.row == 7)
        {
            content = [NSString stringWithFormat:@"%zd次",self.user.warnCount];
        }
        else if (indexPath.row == 8)
        {
            cell.modifyBtn.hidden = NO;
            [cell setModifybtnTitle:@"增减星星数" tag:indexPath.row];

            content = [NSString stringWithFormat:@"%zd",self.user.starCount];
        }
//        else {
//
//            cell.modifyBtn.hidden = NO;
//            [cell setModifybtnTitle:@"编辑备注" tag:indexPath.row];
//            content = self.user.stuRemark;
//        }
        if (indexPath.row - 1 < self.titleArray.count) {
            [cell setCellTitle:[self.titleArray objectAtIndex:indexPath.row - 1] withContent:content];
        }
        return cell;
    }
}


- (void)modifyStarAction:(UIButton *)btn
{
    NSInteger index = btn.tag - 10000;
    if (index == 1) {
      // 编辑标注
        EditStudentMarkView *markView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([EditStudentMarkView class]) owner:nil options:nil] lastObject];
        markView.userId = self.userId;
        markView.stuLabel = self.user.stuLabel;
        WeakifySelf;
        markView.callback = ^{
            [weakSelf requestUserInfo];
        };
        [self.view addSubview:markView];

    } else if (index == 8){
      // 增减星星数
        ModifyStarCountViewController * modifyVc = [[ModifyStarCountViewController alloc] init];
        modifyVc.starCount = self.user.starCount;
        modifyVc.studentId = self.userId;
        [self.navigationController pushViewController:modifyVc animated:YES];
    } else { // 编辑备注
        
        EditContentViewController *remarkVC = [[EditContentViewController alloc] initWithNibName:NSStringFromClass([EditContentViewController class]) bundle:nil];
        remarkVC.userId = self.userId;
        [remarkVC setupEditContentType:EditContentType_StuRemark placeholder:@"" content:self.user.stuRemark];
        [self.navigationController pushViewController:remarkVC animated:YES];
    }
}

- (void)dealloc {
    
    
    [self.request stop];
    [self.request clearCompletionBlock];
    self.request = nil;
}

@end


