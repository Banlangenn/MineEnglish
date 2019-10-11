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

@property (nonatomic,copy) NSString *vedioUrl;

@end

@implementation DownloadVideo

- (void)startDownloadVedioWithUrl:(NSString *)vedioUrl{
    self.vedioUrl = vedioUrl;
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:vedioUrl]];
    [self.downloadTask resume];
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    CGFloat progress = totalBytesWritten / (double)totalBytesExpectedToWrite;
    if (self.progressCallBack) {
        self.progressCallBack(progress);
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
  
    NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileName = [NSString stringWithFormat:@"%@.mp4",[downloadTask.response.suggestedFilename stringByDeletingPathExtension]];
    NSString *file = [cache stringByAppendingPathComponent:fileName];

    
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:file] error:&error];

    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(file)) {
        UISaveVideoAtPathToSavedPhotosAlbum(file, self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
    } else {
       [HUD showErrorWithMessage:@"视频保存失败"];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                      didResumeAtOffset:(int64_t)fileOffset
                                     expectedTotalBytes:(int64_t)expectedTotalBytes{
    

    [HUD showErrorWithMessage:@"视频保存失败"];
}

//保存视频完成之后的回调
- (void)savedPhotoImage:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    if (error) {
        [HUD showErrorWithMessage:@"视频保存失败"];
        if (self.successCallBack) {
            self.successCallBack(NO);
        }
    } else {
        [HUD showWithMessage:@"视频保存成功"];
        if (self.successCallBack) {
            self.successCallBack(YES);
        }
        
        NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *file = [cache stringByAppendingPathComponent:[self.vedioUrl stringByDeletingPathExtension]];
        file = [NSString stringWithFormat:@"%@.mp4",file];
        if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
            [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
        }
    }
}

@end
