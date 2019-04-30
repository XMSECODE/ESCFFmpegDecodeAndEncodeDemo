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
    AVCodecContext *_pCodecCtx;
}

@property(nonatomic,strong)dispatch_queue_t decoderQueue;

@end

@implementation ESCFFmpegDecode

- (instancetype)initWithDelegate:(id)delegate width:(int)width height:(int)height {
    if ((self = [super init])) {
        self.delegate = delegate;
        self.decoderQueue = dispatch_queue_create("decodequeue", DISPATCH_QUEUE_SERIAL);
        [self setupDecoder];
    }
    return self;
}


- (void)dealloc {
    if (_pCodecCtx != NULL) {
        avcodec_close(_pCodecCtx);
        _pCodecCtx = NULL;
    }
}


- (void)setupDecoder{
    dispatch_async(self.decoderQueue, ^{
        avcodec_register_all();
        
        av_register_all();
        
        self->_pCodec = avcodec_find_decoder_by_name("h264");
        if (self->_pCodec == NULL) {
            return ;
        }
        
        self->_pCodecCtx = avcodec_alloc_context3(self->_pCodec);
        
        if(self->_pCodec->capabilities&CODEC_CAP_TRUNCATED)
            self->_pCodecCtx->flags|= CODEC_FLAG_TRUNCATED; // we do not send complete frames
        if (self->_pCodecCtx == NULL) {
            return;
        }
        
        if(avcodec_open2(self->_pCodecCtx, self->_pCodec, NULL)<0){
            return;
        }
        self->_pCodecCtx->pix_fmt = AV_PIX_FMT_YUV420P;
    });
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



- (void)decodeFrameToYUV:(NSData *)frame {
    dispatch_async(self.decoderQueue, ^{
        
        AVFrame *pFrame = av_frame_alloc();
        
        AVPacket *packet = av_packet_alloc();
        int size = (int)[frame length];
        av_new_packet(packet,size);
        
        if (packet==NULL) {
            av_free(pFrame);
            return;
        }
        memcpy(packet->data,(uint8_t *)[frame bytes], size);
        if (self->_pCodecCtx==NULL) {
            av_packet_unref(packet);
            av_packet_free(&packet);
            av_free(pFrame);
            return;
        }
        if (pFrame==NULL) {
            av_packet_unref(packet);
            av_packet_free(&packet);
            av_free(pFrame);
            return;
        }
        int dec = 0;
        
        if (self->_pCodecCtx){
            dec = avcodec_send_packet(self->_pCodecCtx, packet);
            if (dec != 0) {
                NSLog(@"send packet failed!");
                av_packet_unref(packet);
                av_packet_free(&packet);
                av_free(pFrame);
                return;
            }
            dec = avcodec_receive_frame(self->_pCodecCtx, pFrame);
            if (dec != 0) {
                NSLog(@"avcodec_receive_frame failed!");
                av_packet_unref(packet);
                av_packet_free(&packet);
                av_free(pFrame);
                return;
            }
        }else{
            av_packet_unref(packet);
            av_packet_free(&packet);
            av_free(pFrame);
            return;
        }
        
        av_packet_unref(packet);
        av_packet_free(&packet);
        packet = NULL;
        
        
        if (pFrame->data[1]==NULL) {
            av_free(pFrame);
            pFrame = NULL;
            return;
        }
        if (pFrame->data[2]==NULL) {
            av_free(pFrame);
            pFrame = NULL;
            return;
        }
        
        NSData *dataY = copyFrameData(pFrame->data[0], pFrame->linesize[0], self->_pCodecCtx->width, self->_pCodecCtx->height);
        NSData *dataU = copyFrameData(pFrame->data[1], pFrame->linesize[1], self->_pCodecCtx->width / 2, self->_pCodecCtx->height / 2);
        NSData *dataV = copyFrameData(pFrame->data[2], pFrame->linesize[2],self->_pCodecCtx->width / 2, self->_pCodecCtx->height / 2);
        av_frame_free(&pFrame);
        if (self.delegate && [self.delegate respondsToSelector:@selector(decoder:ydata:udata:vdata:)]) {
            [self.delegate decoder:self ydata:dataY udata:dataU vdata:dataV];
        }
    });
    
}

-(void)endH264Data {
    dispatch_async(self.decoderQueue, ^{
        if (self->_pCodecCtx) {
            avcodec_close(self->_pCodecCtx);
            av_free(self->_pCodecCtx);
            self->_pCodecCtx = NULL;
        }
        self->_pCodec = NULL;
        if (self.delegate && [self.delegate respondsToSelector:@selector(endDecoder)]) {
            [self.delegate endDecoder];
        }
    });
}

@end
