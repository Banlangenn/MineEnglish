//
//  SendAudioManager.m
//  MinnieStudent
//
//  Created by songzhen on 2019/4/29.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "AudioPlayerManager.h"

@interface AudioPlayerManager (){
    
    id _progressObserve; // 监听进度
    
    
    NSInteger _seekToTime;
}
@property (nonatomic,retain) AVPlayer *audioPlayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, copy) NSString *currentUrl;


@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, assign) BOOL preparePlay;

@property (nonatomic, assign) BOOL isSeek;


@end



@implementation AudioPlayerManager


- (instancetype)initWithUrl:(NSString *)url{
    
    self = [super init];
    if (self) {
        _currentUrl = url;
    }
    return self;
}

- (void)play:(BOOL)play{
    
    if (play) {
        _preparePlay = YES;
        if (isnan(CMTimeGetSeconds(self.playerItem.duration))) {
            // 资源未加载
            if (_currentUrl.length) {
                [self playWithUrl:_currentUrl];
            }
        } else {
            
            if (self.current >= self.duration) {
                [self.audioPlayer seekToTime:kCMTimeZero];
            }
            [self.audioPlayer play];
            self.isPlaying = [self playState];
        }
    } else {
        _preparePlay = NO;
        [self.audioPlayer pause];
    }
}

- (void)playWithUrl:(NSString *)url{
    
    [self removePlayerProgress];
    
    if ([[url substringToIndex:4] isEqualToString:@"http"]) {
        
        self.playerItem = [[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:url]];
    } else {
        NSString *path = [[NSBundle mainBundle] pathForResource:url ofType:@"mp3"];
        self.playerItem = [[AVPlayerItem alloc]initWithURL:[NSURL fileURLWithPath:path]];
    }
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    self.audioPlayer = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.audioPlayer.volume = 0.5;
    [self addPlayerProgress];
    [self.audioPlayer play];
    
    // iOS10兼容问题：AVPlayer新增属性automaticallyWaitsToMinimizeStalling
    // 解决新系统下播放失效问题（现象：缓冲完成才开始播放）
    if(@available(iOS 10.0, *)){
        
        _audioPlayer.automaticallyWaitsToMinimizeStalling = NO;
    }
}

// 快进后退
- (void)seekToTime:(NSInteger)time{
 
    if (isnan(CMTimeGetSeconds(self.playerItem.duration))) {
        
        _isSeek = YES;
        _seekToTime = time;
        [self play:YES];
    } else {
        
        if (self.current >= self.duration) {
            self.current = time;
        }
        CMTime tempTime = CMTimeMake(time, 1);
        [self.playerItem seekToTime:tempTime];
        [self play:YES];
    }
}

#pragma mark - 进度
- (void)removePlayerProgress{
    
    if (_progressObserve) {
        
        [self.audioPlayer removeTimeObserver:_progressObserve];
        _progressObserve = nil;
    }
}

- (void)addPlayerProgress{
    
    if (!_progressObserve) {
        WeakifySelf;
        // 监听进度
        _progressObserve = [self.audioPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            
            if (!weakSelf) return;
            if (weakSelf.isSeek) return;
            if (weakSelf.progressBlock) {
                
                CGFloat currentTime = weakSelf.playerItem.currentTime.value/weakSelf.playerItem.currentTime.timescale;// 计算当前在第几秒
                CGFloat duration = CMTimeGetSeconds(weakSelf.playerItem.duration);
                
                if (currentTime > duration) {
                    currentTime = duration;
                }
                weakSelf.progressBlock(currentTime, duration);
                weakSelf.current = currentTime;
                weakSelf.duration = duration;
            }
        }];
    }
}


#pragma mark - 播放完成 playbackFinished
- (void)playbackFinished:(NSNotification *)notice{
    
    _preparePlay = NO;
//    [self.audioPlayer seekToTime:kCMTimeZero];
    [self play:NO];
    self.current = self.duration;
    if (self.finishedBlock) {
        self.finishedBlock();
    }
}


#pragma 播放状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if (object == self.playerItem && [keyPath isEqualToString:@"status"]) {
        switch (self.playerItem.status) {
            case AVPlayerItemStatusUnknown:     // 未知状态，此时不能播放
            {
            }
                break;
            case AVPlayerItemStatusReadyToPlay: // 准备完毕，可以播放
                if (_isSeek) {
                    
                    [self seekToTime:_seekToTime];
                    _isSeek = NO;
                } else {
                    if (_preparePlay) {
                        
                        [_audioPlayer play];
                    }
                }
                self.duration = CMTimeGetSeconds(self.playerItem.duration);
                break;
            case AVPlayerItemStatusFailed:      // 加载失败，网络或者服务器出现问题
            {
                [HUD showErrorWithMessage:@"播放失败"];
            }
                break;
            default:
                break;
        }
        if (self.statusBlock) {
            self.statusBlock(self.playerItem.status);
        }
    } else if (object == _playerItem && [keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        
        // 缓存充足后需要手动播放
        if (_preparePlay) {
            
            [_audioPlayer play];
        }
    }
}

- (BOOL)playState{
    
    if (@available(iOS 10.0, *)) {
        
        // AVPlayer iOS10新增属性：timeControlStatus
        return _audioPlayer.timeControlStatus == AVPlayerTimeControlStatusPlaying ? YES : NO;
    }else{
        
        return _audioPlayer.rate == 1.0 ? YES : NO;
    }
}

#pragma mark 重置播放器
- (void)resetCurrentPlayer{
    
    _preparePlay = NO;
    [self.audioPlayer pause];
    [self.playerItem cancelPendingSeeks];
    [self.playerItem.asset cancelLoading];
    self.playerItem = nil;
    [_audioPlayer replaceCurrentItemWithPlayerItem:nil];
    [self removePlayerProgress];
    self.audioPlayer = nil;
}

#pragma mark - setter && getter
- (void)setPlayerItem:(AVPlayerItem *)playerItem{
    
    if (_playerItem == playerItem) {return;}
    if (_playerItem) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    _playerItem = playerItem;
    
    if (playerItem) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        // 媒体加载状态
        [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        // 播放器在缓冲数据充足
        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
        
    }
}

- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
