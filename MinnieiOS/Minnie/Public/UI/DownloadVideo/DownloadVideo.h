//
//  DownloadVideo.h
//  Minnie
//
//  Created by songzhen on 2019/9/19.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloadVideo : NSObject

@property (nonatomic,copy) void (^successCallBack) (BOOL success);

@property (nonatomic,copy) void (^progressCallBack) (CGFloat progress);


- (void)startDownloadVedioWithUrl:(NSString *)vedioUrl;

@end

NS_ASSUME_NONNULL_END
