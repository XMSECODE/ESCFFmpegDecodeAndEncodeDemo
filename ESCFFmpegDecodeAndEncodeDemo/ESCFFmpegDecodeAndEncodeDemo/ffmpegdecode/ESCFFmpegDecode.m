//
//  ESCFFmpegDecode.m
//  AirShoot
//
//  Created by xiangmingsheng on 2019/4/15.
//  Copyright © 2019 DFung. All rights reserved.
//

#import "ESCFFmpegDecode.h"
#include "swscale.h"
#include "avcodec.h"
#include "avformat.h"

@interface ESCFFmpegDecode (){
    AVCodec *_pCodec;
    AVPacket _packet;
    AVCodecContext *_pCodecCtx;
}

@property(nonatomic,strong)dispatch_queue_t decoderQueue;

@property(nonatomic,assign)AVFrame* lastFrame;

@end

@implementation ESCFFmpegDecode

- (id)initWithDelegate:(id)delegate {
    if ((self = [super init])) {
        self.delegate = delegate;
        self.decoderQueue = dispatch_queue_create("decodequeue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


- (void)dealloc {
    if (_pCodecCtx != NULL) {
        avcodec_close(_pCodecCtx);
        _pCodecCtx = NULL;
    }
}


- (BOOL)setupDecoder{
    avcodec_register_all();

    av_register_all();
    
    _pCodec = avcodec_find_decoder_by_name("h264");
    if (_pCodec == NULL) {
        return NO;
        //                return;
    }
    
    _pCodecCtx = avcodec_alloc_context3(_pCodec);
    
    if(_pCodec->capabilities&CODEC_CAP_TRUNCATED)
        _pCodecCtx->flags|= CODEC_FLAG_TRUNCATED; // we do not send complete frames
    if (_pCodecCtx == NULL) {
        return NO;
    }
    
    if(avcodec_open2(_pCodecCtx, _pCodec, NULL)<0){
        return NO;
    }
    _pCodecCtx->pix_fmt = AV_PIX_FMT_YUV420P;
    return YES;
}



- (void)destroy {
    if (_pCodecCtx) {
        avcodec_close(_pCodecCtx);
        av_free(_pCodecCtx);
        _pCodecCtx = NULL;
    }
    _pCodec = NULL;
}

NSData * copyFrameData(UInt8 *src, int linesize, int width, int height) {
    width = MIN(linesize, width);
    NSMutableData *md = [[NSMutableData alloc] initWithLength: width * height];
    Byte *dst = md.mutableBytes;
    for (NSUInteger i = 0; i < height; i++) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}



- (void)decodeFrameToYUV:(MediaFrame *)frame {
    dispatch_async(self.decoderQueue, ^{
        
        AVFrame *_pFrametest = av_frame_alloc();
        AVPacket pkt, *packettest = &pkt;
        int size = [[frame buffer] length];
        av_new_packet(packettest,size);
        
        if (packettest==NULL) {
            av_free(_pFrametest);
            return;
        }
        memcpy(packettest->data,(uint8_t *)[[frame buffer] bytes], size);
        if (_pCodecCtx==NULL) {
            av_free_packet(packettest);
            av_free(_pFrametest);
            return;
        }
        if (_pFrametest==NULL) {
            av_free_packet(packettest);
            av_free(_pFrametest);
            return;
        }
        int gotten = 0;
        //加上全局锁
        int dec = 0;
        
        if (_pCodecCtx)
            dec = avcodec_decode_video2(_pCodecCtx, _pFrametest, &gotten, packettest);
        else{
            av_free_packet(packettest);
            av_free(_pFrametest);
            return;
        }
        
        av_free_packet(packettest);
        packettest = NULL;
        
        if (gotten && dec > 0)
        {
            
            if (_pFrametest->data[1]==NULL) {
                av_free(_pFrametest);
                _pFrametest = NULL;
                return;
            }
            if (_pFrametest->data[2]==NULL) {
                av_free(_pFrametest);
                _pFrametest = NULL;
                return;
            }
            
            if (self.lastFrame != NULL) {
                av_frame_free(&_lastFrame);
                self.lastFrame = av_frame_clone(_pFrametest);
                self.lastFrame->width = _pFrametest->width;
                self.lastFrame->height = _pFrametest->height;
            }else {
                self.lastFrame = av_frame_clone(_pFrametest);
                self.lastFrame->width = _pFrametest->width;
                self.lastFrame->height = _pFrametest->height;
            }
            
            NSData *dataY = copyFrameData(_pFrametest->data[0], _pFrametest->linesize[0], _pCodecCtx->width, _pCodecCtx->height);
            NSData *dataU = copyFrameData(_pFrametest->data[1], _pFrametest->linesize[1], _pCodecCtx->width / 2, _pCodecCtx->height / 2);
            NSData *dataV = copyFrameData(_pFrametest->data[2], _pFrametest->linesize[2],_pCodecCtx->width / 2, _pCodecCtx->height / 2);
            av_frame_free(&_pFrametest);
            if (self.delegate && [self.delegate respondsToSelector:@selector(decoder:didDecodeFrame:ydata:udata:vdata:)]) {
                [self.delegate decoder:self didDecodeFrame:frame ydata:dataY udata:dataU vdata:dataV];
            }
        }else{
            av_free(_pFrametest);
            _pFrametest = NULL;
        }
    });
    
}

@end
