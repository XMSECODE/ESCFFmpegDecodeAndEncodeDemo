//
//  ViewController.m
//  ESCFFmpegDecodeAndEncodeDemo
//
//  Created by xiang on 2019/4/29.
//  Copyright © 2019 xiang. All rights reserved.
//

#import "ViewController.h"
#import "ESCFFmpegDecode.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self decodetest];
}

- (void)decodetest {
    NSString *h264FilePath = [[NSBundle mainBundle] pathForResource:@"video_1280_720.h264" ofType:nil];
    
    NSData *h264Data = [NSData dataWithContentsOfFile:h264FilePath];
    
    ESCFFmpegDecode *tool = [[ESCFFmpegDecode alloc] initWithDelegate:self];
    [tool setupDecoder];
    
    double startTime = CFAbsoluteTimeGetCurrent();
    NSLog(@"%@",self);
    @autoreleasepool {
        uint8_t *videoData = (uint8_t *)[h264Data bytes];
        int lastJ = 0;
        int lastType = 0;
        
        for (int i = 0; i < h264Data.length; i++) {
            //        printf("  %02x  ",videoData[i]);
            //读取头
            if (videoData[i] == 0x00 &&
                videoData[i + 1] == 0x00 &&
                videoData[i + 2] == 0x00 &&
                videoData[i + 3] == 0x01) {
                if (i >= 0) {
                    uint8_t NALU = videoData[i+4];
                    int type = NALU & 0x1f;
                    //                NSLog(@"%d===%d",type,NALU);
                    if (lastType == 5 || lastType == 1) {
                        int frame_size = i - lastJ;
                        NSData *data = [NSData dataWithBytes:&videoData[lastJ] length:frame_size];
                        MediaFrame *frame = [[MediaFrame alloc] init];
                        frame.width = 1280;
                        frame.height = 720;
                        frame.buffer = [data mutableCopy];
                        [tool decodeFrameToYUV:frame];
                        lastJ = i;
                    }
                    lastType = type;
                }
            }else if (i == h264Data.length - 1) {
                int frame_size = i - lastJ + 1;
                NSData *data = [NSData dataWithBytes:&videoData[lastJ] length:frame_size];
                MediaFrame *frame = [[MediaFrame alloc] init];
                frame.width = 1280;
                frame.height = 720;
                frame.buffer = [data mutableCopy];
                [tool decodeFrameToYUV:frame];
                lastJ = i;
            }
        }
    }
    
    double endTime = CFAbsoluteTimeGetCurrent();
    double time = endTime - startTime;
    NSLog(@"%f",time);
}

@end
