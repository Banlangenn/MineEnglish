//
//  SearchStudentsViewController.h
//  Minnie
//
//  Created by songzhen on 2019/12/11.
//  Copyright © 2019 minnieedu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SearchStudentsViewController : BaseViewController

@property (nonatomic, strong) NSArray *students;

@property (nonatomic, copy) void (^addCallBack) (NSArray *array);
@end

NS_ASSUME_NONNULL_END
