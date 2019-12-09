//
//  MIZeroMessagesTableViewCell.m
//  MinnieManager
//
//  Created by songzhen on 2019/7/12.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "MIZeroMessagesTableViewCell.h"

NSString * const MIZeroMessagesTableViewCellId = @"MIZeroMessagesTableViewCellId";

@interface MIZeroMessagesTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageV;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *taskNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UILabel *teacherNameLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;

@end

@implementation MIZeroMessagesTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.imageV.layer.masksToBounds = YES;
    self.imageV.layer.cornerRadius = 18.f;
}

- (void)setupImage:(NSString *)image
              name:(NSString *)name
         taskTitle:(NSString *)title
           comment:(NSString *)comment
           teacher:(NSString *)teacher
             index:(NSInteger)index{
    
    if (index == 0) {
        
        self.imageV.hidden = YES;
        self.imageWidthConstraint.constant = 0;
        self.contentView.backgroundColor = [UIColor unSelectedColor];
        self.nameLabel.font = [UIFont boldSystemFontOfSize:12];
        self.taskNameLabel.font = [UIFont boldSystemFontOfSize:12];
        self.commentLabel.font = [UIFont boldSystemFontOfSize:12];
        self.teacherNameLabel.font = [UIFont boldSystemFontOfSize:12];
        
        self.nameLabel.textColor = [UIColor normalColor];
        self.taskNameLabel.textColor = [UIColor normalColor];
        self.commentLabel.textColor = [UIColor normalColor];
        self.teacherNameLabel.textColor = [UIColor normalColor];
    } else {
        self.imageV.hidden = NO;
        self.imageWidthConstraint.constant = 36;
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.nameLabel.font = [UIFont systemFontOfSize:12];
        self.taskNameLabel.font = [UIFont systemFontOfSize:12];
        self.commentLabel.font = [UIFont systemFontOfSize:12];
        self.teacherNameLabel.font = [UIFont systemFontOfSize:12];
        
        self.nameLabel.textColor = [UIColor detailColor];
        self.taskNameLabel.textColor = [UIColor detailColor];
        self.commentLabel.textColor = [UIColor detailColor];
        self.teacherNameLabel.textColor = [UIColor detailColor];
    }
    
    self.nameLabel.text = name;
    self.taskNameLabel.text = title;
    self.commentLabel.text = comment;
    self.teacherNameLabel.text = teacher;
    [self.imageV sd_setImageWithURL:[image imageURLWithWidth:36] placeholderImage:[UIImage imageNamed:@"attachment_placeholder"]];
}

+ (CGFloat)cellHeightWithZeroMessage:(StudentZeroTask *)zeroData{
  
    CGFloat height = 0.f;
    static MIZeroMessagesTableViewCell *zeroCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        zeroCell = [[[NSBundle mainBundle] loadNibNamed:@"MIZeroMessagesTableViewCell"
                                                      owner:nil
                                                    options:nil] lastObject];
        
    });
    
    [zeroCell setupImage:zeroData.avatar
                    name:zeroData.nickName
               taskTitle:zeroData.title
                 comment:zeroData.content
                 teacher:zeroData.createTeacher
                   index:1];
    CGSize size = [zeroCell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    height = size.height;
    if (height < 56) {
        height = 56;
    }
    return height;
}

@end
