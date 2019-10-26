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

@property (nonatomic,assign) BOOL showSaveBtn;


- (void)playVideoWithUrl:(NSString *)videoUrl;

// 音频播放
- (void)playAudioWithUrl:(NSString *)audioUrl coverUrl:(NSString *)cover;

@end

NS_ASSUME_NONNULL_END
