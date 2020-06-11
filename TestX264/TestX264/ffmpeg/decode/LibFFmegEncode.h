//
//  LibFFmegEncode.h
//  libffmpegCmd
//
//  Created by roy on 2020/6/9.
//  Copyright © 2020 Iceroy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LibFFmegEncode : NSObject

//只写h265的设备，不做h264还需要解析I帧的垃圾设备，默认参数全部正确
- (void)startRecordWithFilePath:(NSString *)filePath
                          Width:(NSInteger)width
                         height:(NSInteger)height
                      frameRate:(NSInteger)frameRate
                    audioFormat:(NSInteger)audioFormat
                audioSampleRate:(NSInteger)audioSampleRate
                   audioChannel:(int)audioChannel
             audioBitsPerSample:(int)audioBitsPerSample;

- (void)addVideoData:(NSData *)videoData isIFrame:(BOOL)isIFrame;

- (void)addAudioData:(NSData *)audioData;


- (void)stopRecord;

@end

NS_ASSUME_NONNULL_END
