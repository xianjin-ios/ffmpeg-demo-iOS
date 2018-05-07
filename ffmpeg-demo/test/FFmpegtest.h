//
//  FFmpegtest.h
//  ffmpeg-demo
//
//  Created by 孟现进 on 2018/3/19.
//  Copyright © 2018年 孟现进. All rights reserved.
//

#import <Foundation/Foundation.h>
//导入头文件
//核心库
#include "libavcodec/avcodec.h"
//封装格式处理库
#include "libavformat/avformat.h"
//工具库
#include "libavutil/imgutils.h"

//视频像素数据格式库
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
@interface FFmpegtest : NSObject

//视频解码
+(void) ffmepgVideoDecode:(NSString*)inFilePath outFilePath:(NSString*)outFilePath;

//音频解码
+(void)ffmpegAudioDecode:(NSString*)inFilePath outFilePath:(NSString*)outFilePath;

//FFmpeg视频编码
+(void)ffmpegVideoEncode:(NSString*)filePath outFilePath:(NSString*)outFilePath;

//音频编码
+(void)ffmpegAudioEncode:(NSString*)inFilePath outFilePath:(NSString*)outFilePath;



@end
