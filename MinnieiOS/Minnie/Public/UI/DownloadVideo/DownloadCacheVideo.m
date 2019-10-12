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
    
    NSString *cacheDirectory = [DownloadCacheVideo cacheDirectory];
    NSString *pathComponent = [[url.absoluteString md5] md5];
    pathComponent = [pathComponent stringByAppendingPathExtension:@".mp4"];
    NSString *filePath = [cacheDirectory stringByAppendingPathComponent:pathComponent];

    return filePath;
}

+ (NSString *)cacheDirectory{
    
    NSString *cacheDirectory = [NSTemporaryDirectory() stringByAppendingFormat:@"taskMedia"];
    [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    return cacheDirectory;
}

#pragma mark     ************ 处理缓存 ************

#pragma mark 清空Cashes文件夹
+ (BOOL)clearCachesDirectory {
    NSArray *subFiles = [self listFilesInDirectoryAtPath:[self cachesDir] deep:NO];
    BOOL isSuccess = YES;
    
    for (NSString *file in subFiles) {
        NSString *absolutePath = [[self cachesDir] stringByAppendingPathComponent:file];
        isSuccess &= [self removeItemAtPath:absolutePath];
    }
    return isSuccess;
}
#pragma mark 清空temp文件夹
+ (BOOL)clearTmpDirectory {
    NSArray *subFiles = [self listFilesInDirectoryAtPath:[self tmpDir] deep:NO];
    BOOL isSuccess = YES;
    
    for (NSString *file in subFiles) {
        NSString *absolutePath = [[self tmpDir] stringByAppendingPathComponent:file];
        isSuccess &= [self removeItemAtPath:absolutePath];
    }
    return isSuccess;
}

#pragma mark - 文件遍历
/**
文件遍历
参数1：目录的绝对路径
参数2：是否深遍历 (1. 浅遍历：返回当前目录下的所有文件和文件夹；
2. 深遍历：返回当前目录下及子目录下的所有文件和文件夹)
*/
+ (NSArray *)listFilesInDirectoryAtPath:(NSString *)path deep:(BOOL)deep {
    NSArray *listArr;
    NSError *error;
    NSFileManager *manager = [NSFileManager defaultManager];
    if (deep) {
        // 深遍历
        NSArray *deepArr = [manager subpathsOfDirectoryAtPath:path error:&error];
        if (!error) {
            listArr = deepArr;
        }else {
            listArr = nil;
        }
    }else {
        // 浅遍历
        NSArray *shallowArr = [manager contentsOfDirectoryAtPath:path error:&error];
        if (!error) {
            listArr = shallowArr;
        }else {
            listArr = nil;
        }
    }
    return listArr;
}

#pragma mark - 判断文件(夹)是否存在
+ (BOOL)isDirectoryAtPath:(NSString *)path error:(NSError *__autoreleasing *)error {
    return ([self attributeOfItemAtPath:path forKey:NSFileType error:error] == NSFileTypeDirectory);
}

#pragma mark - 获取文件属性
+ (id)attributeOfItemAtPath:(NSString *)path forKey:(NSString *)key {
    return [[self attributesOfItemAtPath:path] objectForKey:key];
}

+ (NSDictionary *)attributesOfItemAtPath:(NSString *)path {
    return [self attributesOfItemAtPath:path error:nil];
}

+ (id)attributeOfItemAtPath:(NSString *)path forKey:(NSString *)key error:(NSError *__autoreleasing *)error {
    return [[self attributesOfItemAtPath:path error:error] objectForKey:key];
}

+ (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError *__autoreleasing *)error {
    return [[NSFileManager defaultManager] attributesOfItemAtPath:path error:error];
}

#pragma mark 获取文件夹的大小
+ (NSNumber *)sizeOfTmpDirectory{
    return [self sizeFormattedOfDirectoryAtPath:[self tmpDir] error:nil];
}
+ (NSNumber *)sizeCachesDirectory{
    return [self sizeFormattedOfDirectoryAtPath:[self cacheDirectory] error:nil];
}

+ (NSNumber *)sizeFormattedOfDirectoryAtPath:(NSString *)path error:(NSError *__autoreleasing *)error {
    //先获取NSNumber类型的大小
    NSNumber *size = [self sizeOfDirectoryAtPath:path error:error];
    if (size) {
//        return [self sizeFormatted:size];
        return size;
    }
    return nil;
}
+ (NSNumber *)sizeOfDirectoryAtPath:(NSString *)path error:(NSError *__autoreleasing *)error {
    if ([self isDirectoryAtPath:path error:error]) {
       //深遍历文件夹
        NSArray *subPaths = [self listFilesInDirectoryAtPath:path deep:YES];
        NSEnumerator *contentsEnumurator = [subPaths objectEnumerator];
        
        NSString *file;
        unsigned long long int folderSize = 0;
        
        while (file = [contentsEnumurator nextObject]) {
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:file] error:nil];
            folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
        }
        return [NSNumber numberWithUnsignedLongLong:folderSize];
    }
    return nil;
}

#pragma mark 将文件大小格式化为字节
+(NSString *)sizeFormatted:(NSNumber *)size {
    /*NSByteCountFormatterCountStyle枚举
     *NSByteCountFormatterCountStyleFile 字节为单位，采用十进制的1000bytes = 1KB
     *NSByteCountFormatterCountStyleMemory 字节为单位，采用二进制的1024bytes = 1KB
     *NSByteCountFormatterCountStyleDecimal KB为单位，采用十进制的1000bytes = 1KB
     *NSByteCountFormatterCountStyleBinary KB为单位，采用二进制的1024bytes = 1KB
     */
    return [NSByteCountFormatter stringFromByteCount:[size unsignedLongLongValue] countStyle:NSByteCountFormatterCountStyleFile];
}

#pragma mark - 删除文件(夹)
+ (BOOL)removeItemAtPath:(NSString *)path {
    return [self removeItemAtPath:path error:nil];
}

+ (BOOL)removeItemAtPath:(NSString *)path error:(NSError *__autoreleasing *)error {
    return [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}

#pragma mark 沙盒目录
+ (NSString *)cachesDir {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
}

+ (NSString *)tmpDir {
    return NSTemporaryDirectory();
}

@end
