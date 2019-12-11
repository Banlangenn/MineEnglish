//
//  MICreateWordView.m
//  MinnieManager
//
//  Created by songzhen on 2019/6/6.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "MICreateWordView.h"

@interface MICreateWordView ()
@property (weak, nonatomic) IBOutlet UITextField *English;
@property (weak, nonatomic) IBOutlet UITextField *chinese;
@property (weak, nonatomic) IBOutlet UIView *bgView;

@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;

@property (weak, nonatomic) IBOutlet UIButton *sureBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bgTopConstraint;

@property (strong, nonatomic) NSMutableDictionary *wordsDict;

@end

@implementation MICreateWordView

- (void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    
    self.sureBtn.layer.borderWidth = 0.5;
    self.sureBtn.layer.borderColor = [UIColor mainColor].CGColor;
    
    self.cancelBtn.layer.borderWidth = 0.5;
    self.cancelBtn.layer.borderColor = [UIColor mainColor].CGColor;
    [self.English becomeFirstResponder];
    [self addObserverOfKeyBoardChanged];
    self.wordsDict = [NSMutableDictionary dictionary];
    self.word = [[WordInfo alloc] init];
}

- (IBAction)cancelAction:(id)sender {
    if (self.superview) {
        [self removeFromSuperview];
    }
}
- (IBAction)sureAction:(id)sender {
 
    [self.English resignFirstResponder];
    [self.chinese resignFirstResponder];
    if (self.word.english.length == 0) {
        [HUD showErrorWithMessage:@"请输入英文单词"];
        return;
    }
    if (self.word.chinese.length == 0) {
        [HUD showErrorWithMessage:@"请输入中文意思"];
        return;
    }
    if (self.wordsDict[self.word.english]) {
      
        [HUD showErrorWithMessage:@"该单词已存在"];
        return;
    }
    if (self.callback) {
        self.callback(self.word);
    }
    if (self.superview) {
        [self removeFromSuperview];
    }
}

- (void)setWords:(NSArray *)words{
    
    _words = words;
    [self.wordsDict removeAllObjects];
    for (WordInfo *info in _words) {
        if (info.english) {
            [self.wordsDict setValue:info forKey:info.english];
        }
    }
}

- (void)setWord:(WordInfo *)word{
    
    _word = word;
    self.English.text = _word.english;
    self.chinese.text = _word.chinese;
}

- (IBAction)textFieldChanged:(UITextField *)sender {
    self.word.english = sender.text;
}
- (IBAction)chineseTextFieldChanged:(UITextField *)sender {
       self.word.chinese = sender.text;
}
- (IBAction)englishAction:(id)sender {
    UITextField *textField = sender;
    self.word.english = textField.text;
}

- (IBAction)chineseAction:(id)sender {
    UITextField *textField = sender;
    self.word.chinese = textField.text;
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.English resignFirstResponder];
    [self.chinese resignFirstResponder];

}
- (void)addObserverOfKeyBoardChanged {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification{
    
    //取出键盘动画的时间
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    WeakifySelf;
    [UIView animateWithDuration:duration animations:^{
        
        weakSelf.bgTopConstraint.constant = (ScreenHeight - 250)/2.0 - keyboardFrame.size.height/3.0;
    }];
}
#pragma mark --键盘收回
- (void)keyboardDidHide:(NSNotification *)notification{
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    WeakifySelf;
    [UIView animateWithDuration:duration animations:^{
        
        weakSelf.bgTopConstraint.constant = (ScreenHeight - 250)/2.0;
    }];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
