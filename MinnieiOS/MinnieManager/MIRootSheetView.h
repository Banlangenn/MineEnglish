//
//  RootSheetView.h
//  
//
//  Created by songzhen on 2019/5/27.
//  根模块视图

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MIManagerFuncModule) {
  
    MIManagerFuncRealTaskModule,            // 实时任务
    MIManagerFuncTeacherModule,             // 教师管理
    MIManagerFuncTaskModule,                // 任务管理
    MIManagerFuncActivityModule,            // 活动管理
    MIManagerFuncTeachingModule,            // 学员管理
    MIManagerFuncCampusModule,              // 校区管理
    MIManagerFuncGiftsModule,               // 礼物管理
    MIManagerFuncImagesModule,              // 图片管理
    MIManagerFuncAvatarModule,              // 用户头像
    MIManagerFuncSettingModule              // 设置
};

NS_ASSUME_NONNULL_BEGIN

@protocol RootSheetViewDelete <NSObject>

- (void)rootSheetViewClickedType:(MIManagerFuncModule)type;

@end

@interface MIRootSheetView : UIView

@property (nonatomic, weak) id<RootSheetViewDelete> delegate;

//@property (nonatomic,assign) NSInteger selectIndex;

@property (nonatomic,assign) MIManagerFuncModule selectType;

@end

NS_ASSUME_NONNULL_END
