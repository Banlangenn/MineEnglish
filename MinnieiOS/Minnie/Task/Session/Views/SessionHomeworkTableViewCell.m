//
//  SessionHomeworkTableViewCell.m
//  X5Teacher
//
//  Created by yebw on 2018/3/25.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "SessionHomeworkTableViewCell.h"
#import "HomeworkImageCollectionViewCell.h"
#import "HomeworkVideoCollectionViewCell.h"
#import "HomeworkAudioCollectionViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

NSString * const SessionHomeworkTableViewCellId = @"SessionHomeworkTableViewCellId";

@interface SessionHomeworkTableViewCell()<
UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout>


@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@property (nonatomic, weak) IBOutlet UILabel *homeworkTitleLabel;

@property (nonatomic, weak) IBOutlet UILabel *homeworkTextLabel;
@property (nonatomic, weak) IBOutlet UICollectionView *homeworksCollectionView;
// 限制时间
@property (weak, nonatomic) IBOutlet UILabel *limitTimeLabel;

// 发送作业日期
@property (weak, nonatomic) IBOutlet UILabel *sendTimeLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *collectionViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *collectionViewBottomConstraint;

@property (nonatomic, strong) HomeworkSession *homeworkSession;
@property (weak, nonatomic) IBOutlet UILabel *teremarkLabel;

@end

@implementation SessionHomeworkTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
#if MANAGERSIDE
    self.homeworkTextLabel.preferredMaxLayoutWidth = kColumnThreeWidth - 36 - 44;
#else
    self.homeworkTextLabel.preferredMaxLayoutWidth = ScreenWidth - 36 - 44;
#endif
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize = CGSizeMake(90, 110);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 12;
    
    self.homeworksCollectionView.collectionViewLayout = layout;
    
    [self registerCellNibs];
}

- (void)registerCellNibs {
    [self.homeworksCollectionView registerNib:[UINib nibWithNibName:@"HomeworkImageCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:HomeworkImageCollectionViewCellId];
    [self.homeworksCollectionView registerNib:[UINib nibWithNibName:@"HomeworkVideoCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:HomeworkVideoCollectionViewCellId];
    [self.homeworksCollectionView registerNib:[UINib nibWithNibName:@"HomeworkAudioCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:HomeworkAudioCollectionViewCellId];
}

- (void)setupWithHomeworkSession:(HomeworkSession *)homeworkSession {
    
    self.homeworkSession = homeworkSession;
    
    NSString *text = nil;
    for (HomeworkItem *item in self.homeworkSession.homework.items) {
        if ([item.type isEqualToString:HomeworkItemTypeText]) {
            text = item.text;
            break;
        }
    }
    if (text.length > 0) {
       
        NSMutableAttributedString * mAttribute = [[NSMutableAttributedString alloc] initWithString:text];
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = 5;
        [mAttribute addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, text.length)];
        self.homeworkTextLabel.attributedText = mAttribute;
    }
    
    // 发送时间
    if (self.homeworkSession.sendTime > 0) {
       
        NSString *sendTime = [Utils formatedDayDateString:self.homeworkSession.sendTime];
        self.sendTimeLabel.hidden = NO;
        self.sendTimeLabel.text = sendTime;
    } else {
        self.sendTimeLabel.hidden = YES;
    }
    
    // 批改备注 (仅教师端显示)
    NSString *teremark = @"";
#if TEACHERSIDE || MANAGERSIDE
    if (homeworkSession.homework.teremark.length) {
        teremark = [NSString stringWithFormat:@"注：%@",homeworkSession.homework.teremark];
    }
#else
#endif
    if (teremark.length) {
 
        NSMutableAttributedString * teremarkAtt = [[NSMutableAttributedString alloc] initWithString:teremark];
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = 5;
        [teremarkAtt addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, teremark.length)];
        self.teremarkLabel.attributedText = teremarkAtt;
    }
    
    NSInteger min = homeworkSession.homework.limitTimes / 60;
    NSInteger sec = homeworkSession.homework.limitTimes % 60;
    
    NSString * time;
    if (sec == 0)
    {
        time = [NSString stringWithFormat:@"%ld分钟内",(long)min];
    }
    else
    {
        time = [NSString stringWithFormat:@"%ld分%02ld秒内",(long)min,(long)sec];
    }
    self.limitTimeLabel.text = [NSString stringWithFormat:@"规定时间:%@",time];

//学生端如果5分钟不显示这个规定时间

    if (homeworkSession.homework.limitTimes == 300)
    {
        self.limitTimeLabel.hidden = YES;
    }
    else
    {
        self.limitTimeLabel.hidden = NO;
    }

    
    self.dateLabel.text = [Utils formatedDateString:self.homeworkSession.sendTime];
    
    
    if (![homeworkSession.homework.typeName isEqualToString: kHomeworkTaskFollowUpName]){
       
        if (homeworkSession.homework.items.count == 1) {
            self.collectionViewHeightConstraint.constant = 0.f;
            self.collectionViewBottomConstraint.constant = 10.f;
        } else {
            self.collectionViewHeightConstraint.constant = 114.f;
            self.collectionViewBottomConstraint.constant = 12.f;
        }
    } else {
        self.collectionViewHeightConstraint.constant = 114.f;
        self.collectionViewBottomConstraint.constant = 12.f;
    }
    [self.homeworksCollectionView reloadData];
}

+ (CGFloat)heightWithHomeworkSession:(HomeworkSession *)homeworkSession {
    if (homeworkSession.homework.cellHeight > 0) {
        return homeworkSession.homework.cellHeight;
    }
    
    static SessionHomeworkTableViewCell *cell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cell = [[[NSBundle mainBundle] loadNibNamed:@"SessionHomeworkTableViewCell" owner:nil options:nil] lastObject];
    });
    
    [cell setupWithHomeworkSession:homeworkSession];
    
    cell.collectionViewHeightConstraint.constant = 114.f;
    cell.collectionViewBottomConstraint.constant = 12.f;
    NSString *text = nil;
    for (HomeworkItem *item in homeworkSession.homework.items) {
        if ([item.type isEqualToString:HomeworkItemTypeText]) {
            text = item.text;
            break;
        }
    }
    if (text.length > 0) {
        
        NSMutableAttributedString * mAttribute = [[NSMutableAttributedString alloc] initWithString:text];
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = 5;
        [mAttribute addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, text.length)];
        cell.homeworkTextLabel.attributedText = mAttribute;
    }
    
    
    // 批改备注
    NSString *teremark = @"";
#if TEACHERSIDE || MANAGERSIDE
    if (homeworkSession.homework.teremark.length) {
        teremark = [NSString stringWithFormat:@"注：%@",homeworkSession.homework.teremark];
    }
#else
#endif
    if (teremark.length) {
     
        NSMutableAttributedString * teremarkAtt = [[NSMutableAttributedString alloc] initWithString:teremark];
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = 5;
        [teremarkAtt addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, teremark.length)];
        cell.teremarkLabel.attributedText = teremarkAtt;
    }
    
    CGSize size = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGFloat height = size.height + 20;
    if (![homeworkSession.homework.typeName isEqualToString: kHomeworkTaskFollowUpName]){
        if (homeworkSession.homework.items.count == 1) {
            height -= (114.f + 12.f);
        }
    }
    homeworkSession.homework.cellHeight = height;
    NSLog(@"homeworkSession:%f  \n %@",height,homeworkSession.homework);
    return homeworkSession.homework.cellHeight;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
   
    NSInteger number = 0;
    // 单词记忆，内容放在items最后一个
    // items 第一个放text 内容文本
    // 跟读任务 内容放在 otheritem
    // 单词记忆、跟读，第一个放开始任务button

    for (HomeworkItem *item in self.homeworkSession.homework.items) {
        if (![item.type isEqualToString:HomeworkItemTypeText]) {
            number++;
        }
    }
    if ([self.homeworkSession.homework.typeName isEqualToString: kHomeworkTaskFollowUpName]) {
        number++;
    }
    return number;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = nil;

    if ([self.homeworkSession.homework.typeName isEqualToString: kHomeworkTaskFollowUpName] ||
        [self.homeworkSession.homework.typeName isEqualToString: kHomeworkTaskWordMemoryName]) {
        if (indexPath.row == 0) {
           
            HomeworkImageCollectionViewCell *imageCell = [collectionView dequeueReusableCellWithReuseIdentifier:HomeworkImageCollectionViewCellId forIndexPath:indexPath];
            [imageCell setupWithStartTask];
        
            cell = imageCell;
        } else {
            
            HomeworkItem *item = self.homeworkSession.homework.items[indexPath.row];
            if ([item.type isEqualToString:HomeworkItemTypeImage]) {
                HomeworkImageCollectionViewCell *imageCell = [collectionView dequeueReusableCellWithReuseIdentifier:HomeworkImageCollectionViewCellId forIndexPath:indexPath];
                
                [imageCell setupWithHomeworkItem:item name:[NSString stringWithFormat:@"材料%zd", indexPath.row]];
                
                cell = imageCell;
            } else if ([item.type isEqualToString:HomeworkItemTypeVideo]) {
                HomeworkVideoCollectionViewCell *videoCell = [collectionView dequeueReusableCellWithReuseIdentifier:HomeworkVideoCollectionViewCellId forIndexPath:indexPath];
                
                [videoCell setupWithHomeworkItem:item name:[NSString stringWithFormat:@"材料%zd", indexPath.row]];
                
                cell = videoCell;
            } else
//                if ([item.type isEqualToString:HomeworkItemTypeAudio])
            {
                HomeworkAudioCollectionViewCell *audioCell = [collectionView dequeueReusableCellWithReuseIdentifier:HomeworkAudioCollectionViewCellId forIndexPath:indexPath];
                
                [audioCell setupWithHomeworkItem:item name:[NSString stringWithFormat:@"材料%zd", indexPath.row]];
                
                cell = audioCell;
            }
        }
    } else {
        HomeworkItem *item = self.homeworkSession.homework.items[indexPath.row+1];
        if ([item.type isEqualToString:HomeworkItemTypeImage]) {
            HomeworkImageCollectionViewCell *imageCell = [collectionView dequeueReusableCellWithReuseIdentifier:HomeworkImageCollectionViewCellId forIndexPath:indexPath];
            
            [imageCell setupWithHomeworkItem:item name:[NSString stringWithFormat:@"材料%zd", indexPath.row+1]];
            
            cell = imageCell;
        } else if ([item.type isEqualToString:HomeworkItemTypeVideo]) {
            HomeworkVideoCollectionViewCell *videoCell = [collectionView dequeueReusableCellWithReuseIdentifier:HomeworkVideoCollectionViewCellId forIndexPath:indexPath];
            
            [videoCell setupWithHomeworkItem:item name:[NSString stringWithFormat:@"材料%zd", indexPath.row+1]];
            
            cell = videoCell;
        } else
//            if ([item.type isEqualToString:HomeworkItemTypeAudio])
            {
            HomeworkAudioCollectionViewCell *audioCell = [collectionView dequeueReusableCellWithReuseIdentifier:HomeworkAudioCollectionViewCellId forIndexPath:indexPath];
            
            [audioCell setupWithHomeworkItem:item name:[NSString stringWithFormat:@"材料%zd", indexPath.row+1]];
            
            cell = audioCell;
        }
        
    }
 
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
   
    if ([self.homeworkSession.homework.typeName isEqualToString: kHomeworkTaskFollowUpName] ||
        [self.homeworkSession.homework.typeName isEqualToString: kHomeworkTaskWordMemoryName]) {
        if (indexPath.row == 0) {
            if (self.startTaskCallback) {
                self.startTaskCallback();
            }
        } else {
            HomeworkItem *item = self.homeworkSession.homework.items[indexPath.row];
            if ([item.type isEqualToString:HomeworkItemTypeImage]) {
                
                HomeworkImageCollectionViewCell *cell = (HomeworkImageCollectionViewCell *)[self.homeworksCollectionView cellForItemAtIndexPath:indexPath];
                
                if (self.imageCallback != nil) {
                    self.imageCallback(item.imageUrl, cell.homeworkImageView, indexPath.item);
                }
            } else if ([item.type isEqualToString:HomeworkItemTypeVideo]) {
                if (self.videoCallback != nil) {
                    self.videoCallback(item.videoUrl);
                }
            } else if ([item.type isEqualToString:HomeworkItemTypeAudio]) {
                if (self.audioCallback != nil) {
                    self.audioCallback(item.audioUrl,item.audioCoverUrl);
                }
            }
        }
    } else {
       
        HomeworkItem *item = self.homeworkSession.homework.items[indexPath.row+1];
        if ([item.type isEqualToString:HomeworkItemTypeImage]) {
            
            HomeworkImageCollectionViewCell *cell = (HomeworkImageCollectionViewCell *)[self.homeworksCollectionView cellForItemAtIndexPath:indexPath];
            
            if (self.imageCallback != nil) {
                self.imageCallback(item.imageUrl, cell.homeworkImageView, indexPath.item);
            }
        } else if ([item.type isEqualToString:HomeworkItemTypeVideo]) {
            if (self.videoCallback != nil) {
                self.videoCallback(item.videoUrl);
            }
        } else if ([item.type isEqualToString:HomeworkItemTypeAudio]) {
            if (self.audioCallback != nil) {
                self.audioCallback(item.audioUrl,item.audioCoverUrl);
            }
        }
    }
}


@end


