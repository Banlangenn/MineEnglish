//
//  AudioPlayer.m
//  X5Teacher
//
//  Created by yebw on 2018/3/27.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "AudioPlayer.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AFNetworking/AFNetworking.h>

NSString * const kNotificationOfAudioPlayerStateDidChange = @"kNotificationOfAudioPlayerStateDidChange";

@interface AudioPlayer()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, assign) BOOL kvoInstalled;

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@end

@implementation AudioPlayer

+ (instancetype)sharedPlayer {
    static AudioPlayer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AudioPlayer alloc] init];
    });
    
    return instance;
}

- (void)installKVO {
    if (self.kvoInstalled) {
        return;
    }
    
    if (self.player == nil) {
        return;
    }
    
    self.kvoInstalled = YES;
    
    [self.player addObserver:self
                  forKeyPath:@"rate"
                     options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                     context:nil];
}

- (void)uninstallKVO {
    if (!self.kvoInstalled) {
        return;
    }
    
    self.kvoInstalled = NO;
    
    [self.player removeObserver:self forKeyPath:@"rate"];
}

- (void)addNotificationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioDidPlayToEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
}

- (void)removeNotificationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"rate"]) {
        float rate = [change[NSKeyValueChangeNewKey] floatValue];
        if (rate != 0.0f) {
            if (_state != AudioPlayerPlaying) {
                _state = AudioPlayerPlaying;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOfAudioPlayerStateDidChange
                                                                    object:nil];
            }
        } else {
            if (_state != AudioPlayerStop) {
                _state = AudioPlayerStop;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOfAudioPlayerStateDidChange
                                                                    object:nil];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)audioDidPlayToEnd:(NSNotification *)notification {
    if (_state != AudioPlayerStop) {
        _state = AudioPlayerStop;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOfAudioPlayerStateDidChange
                                                            object:nil];
    }
    
    [self stop];
}

- (void)playURL:(NSURL *)url {
    [self stop];
    
    //    url = [NSURL URLWithString:@"http://file.zhengminyi.com/9ff9f4d47864e27a04ec.wav"];
    
    if (url == nil) {
        return;
    }
    
    _currentURL = url;
    
    NSURL *path = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSURL *audioFileURL = [path URLByAppendingPathComponent:url.lastPathComponent];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:audioFileURL.path]) {
        [self playWithLocalFileURL:audioFileURL];
    } else {
        [self downloadUrl:url completionHandler:^(NSURL *localFileURL) {
            if (localFileURL != nil) {
                [self playWithLocalFileURL:localFileURL];
            }
        }];
    }
}

- (void)playLocalURL:(NSString *)url{
   
    [self stop];
    if (url == nil) {
        return;
    }
    NSString *path = [[NSBundle mainBundle] pathForResource:url ofType:@"mp3"];
    if (path.length > 0) {

        [self playWithLocalFileURL:[NSURL fileURLWithPath:path]];
        self.player.volume = 0.5;
    }
}

- (void)playWithLocalFileURL:(NSURL *)fileURL {
    
    self.player = [[AVPlayer alloc] initWithURL:fileURL];
    [self installKVO];
    [self addNotificationObserver];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    
    [self.player play];
}

- (void)stop {
    [self.player pause];
    [self.downloadTask cancel];
    self.downloadTask = nil;
    
    [self uninstallKVO];
    [self removeNotificationObserver];
    
    _currentURL = nil;
    _state = AudioPlayerStop;
    
    self.player = nil;
    
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)downloadUrl:(NSURL *)url completionHandler:(void (^)(NSURL *localFileURL))completionHandler {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    self.downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSURL *path = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [path URLByAppendingPathComponent:url.lastPathComponent];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable fileURL, NSError * _Nullable error) {
        if (fileURL!=nil && error==nil) {
            completionHandler(fileURL);
        } else {
            completionHandler(nil);
        }
    }];
    
    [self.downloadTask resume];
}

@end



