//
//  ParentFileInfo.m
//  MinnieManager
//
//  Created by songzhen on 2019/6/1.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import "ParentFileInfo.h"

@implementation FileInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
    return @{@"fileId":@"id",
             @"fileName":@"fileName",
             @"parentId":@"parentId",
             @"depth":@"depth",
             @"homeworkNum":@"homeworkNum"
             };
}
@end

@implementation ParentFileInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
    return @{@"fileInfo":@"fileInfo",
             @"subFileList":@"subFileList"};
}

+ (NSValueTransformer *)fileInfoJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[FileInfo class]];
}

+ (NSValueTransformer *)subFileListJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[FileInfo class]];
}

@end

@implementation HomeworkFileDto

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
    return @{@"parentFile":@"parentFile",
             @"subFile":@"subFile"};
}

+ (NSValueTransformer *)parentFileJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[FileInfo class]];
}

+ (NSValueTransformer *)subFileJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[FileInfo class]];
}

@end
