//
//  FFmpegtest.h
//  ffmpeg-demo
//
//  Created by 孟现进 on 2018/3/19.
//  Copyright © 2018年 孟现进. All rights reserved.
//

#import <Foundation/Foundation.h>
//引入头文件
//核心库 -- 音视频编解码
#import <libavcodec/avcodec.h>
//导入封装格式库
#import <libavformat/avformat.h>

@interface FFmpegtest : NSObject

//测试ffmpeg配置
+ (void)ffmpegTestConfig;

//指定打开一个文件
+ (void)ffmpegOpenfile:(NSString *)filePath;

@end
