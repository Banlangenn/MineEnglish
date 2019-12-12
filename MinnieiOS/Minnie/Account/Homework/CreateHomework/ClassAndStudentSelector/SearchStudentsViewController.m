//
//  SearchStudentsViewController.m
//  Minnie
//
//  Created by songzhen on 2019/12/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "StudentService.h"
#import "StudentService.h"
#import "PinyinHelper.h"
#import "HanyuPinyinOutputFormat.h"
#import "StudentSelectorTableViewCell.h"
#import "SearchStudentsViewController.h"
#import "StudentSelectorViewController.h"

@interface SearchStudentsViewController ()<
UITextFieldDelegate,
UITableViewDelegate,
UITableViewDataSource
>

@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cancelTrailConstraint;

@property (nonatomic, strong) StudentSelectorViewController *selectorStudentsVC;

@property (nonatomic, strong) NSArray *resultStudents;
@property (nonatomic, strong) NSMutableArray *selectedStudents;

@property (nonatomic, assign) BOOL selector;
@property (nonatomic, assign) NSInteger inClass;
@property (nonatomic, assign) BOOL showClassName;

@end

@implementation SearchStudentsViewController

- (void)viewDidLoad {
   
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.selectedStudents = [NSMutableArray array];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerNib:[UINib nibWithNibName:@"StudentSelectorTableViewCell" bundle:nil] forCellReuseIdentifier:StudentSelectorTableViewCellId];

    self.resultStudents = self.students;
    if (self.selector) {
        self.addBtn.hidden = NO;
        self.cancelTrailConstraint.constant = 40;
    } else {
        self.addBtn.hidden = YES;
        self.cancelTrailConstraint.constant = 5;
    }
}

- (void)setDataWithSelectState:(BOOL)selector
                       inClass:(NSInteger)inClass
                 showClassName:(BOOL)show{
    self.selector = selector;
    self.inClass = inClass;
    self.showClassName = show;
}

- (void)updateStudentsList:(NSArray *)students{
    self.students = students;
    self.resultStudents = self.students;
    [self.tableView reloadData];
}

#pragma mark - action
- (IBAction)cancelBtnPressed:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
#if MANAGERSIDE
    if (self.closeViewCallBack) {
        self.closeViewCallBack();
    }
#endif
}
- (IBAction)addBtnPressed:(id)sender {
    
    if (self.tableView.hidden) {
        
        [self.selectedStudents removeAllObjects];
        [self.selectedStudents addObjectsFromArray:self.selectorStudentsVC.selectedStudents];
    }
    
    if (self.selectedStudents.count > 0) {

        if (self.addCallBack) {
            self.addCallBack(self.selectedStudents);
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
        
    [textField resignFirstResponder];
    if (textField.text.length > 0)
    {
        [self filterStudents];
    } else {
        self.resultStudents = self.students;
        [self.tableView reloadData];
    }
    return NO;
}
- (IBAction)textFieldChanged:(id)sender {

    [self.selectedStudents removeAllObjects];
    if (self.textField.text.length == 0)
    {// 显示所有
        self.resultStudents = self.students;
        [self.tableView reloadData];
    } else {
        [self filterStudents];
    }
}

- (void)filterStudents{

    NSString *str = [NSString stringWithFormat:@"nickname CONTAINS '%@'",self.textField.text];
    NSPredicate *pre = [NSPredicate predicateWithFormat:str];
    self.resultStudents = [self.students filteredArrayUsingPredicate:pre];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
 
    return self.resultStudents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
 
    User *student = self.resultStudents[indexPath.row];
    
    StudentSelectorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:StudentSelectorTableViewCellId forIndexPath:indexPath];
    
    [cell setupWithStudent:student];
    if (self.showClassName) {
        if ([student isKindOfClass:[StudentsByName class]]) {
            StudentsByName *stu = (StudentsByName *)student;
            [cell setClassName:[NSString stringWithFormat:@"(%@)",stu.className]];
        }
    }
    [cell setChoice:[self.selectedStudents containsObject:student]];
    [cell setReviewMode:!self.selector];


    if (!self.selector) {
        WeakifySelf;
        cell.longPressCallBack = ^{
            [weakSelf moveStudentsWithUserId:student.userId];
        };
    }
    return cell;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return StudentSelectorTableViewCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    User *student = self.resultStudents[indexPath.row];
    
    if (!self.selector) {
        if (self.clickCallBack != nil) {
            self.clickCallBack(student.userId);
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
}

#pragma mark - 获取学生列表
- (void)requestStudentsByTeacher{
    
    if (self.inClass == 1) {// 已入学
               
        [StudentService requestStudentsByTeacherCallback:^(Result *result, NSError *error) {
           
            [self handleRequestResult:result error:error];
        }];
    } else {
        // 未入学 、 待处理
        [StudentService requestStudentsWithClassState:self.inClass
                                             callback:^(Result *result, NSError *error) {
                                                
            [self handleRequestResult:result error:error];
        }];
    }
}

- (void)handleRequestResult:(Result *)result error:(NSError *)error {
  
    if (self.updateStudentStateCallBack) {
        self.updateStudentStateCallBack();
    }
    
    NSDictionary *dict = (NSDictionary *)(result.userInfo);
    NSMutableArray *students = [NSMutableArray arrayWithArray:(NSArray *)(dict[@"list"])];

    HanyuPinyinOutputFormat *outputFormat=[[HanyuPinyinOutputFormat alloc] init];
    [outputFormat setToneType:ToneTypeWithoutTone];
    [outputFormat setVCharType:VCharTypeWithV];
    [outputFormat setCaseType:CaseTypeUppercase];
    [students enumerateObjectsUsingBlock:^(User * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *pinyin = [[PinyinHelper toHanyuPinyinStringWithNSString:obj.nickname withHanyuPinyinOutputFormat:outputFormat withNSString:@" "] uppercaseString];
        obj.pinyinName = pinyin;
    }];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pinyinName" ascending:YES];
    NSArray *array = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [students sortUsingDescriptors:array];
    [self updateStudentsList:students];
}

#pragma mark - 未入学  《=》待处理
- (void)moveStudentsWithUserId:(NSInteger)userId {
    
    if (self.inClass == 1) return;
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
                                                             [weakSelf requestStudentChangeStatusWithUserId:userId];
                                                         }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    
    [alertVC addAction:sureAction];
    [alertVC addAction:cancelAction];
    alertVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alertVC
                       animated:YES
                     completion:nil];
}

- (void)requestStudentChangeStatusWithUserId:(NSInteger)userId{
    
    NSInteger inClass = 0;
    if (self.inClass == 0) {
        inClass = -1;
    }
    WeakifySelf;
    [StudentService requestStudentChangeStatusWithInCalss:inClass studentIds:@[@(userId)] callback:^(Result *result, NSError *error) {
        [weakSelf requestStudentsByTeacher];
    }];
}

@end
