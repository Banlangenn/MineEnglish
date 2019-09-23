//
//  ManagerServce.h
//  MinnieManager
//
//  Created by songzhen on 2019/6/1.
//  Copyright © 2019 minnieedu. All rights reserved.
//
#import "Result.h"
#import "BaseRequest.h"
#import "CampusInfo.h"
#import "ActivityInfo.h"
#import "ParentFileInfo.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ManagerServce : NSObject

#pragma mark - 任务管理

// 新建任务管理文件夹
+ (BaseRequest *)requestCreateFilesWithFileDto:(FileInfo *)fileDto callback:(RequestCallback)callback;


// 获取任务管理文件夹
+ (BaseRequest *)requestGetFilesWithFileId:(NSInteger)fileId callback:(RequestCallback)callback;

// 删除任务管理文件夹
+ (BaseRequest *)requestDelFilesWithFileId:(NSInteger)fileId callback:(RequestCallback)callback;

// 任务位置移动 
+ (BaseRequest *)requestMoveFilesWithFileId:(NSInteger)fileId
                                   parentId:(NSInteger)parentId
                                homeworkIds:(NSArray *)homeworkIds
                                   callback:(RequestCallback)callback;

// 根据目录获取任务列表
+ (BaseRequest *)requesthomeworksByFileWithFileId:(NSInteger)fileId
                                         sortType:(NSInteger)sortType
                                          nextUrl:(NSString *_Nullable)nextUrl
                                         callback:(RequestCallback)callback;

// 获取任务类型
+ (BaseRequest *)requestGetWorkTypesWithCallback:(RequestCallback)callback;

// 任务得分列表
+ (BaseRequest *)requestScoreListByHomeworkId:(NSInteger)homeworkId
                                    teacherId:(NSInteger)teacherId
                                      nextUrl:(NSString *_Nullable)nextUrl
                                     callback:(RequestCallback)callback;


// 获取一级任务管理文件夹（设置权限用）
+ (BaseRequest *)requestAllParentFileListWithCallback:(RequestCallback)callback;


#pragma mark - 活动管理

// 新建活动（ipad管理端）
+ (BaseRequest *)requestCreateActivity:(ActivityInfo *)activityInfo callback:(RequestCallback)callback;

// 删除活动(ipad管理端) 进行中的活动不能删除，活动开始前和结束后的可以删除
+ (BaseRequest *)requestDeleteActivityId:(NSInteger)actId callback:(RequestCallback)callback;

// 获取活动任务列表（ipad管理端&学生端）
+ (BaseRequest *)requestGetActivityListWithCallback:(RequestCallback)callback;

// 获取活动任务详情（ipad管理端&学生端）
+ (BaseRequest *)requestGetActivityDetailWithActId:(NSInteger)actId callback:(RequestCallback)callback;

// 结束活动(ipad管理端)

// 获取活动排名(ipad管理端)
+ (BaseRequest *)requestGetActivityRankListWithActId:(NSInteger)actId callback:(RequestCallback)callback;

// 获取活动排名(学生端)
+ (BaseRequest *)requestGetStuActivityRankListWithActId:(NSInteger)actId callback:(RequestCallback)callback;
    
// 上传活动视频(学生端)
+ (BaseRequest *)requestCommitActivityId:(NSInteger)actId
                                actTimes:(NSInteger)actTimes
                                  actUrl:(NSString *)actUrl
                                callback:(RequestCallback)callback;

// 我的上传（学生&ipad管理端）
+ (BaseRequest *)requestactLogsActivityId:(NSInteger)actId
                                    stuId:(NSInteger)stuId
                                 callback:(RequestCallback)callback;


// 视频审阅（ipad管理端）
+ (BaseRequest *)requestCorrectActVideoId:(NSInteger)videoId
                                     isOk:(NSInteger)isOk
                                    actId:(NSInteger)actId
                                 callback:(RequestCallback)callback;

#pragma mark - 校区管理
// 2.14.1    新建校区/编辑（ipad管理端）
+ (BaseRequest *)requestCreateCampusWithName:(NSString *)name
                                    campusId:(NSInteger)campusId
                                    callback:(RequestCallback)callback;

// 校区列表（ipad管理端）
+ (BaseRequest *)requestCampusCallback:(RequestCallback)callback;

// 删除校区（ipad管理端）
+ (BaseRequest *)requestDeleteCampusWithCampusId:(NSInteger)campusId
                                  callback:(RequestCallback)callback;

#pragma mark - 上下线管理
// 上下线管理 times:在线时长 （分钟）
+ (BaseRequest *)requestUpdateOnlineState:(BOOL)online
                                    times:(NSInteger)times
                           callback:(RequestCallback)callback;


#pragma mark - 2.16.1    欢迎页上传（ipad管理端）
+ (BaseRequest *)uploadWelcomesWithImages:(NSArray *)images
                        callback:(RequestCallback)callback;


#pragma mark - 2.16.2    返回欢迎页（学生端，ipad管理端）
+ (BaseRequest *)getWelcomesImagesWithType:(NSInteger)type
                                  callback:(RequestCallback)callback;

@end


NS_ASSUME_NONNULL_END
