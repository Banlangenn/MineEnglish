//
//  Replay.m
//  test
//
//  Created by songzhen on 2019/9/3.
//  Copyright © 2019 songzhen. All rights reserved.
//

#import "Replay.h"
#import <Photos/Photos.h>

@interface Replay ()<RPPreviewViewControllerDelegate>
/**开始录制*/
@property (nonatomic,strong)UIButton *startBt;
/**结束录制*/
@property (nonatomic,strong)UIButton *endBt;
@property(strong,nonatomic)UIWindow *window;
@end

@implementation Replay
#pragma mark ---懒加载
-(UIButton*)startBt{
    if(!_startBt){
        _startBt=[[UIButton alloc] initWithFrame:CGRectMake(0,0,80,50)];
        _startBt.backgroundColor=[UIColor redColor];
        [_startBt setTitle:@"开始录制" forState:UIControlStateNormal];
        _startBt.titleLabel.font=[UIFont systemFontOfSize:14];
        [_startBt addTarget:self action:@selector(startAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startBt;
}
-(UIButton*)endBt{
    if(!_endBt){
        _endBt=[[UIButton alloc] initWithFrame:CGRectMake(0,60,80,50)];
        _endBt.backgroundColor=[UIColor redColor];
        [_endBt setTitle:@"结束录制" forState:UIControlStateNormal];
        _endBt.titleLabel.font=[UIFont systemFontOfSize:14];
        [_endBt addTarget:self action:@selector(endAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _endBt;
}
/**
 是否显示录制按钮
 */
-(void)catreButton:(BOOL)iscate{
    if (!iscate) return;
    [self performSelector:@selector(createWidow) withObject:nil afterDelay:1];
}
-(void)createWidow{
    self.window =[[UIWindow alloc]initWithFrame:CGRectMake(0, 100, 80, 120)];
    self.window.backgroundColor=[UIColor clearColor];
    self.window.windowLevel = UIWindowLevelAlert+1;
    [self.window makeKeyAndVisible];
    [self.window addSubview:self.startBt];
    [self.window addSubview:self.endBt];
}
//单例化对象
+(instancetype)sharedReplay{
    static Replay *replay=nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        replay=[[Replay alloc] init];
    });
    return replay;
}
-(void)startAction{
    [_startBt setTitle:@"初始化中" forState:UIControlStateNormal];
    [[Replay sharedReplay] startRecord];
}
-(void)endAction{
    [_startBt setTitle:@"开始录制" forState:UIControlStateNormal];
    [[Replay sharedReplay] stopRecordAndShowVideoPreviewController:YES];
}
//是否正在录制
-(BOOL)isRecording{
    return [RPScreenRecorder sharedRecorder].recording;
}
#pragma mark - 开始/结束录制
//开始录制
-(void)startRecord{
    if ([RPScreenRecorder sharedRecorder].recording==YES) {
        NSLog(@"FJReplayKit:已经开始录制");
        return;
    }
    if ([self systemVersionOK]) {
        if ([[RPScreenRecorder sharedRecorder] isAvailable]) {
            NSLog(@"FJReplayKit:录制开始初始化");
            [[RPScreenRecorder sharedRecorder] startRecordingWithMicrophoneEnabled:YES handler:^(NSError *error){
                if (error) {
                    NSLog(@"FJReplayKit:开始录制error %@",error);
                    if ([self.delegate respondsToSelector:@selector(replayRecordFinishWithVC:errorInfo:)]) {
                        [self.delegate replayRecordFinishWithVC:nil errorInfo:[NSString stringWithFormat:@"FJReplayKit:开始录制error %@",error]];
                    }
                }else{
                    NSLog(@"FJReplayKit:开始录制");
                    [self.startBt setTitle:@"正在录制" forState:UIControlStateNormal];
                    if ([self.delegate respondsToSelector:@selector(replayRecordStart)]) {
                        [self.delegate replayRecordStart];
                    }
                }
            }];
        }
        else {
            NSLog(@"FJReplayKit:环境不支持ReplayKit录制");
            if ([_delegate respondsToSelector:@selector(replayRecordFinishWithVC:errorInfo:)]) {
                [_delegate replayRecordFinishWithVC:nil errorInfo:@"FJReplayKit:环境不支持ReplayKit录制"];
            }
        }
    }
    else{
        NSLog(@"FJReplayKit:系统版本需要是iOS9.0及以上才支持ReplayKit录制");
        if ([_delegate respondsToSelector:@selector(replayRecordFinishWithVC:errorInfo:)]) {
            [_delegate replayRecordFinishWithVC:nil errorInfo:@"FJReplayKit:系统版本需要是iOS9.0及以上才支持ReplayKit录制"];
        }
    }
}
//结束录制
-(void)stopRecordAndShowVideoPreviewController:(BOOL)isShow{
    NSLog(@"FJReplayKit:正在结束录制");
    [[RPScreenRecorder sharedRecorder] stopRecordingWithHandler:^(RPPreviewViewController *previewViewController, NSError *  error){
        [self.startBt setTitle:@"开始录制" forState:UIControlStateNormal];
        if (error) {
            NSLog(@"FJReplayKit:结束录制error %@", error);
            if ([self.delegate respondsToSelector:@selector(replayRecordFinishWithVC:errorInfo:)]) {
                [self.delegate replayRecordFinishWithVC:nil errorInfo:[NSString stringWithFormat:@"FJReplayKit:结束录制error %@",error]];
            }
        }
        else {
            NSLog(@"FJReplayKit:录制完成");
            if ([self.delegate respondsToSelector:@selector(replayRecordFinishWithVC:errorInfo:)]) {
                [self.delegate replayRecordFinishWithVC:previewViewController errorInfo:@""];
            }
//            if (isShow) {
//                [self showVideoPreviewController:previewViewController animation:YES];
//            }
            
            // 获取movieURL
            if (previewViewController) {

                NSURL *videoURL = [previewViewController valueForKey:@"movieURL"];
                // 保存到系统相册
                  BOOL compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([videoURL path]);
                  if (compatible) {
                      
                      //保存相册核心代码
                      UISaveVideoAtPathToSavedPhotosAlbum([videoURL path], self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
                  } else {
                      NSLog(@"没有找到 movieURL");
                  }
            }
        }
    }];
}
#pragma mark - 视频保存到相册
//保存视频完成之后的回调
- (void)savedPhotoImage:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    
    if (error) {
        NSLog(@"保存视频失败%@", error.localizedDescription);
    } else {
        NSLog(@"保存视频成功");
        [self readVideoFromSystomAlbum];
    }
}


#pragma mark - 读取相册视频
- (void)readVideoFromSystomAlbum{
   
    // 获取相册
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL * _Nonnull stop) {
       
        PHFetchOptions *options = [PHFetchOptions new];
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i", PHAssetMediaTypeVideo];
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection options:options];

        // 取出最后一个视频并压缩
        PHAsset *asset = result.lastObject;
        [[PHImageManager defaultManager] requestExportSessionForVideo:asset options:nil exportPreset:AVAssetExportPresetPassthrough resultHandler:^(AVAssetExportSession *exportSession, NSDictionary *info) {
                
                // 指定导出路径
                NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
                NSString *docsDir = [dirPaths objectAtIndex:0];
                NSString *videoPath = [docsDir stringByAppendingPathComponent:@"replayVideo.acc"];
                // 已存在删除
                NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:videoPath]];
                if (data.length >0) {
                    [[NSFileManager defaultManager] removeItemAtPath:videoPath
                                                               error:nil];
                }
            
                NSURL *outputURL = [NSURL fileURLWithPath:videoPath];
                exportSession.outputFileType=AVFileTypeMPEG4;
                exportSession.outputURL=outputURL;
                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                    if (exportSession.status == AVAssetExportSessionStatusFailed) {
                        NSLog(@"failed");
                    } else if(exportSession.status == AVAssetExportSessionStatusCompleted){
                        NSLog(@"completed!");
                        if (self.delegate && [self.delegate respondsToSelector:@selector(replayRecordFinishWithPath:)]) {
                            
                            [self.delegate replayRecordFinishWithPath:outputURL];
                        }
                    }
                }];
        }];
    }];
}

#pragma mark - 显示/关闭视频预览页
//显示视频预览页面
-(void)showVideoPreviewController:(RPPreviewViewController *)previewController animation:(BOOL)animation {
    previewController.previewControllerDelegate=self;
    __weak UIViewController *rootVC=[self getRootVC];
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect rect = [UIScreen mainScreen].bounds;
        if (animation) {
            rect.origin.x+=rect.size.width;
            previewController.view.frame=rect;
            rect.origin.x-=rect.size.width;
            [UIView animateWithDuration:0.3 animations:^(){
                previewController.view.frame=rect;
            }];
        }
        else{
            previewController.view.frame=rect;
        }
        
        [rootVC.view addSubview:previewController.view];
        [rootVC addChildViewController:previewController];
    });
}
//关闭视频预览页面
-(void)hideVideoPreviewController:(RPPreviewViewController *)previewController animation:(BOOL)animation {
    previewController.previewControllerDelegate=nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect rect = previewController.view.frame;
        if (animation) {
            rect.origin.x+=rect.size.width;
            [UIView animateWithDuration:0.3 animations:^(){
                previewController.view.frame=rect;
            }completion:^(BOOL finished){
                [previewController.view removeFromSuperview];
                [previewController removeFromParentViewController];
            }];
        }
        else{
            [previewController.view removeFromSuperview];
            [previewController removeFromParentViewController];
        }
    });
}
#pragma mark - 视频预览页回调
//关闭的回调
- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController {
    [self hideVideoPreviewController:previewController animation:YES];
}
//选择了某些功能的回调（如分享和保存）
- (void)previewController:(RPPreviewViewController *)previewController didFinishWithActivityTypes:(NSSet <NSString *> *)activityTypes {
    if ([activityTypes containsObject:@"com.apple.UIKit.activity.SaveToCameraRoll"]) {
      
        NSLog(@"FJReplayKit:保存到相册成功");
        if ([_delegate respondsToSelector:@selector(saveSuccess)]) {
            [_delegate saveSuccess];
        }
    }
    if ([activityTypes containsObject:@"com.apple.UIKit.activity.CopyToPasteboard"]) {
        NSLog(@"FJReplayKit:复制成功");
    }
}
#pragma mark - 其他方法
//判断对应系统版本是否支持ReplayKit
-(BOOL)systemVersionOK{
    if ([[UIDevice currentDevice].systemVersion floatValue]<9.0) {
        return NO;
    } else {
        return YES;
    }
}
//获取rootVC
-(UIViewController *)getRootVC{
    return [UIApplication sharedApplication].delegate.window.rootViewController;
}
@end
