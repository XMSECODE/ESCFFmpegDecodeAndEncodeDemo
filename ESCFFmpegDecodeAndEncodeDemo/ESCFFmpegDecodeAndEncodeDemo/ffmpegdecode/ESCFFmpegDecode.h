//
//  ESCFFmpegDecode.h
//  AirShoot
//
//  Created by xiangmingsheng on 2019/4/15.
//  Copyright © 2019 DFung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MediaFrame.h"

@class ESCFFmpegDecode;

@protocol ESCFFmpegDecodeDelegate <NSObject>

- (void)decoder:(ESCFFmpegDecode *)decoder didDecodeFrame:(MediaFrame *)frame ydata:(NSData *)ydata udata:(NSData *)udata vdata:(NSData *)vdata;

@end


@interface ESCFFmpegDecode : NSObject

@property (nonatomic, weak) id<ESCFFmpegDecodeDelegate> delegate;

- (id)initWithDelegate:(id)delegate;

- (BOOL)setupDecoder;

- (void)decodeFrameToYUV:(MediaFrame *)frame;

- (void)destroy;

- (UIImage *)getLastFrame;

@end


