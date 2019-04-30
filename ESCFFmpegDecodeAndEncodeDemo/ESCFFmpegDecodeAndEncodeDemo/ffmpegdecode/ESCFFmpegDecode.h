//
//  ESCFFmpegDecode.h
//  AirShoot
//
//  Created by xiangmingsheng on 2019/4/15.
//  Copyright © 2019 DFung. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ESCFFmpegDecode;

@protocol ESCFFmpegDecodeDelegate <NSObject>

- (void)decoder:(ESCFFmpegDecode *)decoder ydata:(NSData *)ydata udata:(NSData *)udata vdata:(NSData *)vdata;

- (void)endDecoder;

@end


@interface ESCFFmpegDecode : NSObject

@property (nonatomic, weak) id<ESCFFmpegDecodeDelegate> delegate;

- (instancetype)initWithDelegate:(id)delegate width:(int)width height:(int)height;

- (void)decodeFrameToYUV:(NSData *)frame;

- (void)endH264Data;

@end


