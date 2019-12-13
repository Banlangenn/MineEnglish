//
//  MIEidtFileView.h
//  MinnieManager
//
//  Created by songzhen on 2019/6/2.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^DeleteFileCallback)(void);

typedef void(^RenameFileCallback)(void);

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,MIEidtFileViewStyle) {
    
    MIEidtFileViewVertical,
    MIEidtFileViewHorizontal,
};

@interface MIEidtFileView : UIView

@property (nonatomic,copy) void(^oneBtnCallback)(void);
@property (nonatomic,copy) void(^twoBtnCallBack)(void);

- (void)setupTextColor:(UIColor *)textColor
               bgColor:(UIColor *)bgColor
              oneTitle:(NSString *)oneTitle
              twoTitle:(NSString *)twoTitle
          cornerRadius:(CGFloat)radius
                offset:(CGPoint)offset
                 style:(MIEidtFileViewStyle)style;


@end

NS_ASSUME_NONNULL_END
