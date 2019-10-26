//
//  DownloadCacheVideo.h
//  Minnie
//
//  Created by songzhen on 2019/10/12.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloadCacheVideo : NSObject

- (void)startDownloadWithUrl:(NSString *)vedioUrl
               extensionName:(NSString *)extensionName;

+ (NSString *)cachedFilePathForURL:(NSURL *)url
                     extensionName:(NSString *)extensionName;
- (void)cancelDownload;

// 缓存目录
+ (NSString *)cacheDirectory;

// 清理缓存
+ (BOOL)clearTmpDirectory;
+ (BOOL)clearCachesDirectory;

// 缓存大小
+ (NSNumber *)sizeOfTmpDirectory;
+ (NSNumber *)sizeCachesDirectory;

@end

NS_ASSUME_NONNULL_END
