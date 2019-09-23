//
//  ManagerRequest.h
//  MinnieManager
//
//  Created by songzhen on 2019/6/1.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "BaseRequest.h"
#import "ParentFileInfo.h"
#import "ActivityInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface ManagerRequest : BaseRequest

@end

#pragma mark - 新建任务管理文件夹
@interface CeateFilesRequest : BaseRequest

- (instancetype)initWithCeateFilesData:(FileInfo *)data;

@end


#pragma mark - 获取任务管理文件夹

@interface GetFilesRequest : BaseRequest

- (instancetype)initWithFileId:(NSInteger)fileId;

@end

#pragma mark - 删除任务管理文件夹

@interface DelFilesRequest : BaseRequest

- (instancetype)initWithFileId:(NSInteger) fileId;

@end

#pragma mark - 获取一级任务管理文件夹（设置权限用）
@interface GetParentFilesRequest : BaseRequest

@end

#pragma mark - 任务位置移动
@interface MoveFilesRequest : BaseRequest

- (instancetype)initWithFileId:(NSInteger) fileId
                      parentId:(NSInteger)parentId
                   homeworkIds:(NSArray *)homeworkIds;

@end

#pragma mark - 根据目录获取任务列表

@interface HomeworksByFileRequest : BaseRequest

- (instancetype)initWithFileId:(NSInteger)fileId
                      sortType:(NSInteger)sortType
                       nextUrl:(NSString *_Nullable)nextUrl;

@end

#pragma mark - 获取任务类型
#pragma mark - 删除任务类型
#pragma mark - 增加任务类型
@interface GetWorkTypesRequest : BaseRequest

@end


#pragma mark - 任务得分列表
@interface ScoreListByHomeworkRequest : BaseRequest

- (instancetype)initWithHomeworkId:(NSInteger)homeworkId
                         teacherId:(NSInteger)teacherId
                           nextUrl:(NSString *_Nullable)nextUrl;

@end


#pragma mark - 新建活动（ipad管理端）
@interface ActCreateRequest : BaseRequest

- (instancetype)initWithActivityInfo:(ActivityInfo *)activityInfo;

@end

#pragma mark - 删除活动(ipad管理端)
@interface ActDeleteRequest : BaseRequest

- (instancetype)initWithActId:(NSInteger)actId;

@end

#pragma mark - 获取活动任务列表（ipad管理端&学生端）
@interface ActGetRequest : BaseRequest

@end


#pragma mark - 获取活动任务详情（ipad管理端&学生端）
@interface ActDetailGetRequest : BaseRequest

- (instancetype)initWithActId:(NSInteger)actId;

@end

#pragma mark - 结束活动(ipad管理端)

#pragma mark - 获取活动排名(ipad管理端)
@interface ActGetActivityRankRequest : BaseRequest

- (instancetype)initWithActId:(NSInteger)actId;

@end

#pragma mark - 获取活动排名(学生端)
@interface ActGetStuActRankRequest : BaseRequest

- (instancetype)initWithActId:(NSInteger)actId;

@end

#pragma mark - 上传活动视频(学生端)
@interface ActCommitActRequest : BaseRequest

- (instancetype)initWithActId:(NSInteger)actId
                     actTimes:(NSInteger)actTimes
                       actUrl:(NSString *)actUrl;

@end


#pragma mark - 我的上传（学生&ipad管理端）
@interface ActLogsRequest : BaseRequest

- (instancetype)initWithActId:(NSInteger)actId
                        stuId:(NSInteger)stuId;

@end


#pragma mark - 视频审阅（ipad管理端）
@interface VideoCorrectActRequest : BaseRequest

// 上传的记录id  1合格；2不合格
- (instancetype)initWithVideoId:(NSInteger)videoId isOk:(NSInteger)isOk actId:(NSInteger)actId;

@end

#pragma mark - 新建编辑校区（ipad管理端)
@interface CreateCampusRequest : BaseRequest

- (instancetype)initWithName:(NSString *)name campusId:(NSInteger)campusId;

@end

#pragma mark - 校区列表（ipad管理端）
@interface CampusInfoRequest : BaseRequest

@end

#pragma mark - 删除校区（ipad管理端)
@interface DeleteCampusRequest : BaseRequest

- (instancetype)initWithCampusId:(NSInteger)campusId;

@end

#pragma mark - 2.1.17    上下线管理（ipad）
@interface OnlineStateRequest : BaseRequest

- (instancetype)initWithOnline:(BOOL)online
                         times:(NSInteger)times;

@end



#pragma mark - 2.16.1    欢迎页上传（ipad管理端）
@interface UpWelcomesRequest: BaseRequest

- (instancetype)initWithImageUrls:(NSArray *)urls;

@end


#pragma mark - 2.16.2    返回欢迎页（学生端，ipad管理端）
@interface GetWelcomesRequest: BaseRequest

- (instancetype)initWithType:(NSInteger)type;

@end

NS_ASSUME_NONNULL_END
