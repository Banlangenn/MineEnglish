//
//  ClassEditTableViewCell.m
//  X5Teacher
//
//  Created by yebw on 2018/1/28.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "ClassEditTableViewCell.h"

NSString * const ClassEditTableViewCellId = @"ClassEditTableViewCellId";
CGFloat const ClassEditTableViewCellHeight = 276.f;

@interface ClassEditTableViewCell()

@property (nonatomic, strong) IBOutletCollection(UIImageView) NSArray *arrowImageViews;

@end

@implementation ClassEditTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.startTimeButton.layer.cornerRadius = 12.f;
    self.startTimeButton.layer.masksToBounds = YES;
    
    self.endTimeButton.layer.cornerRadius = 12.f;
    self.endTimeButton.layer.masksToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupWithClass:(Clazz *)clazz {
    if (clazz.isFinished) {
        self.userInteractionEnabled = NO;
        
        for (UIImageView *arrowImageView in self.arrowImageViews) {
            arrowImageView.hidden = YES;
        }
    }
    
    self.classNameTextField.text = clazz.name;
    self.classLocationTextField.text = clazz.location;
    self.classTeacherTextField.text = clazz.teacher.nickname;
    
    [self.startTimeButton setTitle:clazz.startTime forState:UIControlStateNormal];
    [self.endTimeButton setTitle:clazz.endTime forState:UIControlStateNormal];

    if (clazz.maxStudentsCount > 0) {
        self.classStudentsTextField.text = [NSString stringWithFormat:@"%zd", clazz.maxStudentsCount];
    } else {
        self.classStudentsTextField.text = nil;
    }
    NSString *trial;
    if (clazz.trial == 1) {
        trial = @"春季";
    } else if (clazz.trial == 2) {
        trial = @"夏季";
    } else {
        trial = @"秋季";
    }
    self.classTypeTextField.text = trial;
    NSArray * pickList = @[@"零基础",@"1级",@"2级",@"3级",@"4级",@"5级",@"6级",@"7级"];
    self.classLevelTextField.text = [pickList objectAtIndex:clazz.classLevel];
}

- (void)textDidChange:(NSNotification *)notification {
   
    if (self.classNameTextField.isFirstResponder) {
        if (self.nameChangedCallback != nil) {
            self.nameChangedCallback([self.classNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]);
        }
    }
//    else if (self.classLocationTextField.isFirstResponder) {
//        if (self.locationChangedCallback != nil) {
//            self.locationChangedCallback([self.classLocationTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]);
//        }
//    }
}

- (IBAction)startTimeButtonPressed:(id)sender {
    if (self.selectStartTimeCallback != nil) {
        self.selectStartTimeCallback();
    }
}

- (IBAction)endTimerButtonPressed:(id)sender {
    if (self.selectEndTimeCallback != nil) {
        self.selectEndTimeCallback();
    }
}

- (IBAction)localButtonPressed:(id)sender {
    
    if (self.locationChangedCallback) {
        self.locationChangedCallback();
    }
}


- (IBAction)teacherButtonPressed:(id)sender {
    if (self.selectTeacherCallback != nil) {
        self.selectTeacherCallback();
    }
}

- (IBAction)studentsCountButtonPressed:(id)sender {
    if (self.selectStudentsCountCallback != nil) {
        self.selectStudentsCountCallback();
    }
}

- (IBAction)classTypeButtonPressed:(id)sender {
    if (self.selectClassTypeCallback != nil) {
        self.selectClassTypeCallback();
    }
}

- (IBAction)classLevelButtonPressed:(id)sender {
    if (self.selectClassLevelCallback != nil) {
        self.selectClassLevelCallback();
    }
}


@end

