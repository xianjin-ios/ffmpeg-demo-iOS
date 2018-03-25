//
//  FFmpegtest.m
//  ffmpeg-demo
//
//  Created by 孟现进 on 2018/3/19.
//  Copyright © 2018年 孟现进. All rights reserved.
//

#import "FFmpegtest.h"

@implementation FFmpegtest


+ (void)ffmpegTestConfig{
    const char *conguration = avcodec_configuration();
    NSLog(@"配置信息：%s",conguration);
    
}

+ (void)ffmpegOpenfile:(NSString *)filePath{
//    注册组件
    av_register_all();
    
//    打开封装格式文件
    AVFormatContext *context = avformat_alloc_context();
    const char *url = [filePath UTF8String];
    AVDictionary *optDict = NULL;
// 1、封装格式上下文
// 2、打开视频地址
// 3、指定输入封装格式
// 4、指定默认配置信息
    int result = avformat_open_input(&context, url, NULL, &optDict);
    if (result != 0) {//失败了
//          获取错误信息
//        char *error_info = NULL;
//        av_strerror(result, error_info, 1024);
        NSLog(@"打开失败");
        return;
        
    }
    NSLog(@"打开成功！！ ");
    
    
    
}
@end
