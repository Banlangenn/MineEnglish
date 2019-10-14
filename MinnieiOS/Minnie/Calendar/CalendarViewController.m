//
//  CalendarViewController.m
//  X5
//
//  Created by yebw on 2017/8/27.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "CalendarViewController.h"
#import "CalendarHeaderView.h"
#import "CalendarTableViewCell.h"
#import "Clazz.h"
#import <Masonry/Masonry.h>
#import "Constants.h"
#import "ClassService.h"

@interface CalendarViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *headerContainerView;
@property (nonatomic, weak) IBOutlet UITableView *calendarTableView;

@property (nonatomic, strong) NSMutableArray <NSString *> *months; // 月份
@property (nonatomic, strong) NSMutableDictionary *monthItems;

@end

@implementation CalendarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadData];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc {
}

#pragma mark - Private Methods

- (void)loadData {
    self.months = [NSMutableArray array];
    CalendarHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:@"CalendarHeaderView" owner:nil options:nil] lastObject];
    [self.headerContainerView addSubview:headerView];
    [headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.headerContainerView);
    }];
    
    headerView.classNameLabel.text = self.clazz.name;
    headerView.durationLabel.text = [NSString stringWithFormat:@"%@ - %@", self.clazz.startTime, self.clazz.endTime];
    
    [self.calendarTableView registerNib:[UINib nibWithNibName:NSStringFromClass([CalendarTableViewCell class]) bundle:nil] forCellReuseIdentifier:CalendarTableViewCellId];
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 12.f)];
    [v setBackgroundColor:[UIColor clearColor]];
    [self.calendarTableView setTableFooterView:v];
    
    self.monthItems = [NSMutableDictionary dictionary];
    [self sortDays];
}

- (void)sortDays {
    NSDateComponents *todayComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitWeekday) fromDate:[NSDate date]];
    NSInteger todayYear = todayComponents.year;
    NSInteger todayMonth = todayComponents.month;
    NSInteger todayDay = todayComponents.day;
    
    for (NSNumber *dateNumber in self.clazz.dates) {
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
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.months.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CalendarTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CalendarTableViewCellId forIndexPath:indexPath];
    
    [cell updateWithMonthItem:self.monthItems[self.months[indexPath.row]] editMode:NO];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 308.f;
}

@end

