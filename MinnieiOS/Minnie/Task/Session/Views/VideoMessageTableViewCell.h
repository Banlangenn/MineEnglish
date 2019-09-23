//
//  VideoMessageTableViewCell.h
//  X5
//
//  Created by yebw on 2017/10/14.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageTableViewCell.h"

typedef void(^VideoMessageTableViewCellPlayCallback)(void);

extern CGFloat const VideoMessageTableViewCellHeight;

extern NSString * const LeftVideoMessageTableViewCellId;
extern NSString * const RightVideoMessageTableViewCellId;

@interface VideoMessageTableViewCell : MessageTableViewCell


@property (nonatomic, copy) void(^shareVideoUrlCallBack)(NSString *_Nullable shareVideoUrl);

@property (nonatomic, copy) VideoMessageTableViewCellPlayCallback videoPlayCallback;


- (void)setupSelectedVideo:(BOOL)selected;

@end
