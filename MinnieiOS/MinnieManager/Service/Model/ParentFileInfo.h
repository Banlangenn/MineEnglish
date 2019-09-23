//
//  ParentFileInfo.h
//  MinnieManager
//
//  Created by songzhen on 2019/6/1.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <Mantle/Mantle.h>

@protocol FileInfo <NSObject>

@end

@protocol HomeworkFileDto <NSObject>

@end

// 文件夹内容信息
@interface FileInfo : MTLModel<MTLJSONSerializing>

// 返回目录id
@property (nonatomic ,assign) NSInteger fileId;

// 文件夹名称
@property (nonatomic ,copy) NSString *fileName;

// 父文件夹id
@property (nonatomic ,assign) NSInteger parentId;

// 文件夹深度 1一级文件夹 2二级文件夹
@property (nonatomic ,assign) NSInteger depth;

// 二级目录作业总数
@property (nonatomic ,assign) NSInteger homeworkNum;


// 一级文件夹展开、折叠
@property (nonatomic ,assign) BOOL isOpen;

@property (nonatomic ,assign) BOOL canLookFile;


@end


// 一级文件夹
@interface ParentFileInfo : MTLModel<MTLJSONSerializing>

// 文件夹信息
@property (nonatomic ,strong) FileInfo *fileInfo;

// 子文件夹列表
@property (nonatomic ,strong) NSArray<FileInfo> *subFileList;


@end

// 作业所在文件夹信息
@interface HomeworkFileDto : MTLModel<MTLJSONSerializing>

// 一级文件夹信息
@property (nonatomic ,strong) FileInfo *parentFile;
// 二级文件夹信息
@property (nonatomic ,strong) FileInfo *subFile;


@end
