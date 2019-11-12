//
//  FileUploader.m
//  AVFileDemo
//
//  Created by yebw on 2018/3/30.
//  Copyright © 2018年 netease. All rights reserved.
//

#import "FileUploader.h"
#import "FileUploaderService.h"

#import "QNTokenModel.h"
#import "Result.h"
@interface FileUploader()

@property(nonatomic,assign)NSInteger expiresTime;
@property(nonatomic,strong)NSString * upToken;
@end

@implementation FileUploader

+(FileUploader *)shareInstance
{
    static FileUploader * obj;
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        obj = [[FileUploader alloc] init];
    });
    return obj;
}

- (void)qn_uploadData:(NSData *)data
                 type:(UploadFileType)type
               option:(QNUploadOption *)option
      completionBlock:(void (^)(NSString * _Nullable, NSError * _Nullable))completionBlock
{
    //获取七牛云的token
    NSInteger nowTime = [self currentTime];
    if (self.expiresTime > nowTime)
    {
        //直接上传
        [self uploadData:data uploadToken:self.upToken option:option completionBlock:completionBlock];
    }
    else
    {
        //先获取token
        WeakifySelf;
        [FileUploaderService askForQNUploadTokenWithCallback:^(Result *result, NSError *error) {
            if (error != nil) {
                [HUD showErrorWithMessage:@"获取七牛云上传token失败"];
                return;
            }
            StrongifySelf;
            QNTokenModel * model = (QNTokenModel *)(result.userInfo);
            self.expiresTime = nowTime + model.expires;
            self.upToken = model.upToken;
            [strongSelf uploadData:data uploadToken:model.upToken option:option completionBlock:completionBlock];
            
        }];
    }
}

- (void)qn_uploadFile:(NSString *)file
                 type:(UploadFileType)type
               option:(QNUploadOption *)option
      completionBlock:(void (^)(NSString * _Nullable, NSError * _Nullable))completionBlock
{
    NSInteger nowTime = [self currentTime];
    if (self.expiresTime > nowTime)
    {
        //直接上传
        [self uploadFile:file uploadToken:self.upToken option:option completionBlock:completionBlock];
    }
    else
    {
        //先获取token
        WeakifySelf;
        [FileUploaderService askForQNUploadTokenWithCallback:^(Result *result, NSError *error) {
            if (error != nil) {
                [HUD showErrorWithMessage:@"获取七牛云上传token失败"];
                return;
            }
            StrongifySelf;
            QNTokenModel * model = (QNTokenModel *)(result.userInfo);
            self.expiresTime = nowTime + model.expires;
            self.upToken = model.upToken;
            [strongSelf uploadFile:file uploadToken:model.upToken option:option completionBlock:completionBlock];
            
        }];
    }
}

- (void)uploadData:(NSData *)data
              type:(UploadFileType)type
     progressBlock:(void (^)(NSInteger))progressBlock
   completionBlock:(void (^)(NSString * _Nullable, NSError * _Nullable))completionBlock {
    if (data.length == 0) {
        return;
    }
    
    NSString *extension = nil;
    if (type == UploadFileTypeAudio) {
        extension = @"aac";
    } else if (type == UploadFileTypeImage) {
        extension = @"jpg";
    } else if (type == UploadFileTypeVideo) {
        extension = @"mp4";
    } else if (type == UploadFileTypeWav) {
           extension = @"wav";
    }
    else if (type == UploadFileTypeAudio_Mp3)
    {
        extension = @"mp3";
    }
    
    NSString *name = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:extension];
    self.file = [AVFile fileWithData:data name:name];
    [self.file uploadWithProgress:progressBlock completionHandler:^(BOOL succeeded, NSError * _Nullable error) {
        if (completionBlock != nil) {
            completionBlock(self.file.url, error);
        }
    }];
    
}

- (void)uploadData:(NSData *)data
       uploadToken:(NSString *)token
            option:(QNUploadOption *)option
   completionBlock:(void (^)(NSString * _Nullable, NSError * _Nullable))completionBlock
{
    QNUploadManager *upManager = [[QNUploadManager alloc] init];
    [upManager putData:data key:nil token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        if (completionBlock != nil) {
            if (info.statusCode == 200) {
                NSString * imageUrl = [NSString stringWithFormat:@"http://res.zhengminyi.com/%@",resp[@"key"]];
                completionBlock(imageUrl, info.error);
            }
            else
            {
                completionBlock(nil, info.error);
            }
        }
    } option:option];
}

- (void)uploadFile:(NSString *)file
       uploadToken:(NSString *)token
            option:(QNUploadOption *)option
   completionBlock:(void (^)(NSString * _Nullable, NSError * _Nullable))completionBlock
{
    QNUploadManager *upManager = [[QNUploadManager alloc] init];
    [upManager putFile:file key:nil token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        if (completionBlock != nil ) {
            if (info.statusCode == 200) {
                NSString * imageUrl = [NSString stringWithFormat:@"http://res.zhengminyi.com/%@",resp[@"key"]];
                completionBlock(imageUrl, info.error);
            }
            else
            {
                completionBlock(nil, info.error);
            }
        }
    } option:option];
}

- (NSInteger)currentTime
{
    NSDate * date = [NSDate date];
    return [date timeIntervalSince1970];
}

- (void)cancleUploading
{
    [self.file cancelUploading];
}


- (void)uploadDataWithLocalFilePath:(NSString *)localFilePath
                      progressBlock:(void (^)(NSInteger))progressBlock
                    completionBlock:(void (^)(NSString * _Nullable, NSError * _Nullable))completionBlock {
    if (localFilePath.length == 0) {
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:localFilePath]) {
        return;
    }
    
    
    
    
    self.file = [AVFile fileWithLocalPath:localFilePath
                                       error:nil];
    [self.file uploadWithProgress:progressBlock completionHandler:^(BOOL succeeded, NSError * _Nullable error) {
        if (completionBlock != nil) {
            completionBlock(self.file.url, error);
        }
    }];
}

@end
