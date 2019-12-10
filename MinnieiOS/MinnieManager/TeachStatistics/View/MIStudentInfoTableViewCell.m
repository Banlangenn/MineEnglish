//
//  MIStudentInfoTableViewCell.m
//  MinnieManager
//
//  Created by songzhen on 2019/12/9.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "MIStudentInfoTableViewCell.h"

NSString *const MIStudentInfoTableViewCellId = @"MIStudentInfoTableViewCellId";

@interface MIStudentInfoTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *genderLabel;
@property (weak, nonatomic) IBOutlet UILabel *classLabel;
@property (weak, nonatomic) IBOutlet UIView *bgView;

@end

@implementation MIStudentInfoTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.bgView.layer.masksToBounds = YES;
    self.bgView.layer.cornerRadius = 10.f;
}

- (void)setupStudentInfo:(Student *)student{
    
    self.phoneLabel.text = student.phoneNumber;
    
    NSString *gender;
    if (student.gender == 0) {
        gender = @"保密";
    } else if (student.gender == 1) {
        gender = @"男";
    } else {
        gender = @"女";
    }
    self.genderLabel.text = gender;
    self.classLabel.text = student.clazz.name;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
