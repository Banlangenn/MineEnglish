//
//  Homework.m
//  X5
//
//  Created by yebw on 2017/9/17.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "Homework.h"

@implementation Homework

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"homeworkId":@"id",
             @"createTeacher":@"createTeacher",
             @"title":@"title",
             @"items":@"items",
             @"answerItems":@"answerItems",
             @"createTime":@"createTime",
             @"tags":@"tags",
             @"style":@"style",
             @"level":@"level",
             @"category":@"category",
             @"limitTimes":@"limitTimes",
             @"formTag":@"formTag",
             @"teremark":@"teremark",
             @"fileInfos":@"fileInfos",
             @"typeName":@"typeName",
             @"examType":@"examType",
             @"otherItem":@"otherItem",
             @"videoCount":@"videoCount",
             @"imageCount":@"pictureCount"
             };
}

+ (NSValueTransformer *)createTeacherJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[Teacher class]];
}

+ (NSValueTransformer *)correctTeacherJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[Teacher class]];
}

+ (NSValueTransformer *)itemsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[HomeworkItem class]];
}

+ (NSValueTransformer *)otherItemJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[HomeworkItem class]];
}

+ (NSValueTransformer *)answerItemsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[HomeworkAnswerItem class]];
}

+ (NSValueTransformer *)fileInfosJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[HomeworkFileDto class]];
}


- (NSDictionary *)dictionaryForUpload {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    // 表示是更新的
    if (self.homeworkId > 0) {
        dict[@"id"] = @(self.homeworkId);
    }
    
    dict[@"title"] = self.title;
    dict[@"createTeacher"] = @{@"id":@(self.createTeacher.userId)};
    
    
    NSMutableArray *otherItems = [NSMutableArray array];
    for (HomeworkItem *item in self.otherItem) {
        NSMutableDictionary *itemDict = [NSMutableDictionary dictionary];
        itemDict[@"type"] = item.type;
        if ([item.type isEqualToString:HomeworkItemTypeText]) {
            itemDict[@"text"] = item.text;
        } else if ([item.type isEqualToString:HomeworkItemTypeAudio]) {
            itemDict[@"audioUrl"] = item.audioUrl;
            itemDict[@"audioCoverUrl"] = item.audioCoverUrl;
        } else if ([item.type isEqualToString:HomeworkItemTypeVideo]) {
            itemDict[@"videoUrl"] = item.videoUrl;
            itemDict[@"videoCoverUrl"] = item.videoCoverUrl;
        } else if ([item.type isEqualToString:HomeworkItemTypeImage]) {
            itemDict[@"imageUrl"] = item.imageUrl;
            itemDict[@"imageWidth"] = @(item.imageWidth);
            itemDict[@"imageHeight"] = @(item.imageHeight);
        }
        [otherItems addObject:itemDict];
    } dict[@"otherItem"] = otherItems;
    
    NSMutableArray *items = [NSMutableArray array];
    dict[@"items"] = items;
    for (HomeworkItem *item in self.items) {
        NSMutableDictionary *itemDict = [NSMutableDictionary dictionary];
        itemDict[@"type"] = item.type;
        if ([item.type isEqualToString:HomeworkItemTypeText]) {
            itemDict[@"text"] = item.text;
        } else if ([item.type isEqualToString:HomeworkItemTypeAudio]) {
            itemDict[@"audioUrl"] = item.audioUrl;
            itemDict[@"audioCoverUrl"] = item.audioCoverUrl;
        } else if ([item.type isEqualToString:HomeworkItemTypeVideo]) {
            itemDict[@"videoUrl"] = item.videoUrl;
            itemDict[@"videoCoverUrl"] = item.videoCoverUrl;
        } else if ([item.type isEqualToString:HomeworkItemTypeImage]) {
            itemDict[@"imageUrl"] = item.imageUrl;
            itemDict[@"imageWidth"] = @(item.imageWidth);
            itemDict[@"imageHeight"] = @(item.imageHeight);
        } else if ([item.type isEqualToString:HomeworkItemTypeWord]) {
            
            NSMutableArray *words = [NSMutableArray array];
            for (WordInfo *word in item.words) {
                NSMutableDictionary *wordDic = [NSMutableDictionary dictionary];
                wordDic[@"english"] = word.english;
                wordDic[@"chinese"] = word.chinese;
                [words addObject:wordDic];
            }
            itemDict[@"words"] = words;
            itemDict[@"bgmusicUrl"] = item.bgmusicUrl;
            itemDict[@"playtime"] = @(item.playtime);
            itemDict[@"playMode"] = @(item.playMode);
        }
        [items addObject:itemDict];
    }
    
    NSMutableArray *answserItems = [NSMutableArray array];
    dict[@"answerItems"] = answserItems;
    for (HomeworkAnswerItem *item in self.answerItems) {
        NSMutableDictionary *itemDict = [NSMutableDictionary dictionary];
        itemDict[@"type"] = item.type;
        if ([item.type isEqualToString:HomeworkItemTypeVideo]) {
            itemDict[@"videoUrl"] = item.videoUrl;
            itemDict[@"videoCoverUrl"] = item.videoCoverUrl;
        }else if ([item.type isEqualToString:HomeworkItemTypeAudio]) {
            itemDict[@"audioUrl"] = item.audioUrl;
            itemDict[@"audioCoverUrl"] = item.audioCoverUrl;
        }else if ([item.type isEqualToString:HomeworkItemTypeImage]) {
            itemDict[@"imageUrl"] = item.imageUrl;
            itemDict[@"imageWidth"] = @(item.imageWidth);
            itemDict[@"imageHeight"] = @(item.imageHeight);
        }
        [answserItems addObject:itemDict];
    }
    NSDictionary *parentFile;
    if (self.fileInfos.parentFile.parentId == 0) {
        parentFile = @{@"id":@(self.fileInfos.parentFile.fileId),
                       @"fileName":self.fileInfos.parentFile.fileName,
                       @"depth":@(self.fileInfos.parentFile.depth)
                                     };
    } else {
        
        parentFile = @{@"id":@(self.fileInfos.parentFile.fileId),
                       @"fileName":self.fileInfos.parentFile.fileName,
                       @"parentId":@(self.fileInfos.parentFile.parentId),
                       @"depth":@(self.fileInfos.parentFile.depth)
                                     };
    }
    
    NSDictionary *subFile = @{@"id":@(self.fileInfos.subFile.fileId),
                              @"fileName":self.fileInfos.subFile.fileName,
                              @"parentId":@(self.fileInfos.subFile.parentId),
                              @"depth":@(self.fileInfos.subFile.depth)
                                 };
   
    dict[@"fileInfos"] = @{@"parentFile":parentFile,@"subFile":subFile};
    
    dict[@"tags"] = self.tags;
    dict[@"style"] = @(self.style);
    dict[@"level"] = @(self.level);
    dict[@"category"] = @(self.category);
    dict[@"limitTimes"] = @(self.limitTimes);
    dict[@"formTag"] = self.formTag;
    dict[@"teremark"] = self.teremark;
    dict[@"typeName"] = self.typeName;
    dict[@"examType"] = @(self.examType);
    dict[@"pictureCount"] = @(self.imageCount);
    dict[@"videoCount"] = @(self.videoCount);
    
    return dict;
}


- (Homework *)newHomework{
    
    Homework *tempHomework = [[Homework alloc] init];
    tempHomework.homeworkId = self.homeworkId;
//    tempHomework.createTeacher = self.createTeacher;
    tempHomework.title = self.title;
    tempHomework.items = [self newItemsWithArray:self.items];
    tempHomework.otherItem = [self newItemsWithArray:self.otherItem];
    tempHomework.answerItems = [self newAnswerItemsWithArray:self.answerItems];
    tempHomework.createTime = self.createTime;
    
    NSMutableArray *tempTags = [NSMutableArray array];
    for (NSString *tag in self.tags) {
        NSString *tempTag = [NSString stringWithString:tag];
        [tempTags addObject:tempTag];
    }
    tempHomework.tags = tempTags;
    
    tempHomework.style = self.style;
    tempHomework.level = self.level;
    tempHomework.category = self.category;
    tempHomework.limitTimes = self.limitTimes;
    tempHomework.formTag = self.formTag;
    tempHomework.teremark = self.teremark;
    tempHomework.fileInfos = [self newFileInfo:self.fileInfos];
    tempHomework.typeName = self.typeName;
    tempHomework.examType = self.examType;
    tempHomework.videoCount = self.videoCount;
    tempHomework.imageCount = self.imageCount;
    tempHomework.cellHeight = self.cellHeight;
    
    return tempHomework;
}

- (HomeworkFileDto *)newFileInfo:(HomeworkFileDto *)fileInfo{
    
    HomeworkFileDto *tempFileInfo = [[HomeworkFileDto alloc] init];

    FileInfo *tempSubFileInfo = [[FileInfo alloc] init];
    tempSubFileInfo.fileId = fileInfo.subFile.fileId;
    tempSubFileInfo.fileName = fileInfo.subFile.fileName;
    tempSubFileInfo.parentId = fileInfo.subFile.parentId;
    tempSubFileInfo.depth = fileInfo.subFile.depth;
    tempSubFileInfo.isOpen = fileInfo.subFile.isOpen;
    
    FileInfo *tempParentInfo = [[FileInfo alloc] init];
    tempParentInfo.fileId = fileInfo.parentFile.fileId;
    tempParentInfo.fileName = fileInfo.parentFile.fileName;
    tempParentInfo.parentId = fileInfo.parentFile.parentId;
    tempParentInfo.depth = fileInfo.parentFile.depth;
    tempParentInfo.isOpen = fileInfo.parentFile.isOpen;
    
    tempFileInfo.subFile = tempSubFileInfo;
    tempFileInfo.parentFile = tempParentInfo;
    return tempFileInfo;
}

- (NSArray *)newItemsWithArray:(NSArray *)items{
    
    NSMutableArray *tempItems = [NSMutableArray array];
    for (HomeworkItem *item in items) {
        
        HomeworkItem *tempItem = [[HomeworkItem alloc] init];
        tempItem.type = item.type;
        tempItem.text = item.text;
        tempItem.audioUrl = item.audioUrl;
        tempItem.audioCoverUrl = item.audioCoverUrl;
        tempItem.videoUrl = item.videoUrl;
        tempItem.videoCoverUrl = item.videoCoverUrl;
        tempItem.imageUrl = item.imageUrl;
        tempItem.imageWidth = item.imageWidth;
        tempItem.imageHeight = item.imageHeight;
        tempItem.itemTime = item.itemTime;
        
        NSMutableArray *tempWords = [NSMutableArray array];
        for (WordInfo *word in item.words) {
            WordInfo *tempWord = [[WordInfo alloc] init];
            tempWord.english = word.english;
            tempWord.chinese = word.chinese;
            [tempWords addObject:tempWord];
        }
        tempItem.words = (NSArray<WordInfo>*)tempWords;
        
        tempItem.bgmusicUrl = item.bgmusicUrl;
        tempItem.playtime = item.playtime;
        tempItem.playMode = item.playMode;
        [tempItems addObject:tempItem];
    }
    return tempItems;
}

- (NSArray *)newAnswerItemsWithArray:(NSArray *)items{
    
    NSMutableArray *tempItems = [NSMutableArray array];
    for (HomeworkAnswerItem *item in items) {
        
        HomeworkAnswerItem *tempItem = [[HomeworkAnswerItem alloc] init];
        tempItem.type = item.type;
        tempItem.audioUrl = item.audioUrl;
        tempItem.audioCoverUrl = item.audioCoverUrl;
        tempItem.videoUrl = item.videoUrl;
        tempItem.videoCoverUrl = item.videoCoverUrl;
        tempItem.imageUrl = item.imageUrl;
        tempItem.imageWidth = item.imageWidth;
        tempItem.imageHeight = item.imageHeight;
        tempItem.itemTime = item.itemTime;
        [tempItems addObject:tempItem];
    }
    return tempItems;
}
@end

