//
//  DownloadVideo.m
//  Minnie
//
//  Created by songzhen on 2019/9/19.
//  Copyright © 2019 minnieedu. All rights reserved.
//  视频下载

#import "DownloadVideo.h"

@interface DownloadVideo ()<NSURLSessionDownloadDelegate>

@property (nonatomic,strong) MBProgressHUD *hud;

@property (nonatomic,strong) NSURLSessionDownloadTask *downloadTask;


@end

@implementation DownloadVideo

- (void)startDownloadVedioWithUrl:(NSString *)vedioUrl{
    
    NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *file = [cache stringByAppendingPathComponent:[vedioUrl lastPathComponent]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
       
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(file)) {
            UISaveVideoAtPathToSavedPhotosAlbum(file, self, nil, nil);
            [HUD showWithMessage:@"保存成功"];
        }
        [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
    } else {
       
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        self.downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:vedioUrl]];
        [self.downloadTask resume];
    }
    
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    CGFloat progress = totalBytesWritten / (double)totalBytesExpectedToWrite;
    NSLog(@"progress %f",progress);
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
  
    NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *file = [cache stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:file] error:&error];
    
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(file)) {
        UISaveVideoAtPathToSavedPhotosAlbum(file, self, nil, nil);
        [HUD showWithMessage:@"保存成功"];
    }
}


@end
