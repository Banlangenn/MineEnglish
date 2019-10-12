//
//  DownloadCacheVideo.m
//  Minnie
//
//  Created by songzhen on 2019/10/12.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "NSString+MD5.h"
#import "DownloadCacheVideo.h"

@interface DownloadCacheVideo ()<
NSURLSessionDownloadDelegate
>

@property (nonatomic,copy) NSString *videoPath;

@property (nonatomic,strong) NSURLSessionDownloadTask *downloadTask;

@end


@implementation DownloadCacheVideo


- (void)startDownloadVedioWithUrl:(NSString *)vedioUrl{
   
    self.videoPath = [DownloadCacheVideo cachedFilePathForURL:[NSURL URLWithString:vedioUrl]];
    
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
    
//    CGFloat progress = totalBytesWritten / (double)totalBytesExpectedToWrite;
//    NSLog(@"progress %f",progress);
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{

    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.videoPath error:nil];
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:self.videoPath] error:&error];
//    NSLog(@"缓存成功 %d %@ %@",success,self.videoPath,error);
}

+ (NSString *)cachedFilePathForURL:(NSURL *)url{
    
    NSString *cacheDirectory = [NSTemporaryDirectory() stringByAppendingFormat:@"taskMedia"];
    NSString *pathComponent = [[url.absoluteString md5] md5];
    pathComponent = [pathComponent stringByAppendingPathExtension:@".mp4"];
    
    NSString *filePath = [cacheDirectory stringByAppendingPathComponent:pathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];

    return filePath;
}

@end
