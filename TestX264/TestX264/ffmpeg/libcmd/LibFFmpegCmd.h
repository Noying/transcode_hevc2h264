//
//  LibFFmpegCmd.h
//  LibFFmpegCmd
//
//  Created by roy on 2020/5/22.
//  Copyright © 2020 Iceroy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LibFFmpegCmd : NSObject

+(void)transcode:(NSString*)input output:(NSString*)output;


@end
