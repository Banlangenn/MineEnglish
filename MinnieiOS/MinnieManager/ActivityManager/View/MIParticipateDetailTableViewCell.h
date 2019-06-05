//
//  MIParticipateDetailTableViewCell.h
//  MinnieManager
//
//  Created by songzhen on 2019/5/31.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MIParticipateModel.h"

typedef void(^MIPlayVideoCallback)(void);

extern CGFloat const MIParticipateDetailTableViewCellHeight;

extern NSString * _Nullable const MIParticipateDetailTableViewCellId;


NS_ASSUME_NONNULL_BEGIN

@interface MIParticipateDetailTableViewCell : UITableViewCell

@property (nonatomic, copy) MIPlayVideoCallback playVideoCallback;

- (void)setupWithModel:(MIParticipateModel *_Nullable)model;

@end

NS_ASSUME_NONNULL_END
