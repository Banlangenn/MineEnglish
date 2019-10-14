//
//  HomeworkAudioTableViewCell.h
//  X5Teacher
//
//  Created by yebw on 2018/1/24.
//  Copyright © 2018年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^HomeworkAudioTableViewCellPlayCallback)(NSString *);
typedef void(^HomeworkAudioTableViewCellDeleteCallback)(void);
typedef void(^HomeworkAudioTableViewCellDeleteFileCallback)(void);

extern NSString * const HomeworkAudioTableViewCellId;
extern CGFloat const HomeworkAudioTableViewCellHeight;
extern CGFloat const HomeworkAudioWithMp3TableViewCellHeight;

@interface HomeworkAudioTableViewCell : UITableViewCell


@property (nonatomic, copy) void (^imageCallback) (NSString *imageUrl);

@property (nonatomic, copy) void (^playAudioCallback) (NSString *imageUrl, NSString *audioUrl);

//@property (nonatomic, copy) HomeworkAudioTableViewCellPlayCallback playCallback;
@property (nonatomic, copy) HomeworkAudioTableViewCellDeleteCallback deleteCallback;
@property (nonatomic, copy) HomeworkAudioTableViewCellDeleteFileCallback deleteFileCallback;

//设置音频
- (void)setupWithAudioUrl:(NSString *)audioUrl
                 coverUrl:(NSString *)coverUrl;

@end


