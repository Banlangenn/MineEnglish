//
//  ScheduleEditViewController.m
//  X5
//
//  Created by yebw on 2017/8/27.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "ScheduleEditViewController.h"
#import "CalendarTableViewCell.h"
#import "Clazz.h"
#import <Masonry/Masonry.h>
#import "Constants.h"
#import "ScheduleEditHeaderView.h"
#import "DatePickerView.h"
#import "NSDate+X5.h"
#import "NSDate+Extension.h"

@interface ScheduleEditViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *headerContainerView;
@property (nonatomic, strong) IBOutlet ScheduleEditHeaderView *headerView;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UITableView *calendarTableView;
@property (nonatomic, weak) IBOutlet UIButton *rightButton;

@property (nonatomic, strong) NSMutableArray<NSNumber *> *dates; // 上课的日子

@property (nonatomic, strong) NSMutableArray <NSString *> *months; // 月份
@property (nonatomic, strong) NSMutableDictionary *monthItems; // 月份对应的字典

@property (nonatomic, assign) BOOL changed;

@end

@implementation ScheduleEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dates = [NSMutableArray array];
    
    if (self.clazz.dates.count > 0) {
        [self.dates addObjectsFromArray:self.clazz.dates];
    }
    
    [self loadData];
    
    if (self.clazz.isFinished) {
        self.rightButton.hidden = YES;
        self.contentView.userInteractionEnabled = NO;
    }
}

- (void)dealloc {
     
}

- (void)backButtonPressed:(id)sender {
    if (self.changed) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"确认退出"
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                             }];
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  [self.navigationController popViewControllerAnimated:YES];
                                                              }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:confirmAction];
        
        alertController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveButtonPressed:(id)sender {
    if (self.dates.count == 0) {
        [HUD showErrorWithMessage:@"请选择上课日期"];
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyOfUpdateSchedule object:nil];
    
    [HUD showWithMessage:@"已保存"];
    
    self.clazz.dates = self.dates;
    self.changed = NO;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)reloadWithWeekend {
    NSDate *startDate = self.headerView.startDate;
    NSDate *endDate = self.headerView.endDate;
    
    if (startDate == nil || endDate == nil) {
        [self.dates removeAllObjects];
        self.changed = YES;
        [self.monthItems removeAllObjects];
        [self.months removeAllObjects];
        [self reloadTableData];;
        
        return;
    }
    
    if ([endDate timeIntervalSinceDate:startDate]<0
//        ||
//        [endDate timeIntervalSinceDate:startDate]>365*24*60*60
        ) {
        [HUD showErrorWithMessage:@"日期设置错误"];
        
        return;
    }
    
    //  找出这个时间段内所有周末的
    [self.dates removeAllObjects];
    self.changed = YES;
    
    NSInteger index = 0;
    while (1) {
        NSDate *date = [startDate dateByAddingTimeInterval:index*24*60*60];
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date];
        NSInteger weekday = components.weekday;
        if (weekday==1 || weekday==7) {
            [self.dates addObject:@([date timeIntervalSince1970]*1000)];
        }
        
        if ([date isSameDayWithDate:endDate]) {
            break;
        }
        index++;
    }
    
    [self.monthItems removeAllObjects];
    [self.months removeAllObjects];
    [self sortDays];
    [self reloadTableData];;
    
    self.headerView.isWeekend = [self isAllWeekend];
    self.headerView.isWorkday = [self isAllWorkday];
}

- (void)reloadWithWorkday {
    NSDate *startDate = self.headerView.startDate;
    NSDate *endDate = self.headerView.endDate;
    
    if (startDate == nil || endDate == nil) {
        [self.dates removeAllObjects];
        self.changed = YES;
        [self.monthItems removeAllObjects];
        [self.months removeAllObjects];
        [self reloadTableData];;
        
        return;
    }
    
    if ([endDate timeIntervalSinceDate:startDate]<0
//        ||
//        [endDate timeIntervalSinceDate:startDate]>365*24*60*60
        ) {
        [HUD showErrorWithMessage:@"日期设置错误"];
        
        return;
    }
    
    
    //  找出这个时间段内所有工作日
    [self.dates removeAllObjects];
    self.changed = YES;
    
    NSInteger index = 0;
    while (1) {
        NSDate *date = [startDate dateByAddingTimeInterval:index*24*60*60];
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date];
        NSInteger weekday = components.weekday;
        if (weekday!=1 && weekday!=7) {
            [self.dates addObject:@([date timeIntervalSince1970]*1000)];
        }
        
        if ([date isSameDayWithDate:endDate]) {
            break;
        }
        index++;
    }
    
    [self.monthItems removeAllObjects];
    [self.months removeAllObjects];
    [self sortDays];
    [self reloadTableData];;
    
    self.headerView.isWeekend = [self isAllWeekend];
    self.headerView.isWorkday = [self isAllWorkday];
}

- (void)reloadWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    if (startDate == nil || endDate == nil) {
        [self.dates removeAllObjects];
        self.changed = YES;
        [self.monthItems removeAllObjects];
        [self.months removeAllObjects];
        [self reloadTableData];;
        
        return;
    }
    
    if ([endDate timeIntervalSinceDate:startDate]<0
//        ||
//        [endDate timeIntervalSinceDate:startDate]>365*24*60*60
        ) {
        [HUD showErrorWithMessage:@"日期设置错误"];
        
        return;
    }
    
    [self.dates removeAllObjects];
    self.changed = YES;
    [self.dates addObject:@([startDate timeIntervalSince1970]*1000)];
    if (![startDate isSameDayWithDate:endDate]) {
        [self.dates addObject:@([endDate timeIntervalSince1970]*1000)];
    }
    
    [self.monthItems removeAllObjects];
    [self.months removeAllObjects];
    [self sortDays];
    [self reloadTableData];;
    
    self.headerView.isWeekend = [self isAllWeekend];
    self.headerView.isWorkday = [self isAllWorkday];
}

#pragma mark - Private Methods

- (void)loadData {
    ScheduleEditHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:@"ScheduleEditHeaderView" owner:nil options:nil] lastObject];
    [self.headerContainerView addSubview:headerView];
    [headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.headerContainerView);
    }];
    
    self.headerView = headerView;
    
    if (self.dates.count > 0) {
        NSNumber *firstDateNumber = self.dates[0];
        NSNumber *lastDateNumber = [self.dates lastObject];
        
        headerView.startDate = [NSDate dateWithTimeIntervalSince1970:[firstDateNumber floatValue]/1000];
        headerView.endDate = [NSDate dateWithTimeIntervalSince1970:[lastDateNumber floatValue]/1000];
    }
    
    headerView.isWeekend = [self isAllWeekend];
    headerView.isWorkday = [self isAllWorkday];
    
    WeakifySelf;
    __weak ScheduleEditHeaderView *weakHeaderView = headerView;
    headerView.startDateCallback = ^{
        [DatePickerView showInView:weakSelf.navigationController.view
                              date:weakHeaderView.startDate
                          callback:^(NSDate *date) {
                              if ([weakHeaderView.endDate timeIntervalSinceDate:date]<0
//                                  ||
//                                  [weakHeaderView.endDate timeIntervalSinceDate:date]>365*24*60*60
                                  ) {
                                  [HUD showErrorWithMessage:@"日期设置错误"];
                                  
                                  return;
                              }
                              
                              weakHeaderView.startDate = date;
                              [weakSelf reloadWithStartDate:date endDate:weakHeaderView.endDate];
                          }];
    };
    
    headerView.endDateCallback = ^{
        [DatePickerView showInView:weakSelf.navigationController.view
                              date:weakHeaderView.endDate
                          callback:^(NSDate *date) {
                              if ([date timeIntervalSinceDate:weakHeaderView.startDate]<0
//                                  ||
//                                  [date timeIntervalSinceDate:weakHeaderView.startDate]>365*24*60*60
                                  ) {
                                  [HUD showErrorWithMessage:@"日期设置错误"];
                                  
                                  return;
                              }
                              
                              weakHeaderView.endDate = date;
                              
                              [weakSelf reloadWithStartDate:weakHeaderView.startDate endDate:date];
                          }];
    };
    
    headerView.weekendCallback = ^{
        [weakSelf reloadWithWeekend];
    };
    
    headerView.workdayCallback = ^{
        [weakSelf reloadWithWorkday];
    };
    
    [self.calendarTableView registerNib:[UINib nibWithNibName:NSStringFromClass([CalendarTableViewCell class]) bundle:nil] forCellReuseIdentifier:CalendarTableViewCellId];
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 12.f)];
    [v setBackgroundColor:[UIColor clearColor]];
    [self.calendarTableView setTableFooterView:v];
    
    self.months = [NSMutableArray array];
    self.monthItems = [NSMutableDictionary dictionary];
    if (self.dates.count > 0) {
        [self sortDays];
    }
    [self reloadTableData];;
    
    self.headerView.isWeekend = [self isAllWeekend];
    self.headerView.isWorkday = [self isAllWorkday];
}

- (void)addDate:(NSDate *)date {
    if (self.dates.count == 0) {
        [self.dates addObject:@([date timeIntervalSince1970]*1000)];
        self.headerView.startDate = date;
        self.headerView.endDate = date;
        self.headerView.isWeekend = [self isAllWeekend];
        self.headerView.isWorkday = [self isAllWorkday];
        return;
    }
    
    NSNumber *firstDateNumber = self.dates[0];
    NSNumber *lastDateNumber = [self.dates lastObject];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[firstDateNumber floatValue]/1000];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[lastDateNumber floatValue]/1000];
    
    if ([startDate timeIntervalSinceDate:date] > 0 && ![startDate isSameDayWithDate:date]) {
        [self.dates insertObject:@([date timeIntervalSince1970]*1000) atIndex:0];
        self.headerView.startDate = date;
        self.headerView.isWeekend = [self isAllWeekend];
        self.headerView.isWorkday = [self isAllWorkday];
        return;
    }
    
    if ([date timeIntervalSinceDate:endDate] > 0 && ![endDate isSameDayWithDate:date]) {
        [self.dates addObject:@([date timeIntervalSince1970]*1000)];
        self.headerView.endDate = date;
        self.headerView.isWeekend = [self isAllWeekend];
        self.headerView.isWorkday = [self isAllWorkday];
        
        return;
    }
    
    NSInteger index = 1;
    for (NSNumber *dateNumber in self.dates) {
        NSDate *d = [NSDate dateWithTimeIntervalSince1970:dateNumber.floatValue/1000];
        if ([date timeIntervalSinceDate:d]>0 && ![d isSameDayWithDate:date]) {
            [self.dates insertObject:@([date timeIntervalSince1970]*1000) atIndex:index];
            
            break;
        }
        
        index++;
    }
    
    self.headerView.isWeekend = [self isAllWeekend];
    self.headerView.isWorkday = [self isAllWorkday];
    
}

- (void)removeDate:(NSDate *)date {
    if (self.dates.count == 0) {
        return;
    }
    
    NSInteger index = 0;
    for (NSNumber *dateNumber in self.dates) {
        NSDate *d = [NSDate dateWithTimeIntervalSince1970:dateNumber.floatValue/1000];
        if ([d isSameDayWithDate:date]) {
            [self.dates removeObjectAtIndex:index];
            break;
        }
        
        index++;
    }
    
    if (self.dates.count > 0) {
        NSNumber *firstDateNumber = self.dates[0];
        NSNumber *lastDateNumber = [self.dates lastObject];
        self.headerView.startDate = [NSDate dateWithTimeIntervalSince1970:[firstDateNumber floatValue]/1000];
        self.headerView.endDate = [NSDate dateWithTimeIntervalSince1970:[lastDateNumber floatValue]/1000];
    }
    self.headerView.isWeekend = [self isAllWeekend];
    self.headerView.isWorkday = [self isAllWorkday];
    
}

// 是不是都是周末
- (BOOL)isAllWeekend {
    if (self.dates.count == 0) {
        return NO;
    }
    
    BOOL result = YES;
    for (NSNumber *dateNumber in self.dates) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[dateNumber longLongValue]/1000];
        
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date];
        NSInteger weekday = components.weekday;
        if (weekday != 1 && weekday != 7) {
            result = NO;
            break;
        }
    }
    
    return result;
}

// 是不是都是工作日
- (BOOL)isAllWorkday {
    if (self.dates.count == 0) {
        return NO;
    }
    
    BOOL result = YES;
    for (NSNumber *dateNumber in self.dates) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[dateNumber longLongValue]/1000];
        
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date];
        NSInteger weekday = components.weekday;
        if (weekday == 1 || weekday == 7) {
            result = NO;
            break;
        }
    }
    
    return result;
}

- (void)sortDays {
    NSDateComponents *todayComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitWeekday) fromDate:[NSDate date]];
    NSInteger todayYear = todayComponents.year;
    NSInteger todayMonth = todayComponents.month;
    NSInteger todayDay = todayComponents.day;
    
    for (NSNumber *dateNumber in self.dates) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[dateNumber longLongValue]/1000];
        
        NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitWeekday) fromDate:date];
        NSInteger year = components.year;
        NSInteger month = components.month;
        NSInteger day = components.day;
        NSInteger weekday = components.weekday;
        
        NSString *monthString = [NSString stringWithFormat:@"%zd %zd月", year, month];
        if (![self.months containsObject:monthString]) {
            [self.months addObject:monthString];
            
            MonthItem *monthItem = [[MonthItem alloc] init];
            monthItem.dayItems = [NSMutableArray array];
            monthItem.year = year;
            monthItem.month = month;
            
            self.monthItems[monthString] = monthItem;
            
            for (NSInteger index=1; ; index++) {
                NSDate *d = [NSDate dateWithTimeInterval:-24*60*60*index sinceDate:date];
                
                DayItem *dayItem = [[DayItem alloc] init];
                components = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitWeekday) fromDate:d];
                dayItem.date = d;
                dayItem.year = components.year;
                dayItem.month = components.month;
                dayItem.day = components.day;
                dayItem.weakday = components.weekday;
                dayItem.isToday = (todayYear==components.year&&todayMonth==components.month&&todayDay==components.day);
                
                if (dayItem.year != year || dayItem.month != month) {
                    dayItem.isOtherMonth = YES;
                    
                    if (dayItem.weakday != 7) {
                        [monthItem.dayItems insertObject:dayItem atIndex:0];
                    } else {
                        break;
                    }
                    
                    NSDate *tempDate = d;
                    
                    for (NSInteger i=dayItem.weakday-1; i>=1; i--) {
                        DayItem *item = [[DayItem alloc] init];
                        
                        NSDate *d = [NSDate dateWithTimeInterval:-24*60*60*(dayItem.weakday-i) sinceDate:tempDate];
                        
                        components = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitWeekday) fromDate:d];
                        
                        item.date = d;
                        item.year = components.year;
                        item.month = components.month;
                        item.day = components.day;
                        item.weakday = components.weekday;
                        item.isOtherMonth = YES;
                        item.isToday = (todayYear==components.year&&todayMonth==components.month&&todayDay==components.day);
                        item.isClassDay = NO;
                        
                        [monthItem.dayItems insertObject:item atIndex:0];
                    }
                    break;
                } else {
                    [monthItem.dayItems insertObject:dayItem atIndex:0];
                }
            }
            
            DayItem *dayItem = [[DayItem alloc] init];
            dayItem.date = date;
            dayItem.year = year;
            dayItem.month = month;
            dayItem.day = day;
            dayItem.weakday = weekday;
            dayItem.isToday = (todayYear==year&&todayMonth==month&&todayDay==day);
            dayItem.isClassDay = YES;
            
            [monthItem.dayItems addObject:dayItem];
            
            for (NSInteger index=1; ; index++) {
                NSDate *d = [NSDate dateWithTimeInterval:24*60*60*index sinceDate:date];
                
                DayItem *dayItem = [[DayItem alloc] init];
                components = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitWeekday) fromDate:d];
                dayItem.date = d;
                dayItem.year = components.year;
                dayItem.month = components.month;
                dayItem.day = components.day;
                dayItem.weakday = components.weekday;
                dayItem.isToday = (todayYear==components.year&&todayMonth==components.month&&todayDay==components.day);
                
                if (dayItem.year != year || dayItem.month != month) {
                    dayItem.isOtherMonth = YES;
                    if (monthItem.dayItems.count == 6 * 7) {
                        break;
                    }
                    [monthItem.dayItems addObject:dayItem];
                    if (monthItem.dayItems.count == 6 * 7) {
                        break;
                    }
                    
                    NSDate *tempDate = d;
                    
                    for (NSInteger i=dayItem.weakday+1;; i++) {
                        if (monthItem.dayItems.count == 6 * 7) {
                            break;
                        }
                        
                        DayItem *item = [[DayItem alloc] init];
                        
                        NSDate *d = [NSDate dateWithTimeInterval:24*60*60*(i-dayItem.weakday) sinceDate:tempDate];
                        
                        components = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitDay) fromDate:d];
                        item.date = d;
                        item.year = components.year;
                        item.month = components.month;
                        item.day = components.day;
                        item.weakday = components.weekday;
                        item.isOtherMonth = YES;
                        item.isToday = (todayYear==components.year&&todayMonth==components.month&&todayDay==components.day);
                        
                        [monthItem.dayItems addObject:item];
                    }
                    break;
                } else {
                    [monthItem.dayItems addObject:dayItem];
                }
            }
        } else {
            MonthItem *monthItem = self.monthItems[monthString];
            for (DayItem *item in monthItem.dayItems) {
                if (item.isOtherMonth) {
                    continue;
                }
                
                if (item.year==year && item.month==month && item.day==day) {
                    item.isClassDay = YES;
                    break;
                }
            }
        }
    }
    // 课程月份排序
    [self.months sortUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString *   _Nonnull obj2) {
        
        MonthItem *monthItem1 = self.monthItems[obj1];
        MonthItem *monthItem2 = self.monthItems[obj2];
        if (monthItem1.year > monthItem2.year) {
            
            return NSOrderedDescending;
        } else if (monthItem1.year == monthItem2.year) {
            
            if (monthItem1.month >= monthItem2.month) {
                return NSOrderedDescending;
            } else {
                return NSOrderedAscending;
            }
        } else {
            
            return NSOrderedAscending;
        }
    }];
}

- (void)reloadTableData {
    [self.calendarTableView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.dates.count > 0) {
            [self.calendarTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.months.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CalendarTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CalendarTableViewCellId forIndexPath:indexPath];
    
    MonthItem *monthItem = self.monthItems[self.months[indexPath.row]];
    [cell updateWithMonthItem:monthItem editMode:YES];
    
    WeakifySelf;
    cell.callback = ^(NSInteger index) {
        DayItem *dayItem = monthItem.dayItems[index];
        if (dayItem.isClassDay) { // 需要加
            [weakSelf addDate:dayItem.date];
        } else { // 需要减掉
            [weakSelf removeDate:dayItem.date];
        }
        
        weakSelf.changed = YES;
    };
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 308.f;
}

@end

