//
//  MIExpandPickerView.m
//  MinnieManager
//
//  Created by songzhen on 2019/6/3.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "MIExpandPickerView.h"

@interface MIExpandPickerView ()<
UIPickerViewDataSource,
UIPickerViewDelegate>{
    
    
    NSInteger minIndex;
    NSInteger secIndex;
}
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;

@property (nonatomic, strong) NSDateComponents *comp;
@property (nonatomic, strong) NSMutableArray * minArray;
@property (nonatomic, strong) NSMutableArray * secArray;

@property (nonatomic, strong) NSMutableArray * fileLocationArray;

@property (nonatomic, assign) MIHomeworkCreateContentType createType;

@property (nonatomic, strong) UILabel * minLabel;

@property (nonatomic, strong) UILabel * secLabel;

@end

@implementation MIExpandPickerView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
}

// 子文件夹位置选择
- (void)setDefultFileInfo:(FileInfo *)fileInfo fileArray:(NSArray<ParentFileInfo*>*)fileArray{
    
    self.createType = MIHomeworkCreateContentType_Localtion;
    for (NSInteger i = 0; i < fileArray.count; i++) {
        
        ParentFileInfo *parentInfo = fileArray[i];
        if (fileInfo.parentId == parentInfo.fileInfo.fileId) {
            
            [self.fileLocationArray removeAllObjects];
            [self.fileLocationArray addObjectsFromArray:parentInfo.subFileList];
            for (NSInteger j = 0; j < parentInfo.subFileList.count; j++) {
                FileInfo *subInfo = parentInfo.subFileList[j];
                if (fileInfo.fileId == subInfo.fileId) {
                    secIndex = j;
                    break;
                }
            }
            break;
        }
    }
    [self.pickerView selectRow:secIndex inComponent:0 animated:YES];
    [self pickerView:self.pickerView didSelectRow:secIndex inComponent:0];
}

// 父文件夹位置选择
- (void)setDefultParentFileInfo:(FileInfo *)fileInfo fileArray:(NSArray<ParentFileInfo*>*)fileArray{
    
    self.createType = MIHomeworkCreateContentType_Localtion;
    [self.fileLocationArray removeAllObjects];
    [self.fileLocationArray addObjectsFromArray:fileArray];
    for (NSInteger i = 0; i < fileArray.count; i++) {
        
        ParentFileInfo *parentInfo = fileArray[i];
        if (fileInfo.fileId == parentInfo.fileInfo.fileId) {
            secIndex = i;
            break;
        }
    }
    [self.pickerView selectRow:secIndex inComponent:0 animated:YES];
    [self pickerView:self.pickerView didSelectRow:secIndex inComponent:0];
}

- (void)setDefultText:(NSString *)text createType:(MIHomeworkCreateContentType)createType{
    
    self.createType = createType;
    if (createType == MIHomeworkCreateContentType_TimeLimit ||
        createType == MIHomeworkCreateContentType_VideoTimeLimit
        ) { // 0-5分
        
        NSInteger secs = text.integerValue;
        secIndex = secs % 60;
        minIndex = secs / 60;
        
        [self.bgView addSubview:_minLabel];
        [self.bgView addSubview:_secLabel];
        [self selectActionToPickerView:self.pickerView row:minIndex inComponent:0];
        [self selectActionToPickerView:self.pickerView row:secIndex inComponent:1];
    } else if (createType == MIHomeworkCreateContentType_WordsTimeInterval) {// 1-9秒
        
        NSInteger secs = text.floatValue/1000;
        NSInteger row = secs - 1;
        if (row <= 0 ||  row >= self.secArray.count) {
           row = 0;
        }
        [self.bgView addSubview:_secLabel];
        [self.pickerView selectRow:row inComponent:0 animated:YES];
        [self pickerView:self.pickerView didSelectRow:row inComponent:0];
    }
}

- (void)addMinAndSecLabel
{
    CGFloat pointX = ([UIScreen mainScreen].bounds.size.width - 180) / 2 + 65;

    UILabel * minLabel = [[UILabel alloc]initWithFrame:CGRectMake(pointX, self.bgView.frame.size.height/2-15/2.0 + 26, 15, 15)];
    minLabel.text = @"分";
    minLabel.textAlignment = NSTextAlignmentCenter;
    minLabel.font = [UIFont systemFontOfSize:14];
    minLabel.textColor =  [UIColor blackColor];
    minLabel.backgroundColor = [UIColor clearColor];
    [self.bgView addSubview:minLabel];
    
    pointX = ([UIScreen mainScreen].bounds.size.width - 180) / 2 + 90 + 65;
    
    UILabel * secLabel = [[UILabel alloc]initWithFrame:CGRectMake(pointX, self.bgView.frame.size.height/2-15/2.0 + 26, 15, 15)];
    secLabel.text = @"秒";
    secLabel.textAlignment = NSTextAlignmentCenter;
    secLabel.font = [UIFont systemFontOfSize:14];
    secLabel.textColor =  [UIColor blackColor];
    secLabel.backgroundColor = [UIColor clearColor];
    [self.bgView addSubview:secLabel];
}

#pragma mark - Date Data

- (NSMutableArray *)minArray {
    if (_minArray == nil) {
        _minArray = [NSMutableArray array];
        for (int min = 0; min <= 5; min++) {
            NSString *str = [NSString stringWithFormat:@"%d", min];
            [_minArray addObject:str];
        }
    }
    return _minArray;
}

- (NSMutableArray *)secArray {
    if (self.createType == MIHomeworkCreateContentType_TimeLimit ||
        self.createType == MIHomeworkCreateContentType_VideoTimeLimit) {
       
        if (_secArray == nil) {
            _secArray = [NSMutableArray array];
            for (int sec = 0; sec <= 59; sec++) {
                NSString *str = [NSString stringWithFormat:@"%02d", sec];
                [_secArray addObject:str];
            }
        }
    } else if (self.createType == MIHomeworkCreateContentType_WordsTimeInterval) {
        if (_secArray == nil) {
            _secArray = [NSMutableArray array];
            for (int sec = 1; sec < 10; sec++) {
                NSString *str = [NSString stringWithFormat:@"%d", sec];
                [_secArray addObject:str];
            }
        }
    }
    return _secArray;
}

-(NSMutableArray *)fileLocationArray{
    
    if (_fileLocationArray == nil) {
        _fileLocationArray = [NSMutableArray array];
    }
    return _fileLocationArray;
}


- (UILabel *)minLabel{
    
    if (_minLabel == nil) {
        
        CGFloat pointX = ([UIScreen mainScreen].bounds.size.width - 180) / 2 + 65;
        _minLabel = [[UILabel alloc]initWithFrame:CGRectMake(pointX, self.bgView.frame.size.height/2-15/2.0 + 26, 15, 15)];
        _minLabel.text = @"分";
        _minLabel.textAlignment = NSTextAlignmentCenter;
        _minLabel.font = [UIFont systemFontOfSize:14];
        _minLabel.textColor =  [UIColor blackColor];
        _minLabel.backgroundColor = [UIColor clearColor];
    }
    return _minLabel;
}

- (UILabel *)secLabel{
    
    if (_secLabel == nil) {
        
         CGFloat pointX = ([UIScreen mainScreen].bounds.size.width - 180) / 2 + 90 + 65;
        
        _secLabel = [[UILabel alloc]initWithFrame:CGRectMake(pointX, self.bgView.frame.size.height/2-15/2.0 + 26, 15, 15)];
        _secLabel.text = @"秒";
        _secLabel.textAlignment = NSTextAlignmentCenter;
        _secLabel.font = [UIFont systemFontOfSize:14];
        _secLabel.textColor =  [UIColor blackColor];
        _secLabel.backgroundColor = [UIColor clearColor];

    }
    return _secLabel;
}
#pragma mark UIPickerView DataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
   
    if (self.createType == MIHomeworkCreateContentType_Localtion ||
        self.createType == MIHomeworkCreateContentType_WordsTimeInterval) {
        return 1;
    } else if (self.createType == MIHomeworkCreateContentType_TimeLimit ||
               self.createType == MIHomeworkCreateContentType_VideoTimeLimit) { // 0-5分
        return 2;
    }
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  
    if (self.createType == MIHomeworkCreateContentType_Localtion) {
        if (component == 0) {
            return self.fileLocationArray.count;
        }
    } else if (self.createType == MIHomeworkCreateContentType_TimeLimit ||
               self.createType == MIHomeworkCreateContentType_VideoTimeLimit) { // 0-5分
        if (component == 0) {
            return self.minArray.count;
        } else {
            return self.secArray.count;
        }
    } else if (self.createType == MIHomeworkCreateContentType_WordsTimeInterval) {
        if (component == 0) {
            return self.secArray.count;
        }
    }
    return 0;
}

-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 49;
}

-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
    
    return 150;
}

#pragma mark - UIPickerView Delegate
// 滚动UIPickerView就会调用
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
   
    if (self.createType == MIHomeworkCreateContentType_Localtion) {
        secIndex = row;
    } else if (self.createType == MIHomeworkCreateContentType_TimeLimit ||
               self.createType == MIHomeworkCreateContentType_VideoTimeLimit) { // 0-5分
       
        if (component == 0) {
            minIndex = row;
            if (minIndex == 5 && secIndex != 0)
            {
                [self selectActionToPickerView:pickerView row:0 inComponent:1];
            }
        }
        else
        {
            secIndex = row;
            
            if (minIndex == 5 && secIndex != 0)
            {
                [self selectActionToPickerView:pickerView row:0 inComponent:1];
            }
            
        }
    } else if (self.createType == MIHomeworkCreateContentType_WordsTimeInterval) {
        secIndex = row;
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
   
    //设置文字的属性
    UILabel *genderLabel = [[UILabel alloc] init];
    genderLabel.textAlignment = NSTextAlignmentCenter;
    if (self.createType == MIHomeworkCreateContentType_Localtion) {
        id fileObjec = self.fileLocationArray[row];
        if ([fileObjec isKindOfClass:[FileInfo class]]) {
            
            FileInfo *fileInfo = self.fileLocationArray[row];
            genderLabel.text = fileInfo.fileName;
        } else if ([fileObjec isKindOfClass:[ParentFileInfo class]]){
            
            ParentFileInfo *fileInfo = self.fileLocationArray[row];
            genderLabel.text = fileInfo.fileInfo.fileName;
        }
    } else if (self.createType == MIHomeworkCreateContentType_TimeLimit ||
               self.createType == MIHomeworkCreateContentType_VideoTimeLimit) { // 0-5分
        if (component == 0) {
            genderLabel.text = self.minArray[row];
        }else {
            genderLabel.text = self.secArray[row];
        }
    } else if (self.createType == MIHomeworkCreateContentType_WordsTimeInterval) {
        genderLabel.text = self.secArray[row];
    }
    return genderLabel;
}

- (void)selectActionToPickerView:(UIPickerView *)pickerView row:(NSInteger)row inComponent:(NSInteger)inComponent {
    [pickerView selectRow:row inComponent:inComponent animated:YES];
    [self pickerView:pickerView didSelectRow:row inComponent:inComponent];
}

#pragma mark - Animated

- (void)show {
    self.frame = [UIScreen mainScreen].bounds;
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [self showActionAnimated];
}

- (void)hide {
    [self hideActionAnimated];
}

- (void)showActionAnimated {
    
    CATransform3D translate = CATransform3DMakeTranslation(0, ScreenHeight, 0); //平移
    self.bgView.layer.transform = translate;
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];

    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        self.bgView.layer.transform = CATransform3DIdentity;
    } completion:nil];
}

- (void)hideActionAnimated {
    CATransform3D translate = CATransform3DMakeTranslation(0, ScreenHeight, 0); //平移
    self.bgView.layer.transform = CATransform3DIdentity;
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];

    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
        self.bgView.layer.transform = translate;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - Action
- (IBAction)cancelBtn:(id)sender {
    
    [self hide];
}

- (IBAction)sureBtn:(id)sender {
    
    if (self.createType == MIHomeworkCreateContentType_Localtion) {
        
        if (self.localCallback) {
            if (secIndex < self.fileLocationArray.count) {
               
                self.localCallback(self.fileLocationArray[secIndex]);
            }
        }
    } else if (self.createType == MIHomeworkCreateContentType_TimeLimit ||
               self.createType == MIHomeworkCreateContentType_VideoTimeLimit) { // 0-5分
        NSString *min = [NSString stringWithFormat:@"%lu",minIndex * 60 + secIndex];
        if (self.callback) {
            self.callback(min);
        }
    } else if (self.createType == MIHomeworkCreateContentType_WordsTimeInterval) {
        if (self.callback) {
            NSString *intervalStr = self.secArray[secIndex];
            CGFloat wordsTime = intervalStr.floatValue * 1000;
            self.callback([NSString stringWithFormat:@"%d",(int)wordsTime]);
        }
    }
  
    [self hide];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self hideActionAnimated];
}

#pragma mark - 获取文件夹列表


@end
