//
//  ViewController.m
//  TestX264
//
//  Created by roy on 2020/6/1.
//  Copyright © 2020 Iceroy. All rights reserved.
//

#import "ViewController.h"
#import "LibFFmpegCmd.h"



extern int ffmpeg_main(int argc, char **argv);
extern int transcode_main(int argc,char **argv);
extern int aac_main(int argc,char**argv);
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"video_and_auido" ofType:@"mp4"];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *transcodePath = [NSString stringWithFormat:@"%@/down.mp4",docDir];
#if fftools /* 使用fftools的画，内存会过大而*/
    NSString *command_str= [NSString stringWithFormat:@"ffmpeg -i %@ -vcodec libx264 %@",filePath,transcodePath];
#else /*这种方式画质稍微有点降低*/
    NSString *command_str= [NSString stringWithFormat:@"ffmpeg %@ %@",filePath,transcodePath];
#endif
    
    NSLog(command_str);
    NSArray *argv_array=[command_str componentsSeparatedByString:(@" ")];
    int argc=argv_array.count;
    char** argv=(char**)malloc(sizeof(char*)*argc);
    for(int i=0;i<argc;i++)
    {
        argv[i]=(char*)malloc(sizeof(char)*1024);
        strcpy(argv[i],[[argv_array objectAtIndex:i] UTF8String]);
    }
#if fftools
    ffmpeg_main(argc,argv);
#else
    NSLog(@"time start");
    transcode_main(argc, argv);
    NSLog(@"time end");
#endif
    
    for(int i=0;i<argc;i++)
        free(argv[i]);
    free(argv);

}


@end
