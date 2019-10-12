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

- (void)startDownloadVedioWithUrl:(NSString *)vedioUrl;

+ (NSString *)cachedFilePathForURL:(NSURL *)url;

// 缓存目录
+ (NSString *)cacheDirectory;

@end

NS_ASSUME_NONNULL_END
