//
//  MITagsTableViewCell.m
//  MinnieManager
//
//  Created by songzhen on 2019/6/5.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "MITagsTableViewCell.h"
#import "TagCollectionViewCell.h"
#import "MIEqualSpaceFlowLayout.h"

NSString * const MITagsTableViewCellId = @"MITagsTableViewCellId";

@interface MITagsTableViewCell()<
UICollectionViewDataSource,
MIEqualSpaceFlowLayoutDelegate>

@property (nonatomic, strong) NSArray<NSString *> *tags;
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedTags;

@property (weak, nonatomic) IBOutlet UILabel *typeLabel;

@property (nonatomic, strong) UICollectionView *tagsCollectionView;

@property (nonatomic, assign) NSInteger collecttionViewWidth;


@end

@implementation MITagsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if (@available(iOS 12.0, *)) {
        // Addresses a separate issue and prevent auto layout warnings due to the temporary width constraint in the xib.
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *leftConstraint = [self.contentView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:0];
        NSLayoutConstraint *rightConstraint = [self.contentView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:0];
        NSLayoutConstraint *topConstraint = [self.contentView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0];
        NSLayoutConstraint *bottomConstraint = [self.contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0];
        
        [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, bottomConstraint]];
    }
    
    self.tagsCollectionView.layer.cornerRadius = 12;
    self.tagsCollectionView.layer.masksToBounds = YES;
}

- (void)setupWithTags:(NSArray <NSString *> *)tags
         selectedTags:(NSArray <NSString *> *)selectedTags
            typeTitle:(NSString *)title
      collectionWidth:(CGFloat)collectionWidth{
   
    _collecttionViewWidth = collectionWidth;
    self.typeLabel.text = title;
    self.tags = tags;
    self.selectedTags = [NSMutableArray arrayWithArray:selectedTags];
    if (!self.tagsCollectionView) {
        
        [self addContentView];
    }
    self.tagsCollectionView.frame = CGRectMake(0, 40, _collecttionViewWidth, [MITagsTableViewCell heightWithTags:tags collectionWidth:collectionWidth] + 10);
    
    [self.tagsCollectionView reloadData];
}

#pragma mark - IBActions
- (IBAction)managerButtionAction:(UIButton *)sender {
    if (self.manageCallback) {
        self.manageCallback();
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.tags.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    TagCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:TagCollectionViewCellId
                                                                            forIndexPath:indexPath];
    NSString *tag = self.tags[indexPath.row];
    cell.selColor = self.selColor;
    [cell setupWithTag:tag];
    [cell setChoice:[self.selectedTags containsObject:tag]];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    NSString *tag = self.tags[indexPath.item];
    TagCollectionViewCell *cell = (TagCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (self.type == HomeworkTagsTableViewCellSelectSigleType || self.type == HomeworkTagsTableViewCellSelectMutiType)
    {
        if ([self.selectedTags containsObject:tag]) {
            [self.selectedTags removeObject:tag];
            [cell setChoice:NO];
        } else {
            if (self.type == HomeworkTagsTableViewCellSelectSigleType)
            {
                if (self.selectedTags.count == 1)
                {
                    NSString * lastTag = [self.selectedTags objectAtIndex:0];
                    NSInteger lastIndex = [self.tags indexOfObject:lastTag];
                    TagCollectionViewCell *lastCell = (TagCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:lastIndex inSection:0]];
                    [lastCell setChoice:NO];
                    [self.selectedTags removeAllObjects];
                }
            }
            [self.selectedTags addObject:tag];
            [cell setChoice:YES];
        }
    }
    if (self.selectCallback != nil) {
        self.selectCallback(tag);
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *tag = self.tags[indexPath.row];
    CGSize itemSize = [TagCollectionViewCell cellSizeWithTag:tag];
    // 标签长度大于屏幕
    if (itemSize.width > _collecttionViewWidth -30) {
        
        itemSize.width = _collecttionViewWidth - 30;
    } else if (itemSize.width < 40) {
        itemSize.width = 40;
        itemSize.height = 30.5;
    }
    return itemSize;
}

- (void)addContentView{
    
    MIEqualSpaceFlowLayout *flowLayout = [[MIEqualSpaceFlowLayout alloc] initWithCollectionViewWidth:_collecttionViewWidth];
    flowLayout.delegate = self;
    
    self.tagsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 50, _collecttionViewWidth, 50) collectionViewLayout:flowLayout];
    self.tagsCollectionView.backgroundColor = [UIColor whiteColor];
    self.tagsCollectionView.delegate = self;
    self.tagsCollectionView.dataSource = self;
    [self addSubview:self.tagsCollectionView];
    [self.tagsCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([TagCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:TagCollectionViewCellId];
}

+ (CGFloat)heightWithTags:(NSArray <NSString *> *)tags collectionWidth:(CGFloat)collectionWidth{
    
    if (tags.count == 0) {
        return 50.f;
    }
    CGFloat leftSpace = 10;
    CGFloat topSpace = 10;
    CGFloat rightSpace = 10;
    CGFloat minimumInteritemSpacing = 10;
    CGFloat minimumLineSpacing = 10;
    
    CGFloat xOffset = leftSpace;
    CGFloat yOffset = topSpace;
    CGFloat xNextOffset = leftSpace;
    
    CGFloat height = 0;
    
    CGFloat collecttionViewWidth = collectionWidth;
    for (NSInteger idx = 0; idx < tags.count; idx++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
        
        NSString *tag = tags[indexPath.row];
        CGSize itemSize = [TagCollectionViewCell cellSizeWithTag:tag];
        
        xNextOffset+=(minimumInteritemSpacing + itemSize.width);
        if (xNextOffset >= collecttionViewWidth - rightSpace) {
            xOffset = leftSpace;
            xNextOffset = (leftSpace + minimumInteritemSpacing + itemSize.width);
            yOffset += (itemSize.height + minimumLineSpacing);
        }
        else
        {
            xOffset = xNextOffset - (minimumInteritemSpacing + itemSize.width);
        }
        height = yOffset + itemSize.height + 10;
    }
    return height;
}


@end
