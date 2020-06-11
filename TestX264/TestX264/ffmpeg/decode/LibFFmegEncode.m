//
//  LibFFmegEncode.m
//  libffmpegCmd
//
//  Created by roy on 2020/6/9.
//  Copyright © 2020 Iceroy. All rights reserved.
//

#import "LibFFmegEncode.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include <libavutil/avassert.h>
#include <libavutil/channel_layout.h>
#include <libavutil/opt.h>
#include <libavutil/mathematics.h>
#include <libavutil/timestamp.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>



@interface LibFFmegEncode()


@property (nonatomic,assign) AVStream *video_st;
@property (nonatomic,assign) AVStream *audio_st;

@property (nonatomic,assign) AVCodecContext *video_enc;
@property (nonatomic,assign) AVCodecContext *audio_enc;

@property (nonatomic,assign) int64_t video_frameIndex;
@property (nonatomic,assign) int64_t audio_frameIndex;

@property (nonatomic,assign) AVFormatContext *oc;
@property (nonatomic,assign) AVOutputFormat *fmt;
@property (nonatomic,assign) int fps;

@end


@implementation LibFFmegEncode


//默认OPTION为空
- (void)startRecordWithFilePath:(NSString *)filePath
                          Width:(NSInteger)width
                         height:(NSInteger)height
                      frameRate:(NSInteger)frameRate
                    audioFormat:(NSInteger)audioFormat
                audioSampleRate:(NSInteger)audioSampleRate
                   audioChannel:(int)audioChannel
             audioBitsPerSample:(int)audioBitsPerSample{
    AVStream *video_st;
    AVStream *audio_st;

    AVCodecContext *video_enc;
    AVCodecContext *audio_enc;
    
    const char *filename;
    AVOutputFormat *fmt;
    AVFormatContext *oc;
    AVCodec *audio_codec, *video_codec;
    int have_video = 0, have_audio = 0;
    int encode_video = 0, encode_audio = 0;
    AVDictionary *opt = NULL;
    self.fps = frameRate;
    //文件名
    filename = [filePath UTF8String];
    
    //初始化
    av_register_all();
    
    /* allocate the output media context */
    int ret = avformat_alloc_output_context2(&oc, NULL, NULL, filename);
    if (!oc) {
        NSLog(@"Could not deduce output format from file extension: using MPEG. ret is %d",ret);
        //打不开就用mpeg模式默认
        avformat_alloc_output_context2(&oc, NULL, "mpeg", filename);
    }
    if (!oc)
        NSLog(@"Crash:can't open this file");
    self.oc = oc;
    fmt = oc->oformat; //输出的容器格式
    
    /* Add the audio and video streams using the default format codecs
       * and initialize the codecs. */
   /*初始化2个stream通道,一个为h265的video stream，一个是aac的audio stream,参数皆有输入进来的参数，不做I帧解析了，外部做H264和H265判断*/
 
     //video stream
    AVCodecContext *videoCodecContext;
    AVStream *videoStream;
    //找编码器
    video_codec = avcodec_find_decoder(AV_CODEC_ID_H265);
    if (!video_codec) {
     NSLog(@"Crash:Could not find encoder for '%s' ",
             avcodec_get_name(AV_CODEC_ID_H265));
    }
    //创建以h265为主的stream
    videoStream = avformat_new_stream(oc, video_codec);
    if (!videoStream) {
        NSLog(@"Crash:Could not allocate h265 stream\n");
    }
    videoStream->id = oc->nb_streams-1;
    
    videoCodecContext = avcodec_alloc_context3(video_codec);
    if (!videoCodecContext) {
        NSLog(@"Crash:Could not alloc an h265 encoding context");
    }
    video_enc = videoCodecContext;
    videoCodecContext->codec_id = AV_CODEC_ID_H265;
    videoCodecContext->bit_rate = 600000;
    videoCodecContext->width = width;
    videoCodecContext->height = height;
    videoStream->time_base = (AVRational){ 1, frameRate};
    videoCodecContext->time_base = videoStream->time_base;
    videoCodecContext->pix_fmt= AV_PIX_FMT_YUV420P;
    videoCodecContext->codec_tag = ('1'<<24)+('c'<<16)+('v'<<8)+'h';
    
    videoStream->codecpar->codec_type = AVMEDIA_TYPE_VIDEO;
    videoStream->codecpar->width = width;
    videoStream->codecpar->height = height;
    videoStream->codecpar->bit_rate = 600000;
    videoStream->codecpar->codec_id = AV_CODEC_ID_H265;
//    videoStream->codecpar->codec_tag = ('H'<<24)+('E'<<16)+('V'<<8)+'C';
    videoStream->codecpar->codec_tag = 0x31637668;
    videoStream->codecpar->format = AV_PIX_FMT_YUV420P;
    
    
    video_st = videoStream;
    
    //audio stream
    AVCodecContext *audioCodecContext;
    AVStream *audioStream;
    //找aac编码器
    enum AVCodecID audioID = audioFormat == 0x7A25? AV_CODEC_ID_PCM_MULAW:AV_CODEC_ID_PCM_ALAW;
    audio_codec = avcodec_find_decoder(audioID);
    if (!audio_codec) {
     NSLog(@"Crash:Could not find encoder for '%s' ",
             avcodec_get_name(audioID));
    }
    //创建AAC的stream
    audioStream = avformat_new_stream(oc, audio_codec);
    if (!audioStream) {
        NSLog(@"Crash:Could not allocate aac stream\n");
    }
    audioStream->id = oc->nb_streams-1;
    
    audioCodecContext = avcodec_alloc_context3(audio_codec);
    if (!audioCodecContext) {
        NSLog(@"Crash:Could not alloc an aac encoding context");
    }
    audio_enc = audioCodecContext;
    audioCodecContext->sample_fmt  = audio_codec->sample_fmts ?
    audio_codec->sample_fmts[0] : AV_SAMPLE_FMT_FLTP;
    audioCodecContext->codec_id = audioID;
    audioCodecContext->bit_rate = audioBitsPerSample;
    audioCodecContext->sample_rate = audioSampleRate;
    audioCodecContext->channel_layout = audioChannel;
    audioCodecContext->channels = av_get_channel_layout_nb_channels(audioChannel);
    audioStream->codecpar->codec_type = AVMEDIA_TYPE_AUDIO;
    audioStream->codecpar->format =  audio_codec->sample_fmts ?audio_codec->sample_fmts[0] : AV_SAMPLE_FMT_FLTP;
    audioStream->codecpar->bit_rate = audioBitsPerSample;
    audioStream->codecpar->codec_id = audioID;
    audioStream->codecpar->channel_layout = audioChannel;
    audioStream->codecpar->channels = av_get_channel_layout_nb_channels(audioChannel);
    audioStream->codecpar->sample_rate = audioSampleRate;
    audioStream->codecpar->frame_size = AV_CODEC_CAP_VARIABLE_FRAME_SIZE;//？？？
    audio_st = audioStream;
    
    
    
    _audio_st = audio_st;
    _video_st = video_st;
    
    _audio_enc = audio_enc;
    _video_st = video_st;
    
    self.video_frameIndex = 0;
    self.audio_frameIndex = 0;
    //打印
    av_dump_format(oc, 0, filename, 1);
    
    
    //如果没有创建文件，此处创建
    if (!(fmt->flags & AVFMT_NOFILE)) {
           int ret = avio_open(&oc->pb, filename, AVIO_FLAG_WRITE);
           if (ret < 0) {
               NSLog(@"Crash:Could not open '%s': %s\n", filename,
                       av_err2str(ret));
           }
    }
    self.fmt = fmt;
    
    /* Write the stream header, if any. */
    ret = avformat_write_header(oc, &opt);
    if (ret < 0) {
        NSLog(@"Crash: Error occurred when opening output file: %s %d\n",
                av_err2str(ret),ret);
    }
}

- (void)addVideoData:(NSData *)videoData isIFrame:(BOOL)isIFrame{
    uint8_t *buf = (uint8_t*)videoData.bytes;
    int size = (int)videoData.length;
    int ret;
    AVStream *pst = self.oc->streams[0];
    
    //创建pkt
    AVPacket pkt;
    av_init_packet(&pkt);
    pkt.flags |= isIFrame?AV_PKT_FLAG_KEY:0;
    pkt.stream_index = pst->index;
    pkt.data = buf;
    pkt.size = size;
    
    
    int m_fps = self.fps;
    int64_t m_frame_index = self.video_frameIndex;
    // 计算每一帧的长度
    int64_t calc_duration = (double)AV_TIME_BASE / m_fps;

    // 计算该帧的显示时间戳
    pkt.pts = (double)(m_frame_index*calc_duration) / (double)(av_q2d(pst->time_base)*AV_TIME_BASE);

    // 解码时间戳和显示时间戳相等  因为视频中没有b帧
    pkt.dts = pkt.pts;
    // 帧的时长
    pkt.duration = (double)calc_duration / (double)(av_q2d(pst->time_base)*AV_TIME_BASE);
  
    self.video_frameIndex++;

    // 换算时间戳 （换算成已输出流中的时间基为单位的显示时间戳）
    pkt.pts = av_rescale_q_rnd(pkt.pts, pst->time_base, pst->time_base, AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX);
    pkt.dts = av_rescale_q_rnd(pkt.dts, pst->time_base, pst->time_base, AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX);
    pkt.duration = av_rescale_q(pkt.duration, pst->time_base, pst->time_base);
    pkt.pos = -1;
    
    NSLog(@"write video frame pts is %d dts is %d duration is %d %@",pkt.pts,pkt.dts,pkt.pos,isIFrame?@"I frame":@"p frame");
    
    ret = av_interleaved_write_frame(self.oc, &pkt );
    if (ret< 0) {
        NSLog(@"cannot write video frame,but also continue");
    }
}


- (void)addAudioData:(NSData *)audioData{
    
    uint8_t *buf = (uint8_t *)audioData.bytes;
    int size = (int)audioData.length;
    int ret;
    AVStream *pst = self.oc->streams[1];
   
    //创建pkt
    AVPacket pkt;

    av_init_packet(&pkt);
    
    pkt.stream_index = pst->index;
    pkt.data = buf;
    pkt.size = size;
   
    int m_fps = self.fps;
    int64_t m_frame_index = self.audio_frameIndex;
    // 计算每一帧的长度
    int64_t calc_duration = (double)AV_TIME_BASE / m_fps;

    // 计算该帧的显示时间戳
    pkt.pts = (double)(m_frame_index*calc_duration) / (double)(av_q2d(pst->time_base)*AV_TIME_BASE);

    // 解码时间戳和显示时间戳相等  因为视频中没有b帧
    pkt.dts = pkt.pts;
    // 帧的时长
    pkt.duration = (double)calc_duration / (double)(av_q2d(pst->time_base)*AV_TIME_BASE);

    self.audio_frameIndex++;

    // 换算时间戳 （换算成已输出流中的时间基为单位的显示时间戳）
    pkt.pts = av_rescale_q_rnd(pkt.pts, pst->time_base, pst->time_base, AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX);
    pkt.dts = av_rescale_q_rnd(pkt.dts, pst->time_base, pst->time_base, AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX);
    pkt.duration = av_rescale_q(pkt.duration, pst->time_base, pst->time_base);
    pkt.pos = -1;
    
    NSLog(@"write audio frame pts is %d dts is %d duration is %d",pkt.pts,pkt.dts,pkt.pos);
   
   //首帧确定为I帧，我就不管了
    /*
    pkt.pts = self.audio_st->next_pts*(90000/c->framerate.num);
    pkt.dts = pkt.pts;
    self.audio_st->next_pts++;
    */
   
    ret = av_interleaved_write_frame(self.oc, &pkt );
    if (ret< 0) {
       NSLog(@"cannot write audio frame,but also continue");
    }
    
}


- (void)stopRecord{
    av_write_trailer(self.oc);
    
    avcodec_free_context(&_video_enc);
    avcodec_free_context(&_audio_enc);
    
    if (!(self.fmt->flags & AVFMT_NOFILE))
    /* Close the output file. */
        avio_closep(&self.oc->pb);
    
    avformat_free_context(self.oc);
}



@end
