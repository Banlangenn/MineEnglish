//
//  HomeworkSessionTableViewCell.m
//  X5
//
//  Created by yebw on 2017/8/30.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "HomeworkSessionTableViewCell.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import "IMManager.h"

NSString * const UnfinishedHomeworkSessionTableViewCellId = @"UnfinishedHomeworkSessionTableViewCellId";
NSString * const UnfinishedStudentHomeworkSessionTableViewCellId = @"UnfinishedStudentHomeworkSessionTableViewCellId";
NSString * const FinishedHomeworkSessionTableViewCellId = @"FinishedHomeworkSessionTableViewCellId";

@interface HomeworkSessionTableViewCell()

@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (nonatomic, weak) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, weak) IBOutlet UIImageView *unreadIconImageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@property (nonatomic, weak) IBOutlet UILabel *homeworkTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *lastSessionLabel;

@property (nonatomic, weak) IBOutlet UILabel *timeLabel;

@property (nonatomic, weak) IBOutlet UIView *scoreView;
@property (weak, nonatomic) IBOutlet UIView *unfinishTimeBgView;  //距离提交的背景
@property (weak, nonatomic) IBOutlet UILabel *unfinishTimeLabel;  //距离提交的天数
@property (weak, nonatomic) IBOutlet UILabel *unfiishTimeTypeLabel;  //距离提交  天或者小时
@property (weak, nonatomic) IBOutlet UILabel *diffcultLabel;       //难度
@property (weak, nonatomic) IBOutlet UIImageView *cornerBgView;    //角标

@property (weak, nonatomic) IBOutlet UIImageView *unfinishTimeImaV;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *unfinishTimeTopConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *unfinishTimeTypeTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *unfinishTimeTypeCenterXConstraint;


@property (weak, nonatomic) IBOutlet UILabel *unfinishTipLabel;    //距离提交或者距离过期
@property (weak, nonatomic) IBOutlet UIView *rightLineView;

@end

@implementation HomeworkSessionTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.containerView.layer.cornerRadius = 12.f;
    self.containerView.layer.shadowOpacity = 0.4;// 阴影透明度
    self.containerView.layer.shadowColor = [UIColor colorWithHex:0xEEEEEE].CGColor;
    self.containerView.layer.shadowRadius = 3;
    self.containerView.layer.shadowOffset = CGSizeMake(2, 4);
    
    self.avatarImageView.layer.cornerRadius = 22.f;
    self.avatarImageView.layer.masksToBounds = YES;
    
    self.unreadIconImageView.layer.cornerRadius = 5.f;
    self.unreadIconImageView.layer.masksToBounds = YES;
    
    self.homeworkTitleLabel.preferredMaxLayoutWidth = ScreenWidth - 4 * 12.f - 56.f;
    self.lastSessionLabel.preferredMaxLayoutWidth = ScreenWidth - 4 * 12.f - 56.f;
}


- (void)setupSelectState:(BOOL)select{
    
    if (select) {
        self.rightLineView.hidden = NO;
        self.backgroundColor = [UIColor selectedColor];
        self.containerView.backgroundColor = [UIColor selectedColor];
    } else {
        self.rightLineView.hidden = YES;
        self.backgroundColor = [UIColor unSelectedColor];
        self.containerView.backgroundColor = [UIColor whiteColor];
    }
}

- (void)setLeftCommitHomeworkUI:(HomeworkSession *)homeworkSession
{
    
#if MANAGERSIDE
    
    self.unfinishTimeTopConstraint.constant = 35;
    self.unfinishTimeImaV.hidden = YES;
    self.unfiishTimeTypeLabel.hidden = NO;
#else

    self.unfinishTimeTopConstraint.constant = 5;
    self.unfinishTimeImaV.hidden = NO;
    self.unfiishTimeTypeLabel.hidden = YES;
#endif
    
    NSInteger maxHours;
    if (homeworkSession.homework.style == 1)
    {
        maxHours = 24;
    }
    else if (homeworkSession.homework.style == 2)
    {
        maxHours = 48;
    }
    else if (homeworkSession.homework.style == 3)
    {
        maxHours = 72;
    }
    else
    {
        maxHours = 96;
    }
    
    //计算时间
    NSInteger hours = [self calculateDeadlineHourForTime:homeworkSession.sendTime];
    NSLog(@"hours:  %lu",hours);
    BOOL isOutTime; //是否超时，超过规定时间
    if (hours < maxHours)
    {
        isOutTime = NO;
//        self.unfinishTipLabel.text = @"距离提交";
        self.unfinishTipLabel.text = @"绿色还剩";
        self.unfinishTimeBgView.backgroundColor = [[UIColor colorWithHex:0X00CE00] colorWithAlphaComponent:0.7];
    }
    else
    {
        isOutTime = YES;
//        self.unfinishTipLabel.text = @"距离过期";
        if (hours <= 144)
        {
            self.unfinishTipLabel.text = @"黄色还剩";
            self.unfinishTimeBgView.backgroundColor = [[UIColor colorWithHex:0XFFAD27] colorWithAlphaComponent:0.7];
        }
        else
        {
            self.unfinishTipLabel.text = @"距离过期";
            self.unfinishTimeBgView.backgroundColor = [[UIColor colorWithHex:0XFF4858] colorWithAlphaComponent:0.7];
        }
        maxHours = 168;
    }
    
    if (maxHours - hours < 24)
    {
        if (maxHours - hours < 0)
        {
            self.unfinishTipLabel.text = @"已过期";
            
            if (hours - maxHours > 24)
            {
                NSInteger day = (hours - maxHours) % 24 == 0 ? (hours - maxHours) / 24 : (hours - maxHours) / 24 + 1;
                
                [self updateUnfinishTime:day type:@"天"];
                [self updateImageWithOutTime:isOutTime
                                   limitTime:homeworkSession.homework.style
                                 surplusTime:1];
            }
            else
            {
                [self updateUnfinishTime:hours - maxHours type:@"时"];
                // 小于一天
                [self updateImageWithOutTime:isOutTime
                                   limitTime:homeworkSession.homework.style
                                 surplusTime:1];
            }
        }
        else
        {
            [self updateUnfinishTime:maxHours- hours type:@"时"];
            // 小于一天
            [self updateImageWithOutTime:isOutTime
                               limitTime:homeworkSession.homework.style
                             surplusTime:1];
        }
    }
    else
    {
        NSInteger day = (maxHours - hours) % 24 == 0 ? (maxHours - hours) / 24 : (maxHours - hours) / 24 + 1;
        
        [self updateUnfinishTime:day type:@"天"];
        [self updateImageWithOutTime:isOutTime
                           limitTime:homeworkSession.homework.style
                         surplusTime:day];
    }
}

- (void)updateUnfinishTime:(NSInteger)time
                      type:(NSString *)type{
    
#if MANAGERSIDE
    
    self.unfinishTimeLabel.text = [NSString stringWithFormat:@"%ld",time];
    self.unfiishTimeTypeLabel.text = type;
#else
    
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld %@",time,type]];
    [attrStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:24]}
                     range:NSMakeRange(0, attrStr.length - 1)];
    [attrStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]}
                     range:NSMakeRange( attrStr.length - 1,1)];
    
    self.unfinishTimeLabel.attributedText = attrStr;
#endif
}

- (void)updateImageWithOutTime:(BOOL)isOutTime
                     limitTime:(NSInteger)limitTime
                   surplusTime:(NSInteger)surpluseTime{
#if MANAGERSIDE
#else
   
    //surpluseTime 当前距离提交或距离超时剩余时间
    if (isOutTime){ // 超过规定时间
        
        NSString *imageStr = [NSString stringWithFormat:@"day_%lu",surpluseTime];
        self.unfinishTimeImaV.image = [UIImage imageNamed:imageStr];
    } else {// 在作业时限之内
        NSString *imageStr = [NSString stringWithFormat:@"day_%lu%lu",limitTime,surpluseTime];
        self.unfinishTimeImaV.image = [UIImage imageNamed:imageStr];
    }
#endif
}

- (NSInteger)calculateDeadlineHourForTime:(long long)time
{
    NSDate * date = [NSDate date];
    NSTimeInterval second = time/1000;
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate:date];
    NSDate *localDate = [date dateByAddingTimeInterval:interval];
    NSDate * createDate = [NSDate dateWithTimeIntervalSince1970:second];
    interval = [zone secondsFromGMTForDate:createDate];
    NSDate * zoneCreateDate = [createDate dateByAddingTimeInterval:interval];
    NSUInteger countHour = [localDate timeIntervalSinceDate:zoneCreateDate] / 3600;
    return countHour;
}

- (void)setupWithHomeworkSession:(HomeworkSession *)homeworkSession {
    
    HomeworkItem *item = homeworkSession.homework.items.firstObject;
    
    [self setupSelectState:NO];
    
    self.cornerBgView.hidden = NO;
    if (homeworkSession.homework.level == 0)
    {
        self.diffcultLabel.text = @"1星";
    }
    else if (homeworkSession.homework.level == 1)
    {
        self.diffcultLabel.text = @"2星";
    }
    else if (homeworkSession.homework.level == 2)
    {
        self.diffcultLabel.text = @"3星";
    }
    else if (homeworkSession.homework.level == 3)
    {
        self.diffcultLabel.text = @"4星";
    }
    else if (homeworkSession.homework.level == 4)
    {
        self.diffcultLabel.text = @"5星";
    }
    else
    {
        self.cornerBgView.hidden = YES;
    }
    
#if TEACHERSIDE | MANAGERSIDE
    self.nameLabel.text = homeworkSession.student.nickname;
    
    if ([self.reuseIdentifier isEqualToString:@"UnfinishedStudentHomeworkSessionTableViewCellId"])
    {
        [self setLeftCommitHomeworkUI:homeworkSession];
    }
    
    [self.avatarImageView sd_setImageWithURL:[homeworkSession.student.avatarUrl imageURLWithWidth:44.f]];
    NSString * homeworkTitle = item.text?:@"[无文字内容]";
    NSMutableAttributedString * mAttribute = [[NSMutableAttributedString alloc] initWithString:homeworkTitle];
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineSpacing = 5;
    [mAttribute addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, homeworkTitle.length)];
    self.homeworkTitleLabel.attributedText = mAttribute;
    if (homeworkSession.shouldColorLastSessionContent) {
        self.lastSessionLabel.textColor = [UIColor colorWithHex:0x0098FE];
    } else {
        self.lastSessionLabel.textColor = [UIColor colorWithHex:0xFFA500];
    }
#else
    
    //按日期第几次作业有bug恢复到还是取老师名字
    self.nameLabel.text = homeworkSession.correctTeacher.nickname;
    
    [self.avatarImageView sd_setImageWithURL:[homeworkSession.correctTeacher.avatarUrl imageURLWithWidth:44.f] placeholderImage:[UIImage imageNamed:@"attachment_placeholder"]];
    if ([self.reuseIdentifier isEqualToString:@"UnfinishedStudentHomeworkSessionTableViewCellId"])
    {
        [self setLeftCommitHomeworkUI:homeworkSession];
        
        if (homeworkSession.homework.formTag.length > 0)
        {
            NSString * attrStr = item.text?[NSString stringWithFormat:@"[%@]%@",homeworkSession.homework.formTag,item.text]:[NSString stringWithFormat:@"[%@][无文字内容]",homeworkSession.homework.formTag];
            NSMutableAttributedString * mAttribute = [[NSMutableAttributedString alloc] initWithString:attrStr];
            [mAttribute addAttribute:NSForegroundColorAttributeName
                               value:[UIColor colorWithHex:0X0098FE]
                               range:NSMakeRange(0, homeworkSession.homework.formTag.length + 2)];
            NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.lineSpacing = 5;
            [mAttribute addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attrStr.length)];
            self.homeworkTitleLabel.attributedText = mAttribute;
        }
        else
        {
            NSString * homeworkTitle = item.text?:@"[无文字内容]";
            NSMutableAttributedString * mAttribute = [[NSMutableAttributedString alloc] initWithString:homeworkTitle];
            NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.lineSpacing = 5;
            [mAttribute addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, homeworkTitle.length)];
            self.homeworkTitleLabel.attributedText = mAttribute;
        }
        
    }
    else
    {
        NSString * homeworkTitle = item.text?:@"[无文字内容]";
        NSMutableAttributedString * mAttribute = [[NSMutableAttributedString alloc] initWithString:homeworkTitle];
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = 5;
        [mAttribute addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, homeworkTitle.length)];
        self.homeworkTitleLabel.attributedText = mAttribute;
    }
    
    
    if (homeworkSession.shouldColorLastSessionContent) {
        self.lastSessionLabel.textColor = [UIColor redColor];
    } else {
        self.lastSessionLabel.textColor = [UIColor colorWithHex:0x999999];
    }
    
#endif
    
    
    self.lastSessionLabel.text = homeworkSession.lastSessionContent;
    
    if (homeworkSession.sortTime > 0)
    {
        self.timeLabel.text = [Utils formatedDateString:homeworkSession.sortTime];
    }
    else
    {
        self.timeLabel.text = [Utils formatedDateString:homeworkSession.sendTime];
    }
    
    self.unreadIconImageView.hidden = homeworkSession.unreadMessageCount==0;

    if (self.scoreView != nil) {
        for (UIView *v in self.scoreView.subviews) {
            [v removeFromSuperview];
        }
        
        NSString *desc = nil;
        NSUInteger starCount = 0;
        UIColor *color = nil;
        if (homeworkSession.score == 0) {
            starCount = 0;
            color = [UIColor lightGrayColor];
        } else if (homeworkSession.score == 1) {
            desc = @"Pass!";
            starCount = 1;
            color = [UIColor colorWithHex:0x28C4B7];
        } else if (homeworkSession.score == 2) {
            desc = @"Good job!";
            starCount = 2;
            color = [UIColor colorWithHex:0x00CE00];
        } else if (homeworkSession.score == 3) {
            desc = @"Very nice!";
            starCount = 3;
            color = [UIColor colorWithHex:0x0098FE];
        } else if (homeworkSession.score == 4) {
            desc = @"Great!";
            starCount = 4;
            color = [UIColor colorWithHex:0xFFC600];
        } else if (homeworkSession.score == 5) {
            desc = @"Perfect!";
            starCount = 5;
            color = [UIColor colorWithHex:0xFF4858];
        }
//        else if (homeworkSession.score == 6) {
//            desc = @"Very hard working!";
//            starCount = 5; // 没有写错，就是5颗
//            color = [UIColor colorWithHex:0xB248FF];
//        }
        
        self.scoreView.backgroundColor = color;
        
        CGFloat trailing = 0;
        for (NSInteger index=0; index<starCount; index++) {
            trailing = 8+index*12;
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_stars"]];
            [imageView setContentMode:UIViewContentModeScaleAspectFill];
            [self.scoreView addSubview:imageView];
            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.trailing.equalTo(self.scoreView).with.offset(-trailing);
                make.centerY.equalTo(self.scoreView);
                make.size.mas_equalTo(CGSizeMake(12, 12));
            }];
        }
        
        UILabel *label = [[UILabel alloc] init];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = homeworkSession.reviewText;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = [UIColor whiteColor];
        
        [self.scoreView addSubview:label];
        
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.scoreView).with.offset(15);
            make.trailing.equalTo(self.scoreView).with.offset(-trailing-12-8);
            make.centerY.equalTo(self.scoreView);
        }];
    }
}

+ (CGFloat)cellHeightWithHomeworkSession:(HomeworkSession *)homeworkSession finished:(BOOL)finished {
    if (homeworkSession.cellHeightWithMessage>0 && homeworkSession.lastSessionContent.length>0) {
        return homeworkSession.cellHeightWithMessage;
    }
    
    if (homeworkSession.cellHeightWithoutMessage>0 && homeworkSession.lastSessionContent.length==0) {
        return homeworkSession.cellHeightWithoutMessage;
    }
    
    CGFloat height = 0.f;
    
    if (!finished) {
        static HomeworkSessionTableViewCell *unfinishedCell = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
//#if TEACHERSIDE
//            unfinishedCell = [[[NSBundle mainBundle] loadNibNamed:@"UnfinishedHomeworkSessionTableViewCell"
//                                                            owner:nil
//                                                          options:nil] lastObject];
//#else
            unfinishedCell = [[[NSBundle mainBundle] loadNibNamed:@"UnfinishedStudentHomeworkSessionTableViewCell"
                                                            owner:nil
                                                          options:nil] lastObject];
//#endif
        });
        
        
        HomeworkItem *item = homeworkSession.homework.items.firstObject;
        
        NSString * homeworkTitle = item.text?:@"[无文字内容]";
        NSMutableAttributedString * mAttribute = [[NSMutableAttributedString alloc] initWithString:homeworkTitle];
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = 5;
        [mAttribute addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, homeworkTitle.length)];
        unfinishedCell.homeworkTitleLabel.attributedText = mAttribute;
        unfinishedCell.lastSessionLabel.text = homeworkSession.lastSessionContent;
        
        CGSize size = [unfinishedCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        height = size.height;
//#if TEACHERSIDE
//#else
        height = height < 98.0 ? 98.0 : height;
//#endif
//        if (homeworkSession.lastSessionContent.length == 0) {
//            height -= 8.f;
//        }
    } else {
        static HomeworkSessionTableViewCell *finishedCell = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{

            finishedCell = [[[NSBundle mainBundle] loadNibNamed:@"FinishedHomeworkSessionTableViewCell"
                                                          owner:nil
                                                        options:nil] lastObject];
            
        });
        
        HomeworkItem *item = homeworkSession.homework.items.firstObject;
        NSString * homeworkTitle = item.text?:@"[无文字内容]";
        NSMutableAttributedString * mAttribute = [[NSMutableAttributedString alloc] initWithString:homeworkTitle];
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = 5;
        [mAttribute addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, homeworkTitle.length)];
        finishedCell.homeworkTitleLabel.attributedText = mAttribute;
        finishedCell.lastSessionLabel.text = homeworkSession.lastSessionContent;
        
        CGSize size = [finishedCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        height = size.height;
    }
    
    if (homeworkSession.lastSessionContent.length > 0) {
        homeworkSession.cellHeightWithMessage = height;
    } else {
        homeworkSession.cellHeightWithoutMessage = height;
    }
    
    return height;
}

@end

