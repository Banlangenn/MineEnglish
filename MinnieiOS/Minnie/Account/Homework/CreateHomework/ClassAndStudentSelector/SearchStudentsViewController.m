//
//  SearchStudentsViewController.m
//  Minnie
//
//  Created by songzhen on 2019/12/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

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

@property (nonatomic, strong) StudentSelectorViewController *selectorStudentsVC;

@property (nonatomic, strong) NSArray *resultStudents;
@property (nonatomic, strong) NSMutableArray *selectedStudents;


@end

@implementation SearchStudentsViewController

- (void)viewDidLoad {
   
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.selectedStudents = [NSMutableArray array];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerNib:[UINib nibWithNibName:@"StudentSelectorTableViewCell" bundle:nil] forCellReuseIdentifier:StudentSelectorTableViewCellId];
    [self addStudentSelectorViewController];
}

- (IBAction)cancelBtnPressed:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
#if MANAGERSIDE
    if (self.cancelCallBack) {
        self.cancelCallBack();
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
        self.tableView.hidden = NO;
        [self removeStudentSelectorViewController];
        [self search];
    } else {
        self.tableView.hidden = YES;
        [self addStudentSelectorViewController];
    }
    return NO;
}
- (IBAction)textFieldChanged:(id)sender {
   
    if (self.textField.text.length == 0)
    {
        self.tableView.hidden = YES;
        [self addStudentSelectorViewController];
    } else {
        self.tableView.hidden = NO;
        [self removeStudentSelectorViewController];
    }
}

- (void)removeStudentSelectorViewController{
    
    if (self.selectorStudentsVC) {
        
        if (self.selectorStudentsVC.view.superview) {
            [self.selectorStudentsVC.view removeFromSuperview];
            [self.selectorStudentsVC removeFromParentViewController];
        }
    }
}

- (void)addStudentSelectorViewController {
   
    return;
    if (self.selectorStudentsVC == nil) {
            
        self.selectorStudentsVC = [[StudentSelectorViewController alloc] initWithNibName:NSStringFromClass([StudentSelectorViewController class]) bundle:nil];

        self.selectorStudentsVC.reviewMode = NO;
        self.selectorStudentsVC.classStateMode = YES;
        self.selectorStudentsVC.inClass = 0;
        self.selectorStudentsVC.selectCallback = ^(NSInteger count) {
        };
    }
    
    [self addChildViewController:self.selectorStudentsVC];
    [self.view addSubview:self.selectorStudentsVC.view];
//    self.selectorStudentsVC.view.frame = CGRectMake(0, kNaviBarHeight, ScreenWidth, ScreenHeight - kNaviBarHeight);
    [self.selectorStudentsVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.top.mas_equalTo(self.view.mas_top).offset(kNaviBarHeight);
        make.left.right.bottom.equalTo(self.view);
    }];
    [self.selectorStudentsVC didMoveToParentViewController:self];
}

- (void)search{

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
    [cell setChoice:[self.selectedStudents containsObject:student]];
    [cell setReviewMode:NO];
//    if (self.inClass != 1) {
//        WeakifySelf;
//        cell.longPressCallBack = ^{
//            [weakSelf requestMoveStudentsWithUserId:student.userId];
//        };
//    }
//    if (self.showClassName) {
//        if ([student isKindOfClass:[StudentsByName class]]) {
//            StudentsByName *stu = (StudentsByName *)student;
//            [cell setClassName:[NSString stringWithFormat:@"(%@)",stu.className]];
//        }
//    }
    return cell;
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return StudentSelectorTableViewCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    User *student = self.resultStudents[indexPath.row];
    StudentSelectorTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([self.selectedStudents containsObject:student]) {
        [self.selectedStudents removeObject:student];
        [cell setChoice:NO];
    } else {
        [self.selectedStudents addObject:student];
        [cell setChoice:YES];
    }
}

@end
