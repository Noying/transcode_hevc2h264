### 下载ffmpeg，并且将libx264编译进去
#### 1.下载gas-preprocessor文件
* [https://github.com/libav/gas-preprocessor](https://github.com/libav/gas-preprocessor)
* 将里面的gas-preprocessor.pl拷贝到/usr/local/bin
* 修改文件权限
	`chomd 777 /usr/local/bin/gas-preprocessor.pl`

#### 2. 下载x264源码:
* [https://www.videolan.org/developers/x264.html](https://www.videolan.org/developers/x264.html])

#### 3. 下载x264编译脚本：
 * [https://www.videolan.org/developers/x264.html](https://www.videolan.org/developers/x264.html)

#### 4. 将源码与脚本放在一起
* 新建一个文件夹，将编译脚本build-x264.sh与x264源码文件夹放入这个新建文件夹中，并将x264文件夹(x264-snapshot-xxxx)改名为"x264"

#### 5. 修改权限、执行脚本
* sudo chmod u+x build-x264.sh
* sudo ./build-x264.sh
* 编译过程中会生成scratch-x264文件夹与thin-x264文件夹
* 编译完成最终会生成"x264-iOS"文件夹
![x264-iOS](https://upload-images.jianshu.io/upload_images/11386185-e5dff57d0cfbe28a.png?imageMogr2/auto-orient/strip|imageView2/2/w/824)

### 编译FFmpeg + x264
#### 1. 下载FFmpeg 编译脚本:
* [https://github.com/kewlbear/FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script)
* 去掉脚本 build-ffmpeg.sh中的 #x264 =\`pwd\`/fat-x264 的注释
* 将x264编译出来的lib库文件夹放入ffmpeg编译脚本的文件夹中，并改名为"fat-x264"
![fat-x264](https://upload-images.jianshu.io/upload_images/11386185-0758c2ebd3b598da.png?imageMogr2/auto-orient/strip|imageView2/2/w/402)

#### 2. 编译FFmpeg
* 终端运行 ./build-ffmpeg.sh arm64，因为我的代码只需要arm64
* 编译完成之后，目录生成
![FFmpeg-ios](https://upload-images.jianshu.io/upload_images/11386185-9275ea5818538a30.png?imageMogr2/auto-orient/strip|imageView2/2/w/414)

###  创建转码项目Test264
#### 1. 创建fftools，命令行方式
* 导入文件
`
	cmdutils_common_opts.h 
	cmdutils.c
	cmdutils.h
	config.h
	ffmpeg_filter.c
	ffmpeg_opt.c
	ffmpeg_videotoolbox.c
	ffmpeg.c
	ffmpeg.h
	ffprobe.c
`
* 设置Header Search Paths
* 改bitcode为NO
* 修改 ffmpeg.c中main函数为 ffmpeg_main
* cmdutils.c修改 exit_program
`
int exit_program(int ret)
{
//    if (program_exit)
//        program_exit(ret);
//
//    exit(ret);
    return ret;
}
`
* ffmpeg.c文件中，计数器置零, 在 term_exit(); 前面将5个参数置零（修复多次调用可能引起crash
`
    nb_filtergraphs=0;
    nb_output_files=0;
    nb_output_streams=0;
    nb_input_files=0;
    nb_input_streams=0;
    
    term_exit();
    ffmpeg_exited = 1;
`

* 项目还需要添加系统库
****************
	AudioToolbox.framework

	CoreMedia.framework

	VideoToolbox.framework
	
	libiconv.tdb
	
	libbz2.tdb
	
	libz.tdb
****************

#### 2. 使用代码转码
* 加入另一个转码 transcoding.c，这个是examples里获取的，目录地址根据不同版本的ffmpeg可能不一样，搜索全文件夹就行了，这里我只讲，我修改了transcoding.c的位置
* 第一个我是	强制转化为h264，所以在open_output_file 处修改转出的格式
`
if (dec_ctx->codec_type == AVMEDIA_TYPE_VIDEO) {
                encoder = avcodec_find_encoder(AV_CODEC_ID_H264); //视频强制为h264
            }
            else{
                encoder = avcodec_find_encoder(AV_CODEC_ID_AAC); //声波转为aac
            }
`
* 为了能够去掉 broken ffmpeg default settings detected 错误
`
		  enc_ctx->me_range = 16; 
               enc_ctx->max_qdiff = 4;
               enc_ctx->qmin = 10; 
              enc_ctx->qmax = 51; 
               enc_ctx->qcompress = 0.6;
`
* 视频质量跟码率有关，稍微提高点码率
* 提示 application dts 190>16 ，是因为 av_interleaved_write_frame 返回了-22 ，这里我屏蔽掉这个错误，直接编写
