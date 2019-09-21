//
//  MIPlayerViewController.h
//  Minnie
//
//  Created by songzhen on 2019/9/20.
//  Copyright © 2019 minnieedu. All rights reserved.
//  视频播放，添加保存

#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MIPlayerViewController : AVPlayerViewController

- (void)showSaveVideo:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
