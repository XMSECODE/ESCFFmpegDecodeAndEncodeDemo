//
//  MediaFrame.h
//  AirShoot
//
//  Created by xiangmingsheng on 2019/4/15.
//  Copyright © 2019 DFung. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MediaFrame : NSObject

@property (nonatomic, copy) NSMutableData *buffer;

@property (nonatomic, assign) BOOL  keyFrame;

@property (nonatomic) int width;

@property (nonatomic) int height;

@end

NS_ASSUME_NONNULL_END
