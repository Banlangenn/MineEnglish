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

extern NSString * _Nullable const LeftVideoMessageTableViewCellId;
extern NSString * _Nullable const RightVideoMessageTableViewCellId;

@interface VideoMessageTableViewCell : MessageTableViewCell


@property (nonatomic, copy) void(^ _Nullable longPressGestureCallback)(NSString *_Nullable shareVideoUrl);

@property (nonatomic, copy) VideoMessageTableViewCellPlayCallback _Nullable videoPlayCallback;

- (void)setupSelectedVideo:(BOOL)selected;

@end
