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

@interface SessionHomeworkTableViewCell()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>


@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@property (nonatomic, weak) IBOutlet UILabel *homeworkTitleLabel;

@property (nonatomic, weak) IBOutlet UILabel *homeworkTextLabel;
@property (nonatomic, weak) IBOutlet UICollectionView *homeworksCollectionView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *collectionViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *collectionViewBottomConstraint;

@property (nonatomic, strong) HomeworkSession *homeworkSession;

@end

@implementation SessionHomeworkTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.homeworkTextLabel.preferredMaxLayoutWidth = ScreenWidth - 36 - 44;
    
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
    
//    self.homeworkTitleLabel.text = self.homeworkSession.homework.title;
    
    NSString *text = nil;
    for (HomeworkItem *item in self.homeworkSession.homework.items) {
        if ([item.type isEqualToString:HomeworkItemTypeText]) {
            text = item.text;
            break;
        }
    }
    
    self.homeworkTextLabel.text = text;
    self.dateLabel.text = [Utils formatedDateString:self.homeworkSession.sendTime];
    
    if (homeworkSession.homework.items.count == 1) {
        self.collectionViewHeightConstraint.constant = 0.f;
        self.collectionViewBottomConstraint.constant = 0.f;
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
    
    CGSize size = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGFloat height = size.height;
    
    if (homeworkSession.homework.items.count == 1) {
        height -= (114.f + 12.f);
    }
    
    homeworkSession.homework.cellHeight = height;
    
    return homeworkSession.homework.cellHeight;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger number = 0;
    
    for (HomeworkItem *item in self.homeworkSession.homework.items) {
        if (![item.type isEqualToString:HomeworkItemTypeText]) {
            number++;
        }
    }
    
    return number;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = nil;
    
    HomeworkItem *item = self.homeworkSession.homework.items[indexPath.row+1];
    if ([item.type isEqualToString:HomeworkItemTypeImage]) {
        HomeworkImageCollectionViewCell *imageCell = [collectionView dequeueReusableCellWithReuseIdentifier:HomeworkImageCollectionViewCellId forIndexPath:indexPath];
        
        [imageCell setupWithHomeworkItem:item name:[NSString stringWithFormat:@"材料%zd", indexPath.row+1]];
        
        cell = imageCell;
    } else if ([item.type isEqualToString:HomeworkItemTypeVideo]) {
        HomeworkVideoCollectionViewCell *videoCell = [collectionView dequeueReusableCellWithReuseIdentifier:HomeworkVideoCollectionViewCellId forIndexPath:indexPath];
        
        [videoCell setupWithHomeworkItem:item name:[NSString stringWithFormat:@"材料%zd", indexPath.row+1]];
        
        cell = videoCell;
    } else if ([item.type isEqualToString:HomeworkItemTypeAudio]) {
        HomeworkAudioCollectionViewCell *audioCell = [collectionView dequeueReusableCellWithReuseIdentifier:HomeworkAudioCollectionViewCellId forIndexPath:indexPath];
        
        [audioCell setupWithHomeworkItem:item name:[NSString stringWithFormat:@"材料%zd", indexPath.row+1]];
        
        cell = audioCell;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    HomeworkItem *item = self.homeworkSession.homework.items[indexPath.row+1];
    if ([item.type isEqualToString:HomeworkItemTypeImage]) {
        HomeworkImageCollectionViewCell *cell = (HomeworkImageCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        
        if (self.imageCallback != nil) {
            self.imageCallback(item.imageUrl, cell.homeworkImageView);
        }
    } else if ([item.type isEqualToString:HomeworkItemTypeVideo]) {
        if (self.videoCallback != nil) {
            self.videoCallback(item.videoUrl);
        }
    } else if ([item.type isEqualToString:HomeworkItemTypeAudio]) {
        if (self.audioCallback != nil) {
            self.audioCallback(item.audioUrl);
        }
    }
}


@end


