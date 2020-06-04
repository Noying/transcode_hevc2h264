//
//  LibFFmpegCmd.m
//  LibFFmpegCmd
//
//  Created by roy on 2020/5/22.
//  Copyright © 2020 Iceroy. All rights reserved.
//

#import "LibFFmpegCmd.h"


extern int ffmpeg_main(int argc, char **argv);
extern int transcode_Main(int argc,char **argv);
@implementation LibFFmpegCmd

+(void)transcode:(NSString*)input output:(NSString*)output{
   
    [[NSFileManager defaultManager] createFileAtPath:output contents:nil attributes:nil];
    NSString *command_str= [NSString stringWithFormat:@"ffmpeg -i %@ -vcodec libx264 %@",input,output];
    NSLog(command_str);
    NSArray *argv_array=[command_str componentsSeparatedByString:(@" ")];
    int argc=argv_array.count;
    char** argv=(char**)malloc(sizeof(char*)*argc);
    for(int i=0;i<argc;i++)
    {
        argv[i]=(char*)malloc(sizeof(char)*1024);
        strcpy(argv[i],[[argv_array objectAtIndex:i] UTF8String]);
    }
    
    NSLog(@"start ff");
    ffmpeg_main(argc, argv);
    NSLog(@"end ff");
    for(int i=0;i<argc;i++)
        free(argv[i]);
    free(argv);
}


@end
