//
//  FFmpegtest.m
//  ffmpeg-demo
//
//  Created by 孟现进 on 2018/3/19.
//  Copyright © 2018年 孟现进. All rights reserved.
//

#import "FFmpegtest.h"
int flush_encoder(AVFormatContext *fmt_ctx, unsigned int stream_index) {
    int ret;
    int got_frame;
    AVPacket enc_pkt;
    if (!(fmt_ctx->streams[stream_index]->codec->codec->capabilities &
          CODEC_CAP_DELAY))
        return 0;
    while (1) {
        enc_pkt.data = NULL;
        enc_pkt.size = 0;
        av_init_packet(&enc_pkt);
        ret = avcodec_encode_video2(fmt_ctx->streams[stream_index]->codec, &enc_pkt,
                                    NULL, &got_frame);
        av_frame_free(NULL);
        if (ret < 0)
            break;
        if (!got_frame) {
            ret = 0;
            break;
        }
        NSLog(@"Flush Encoder: Succeed to encode 1 frame!\tsize:%5d\n", enc_pkt.size);
        /* mux encoded frame */
        ret = av_write_frame(fmt_ctx, &enc_pkt);
        if (ret < 0)
            break;
    }
    return ret;
}
@implementation FFmpegtest


//inFilePath:输入文件->mp4、mov等等->封装格式
//outFilePath:输出文件->YUV文件->视频像素数据格式
+(void) ffmepgVideoDecode:(NSString*)inFilePath outFilePath:(NSString*)outFilePath{
    //第一步：组册组件
    av_register_all();
    
    //第二步：打开封装格式->打开文件
    //参数一：封装格式上下文
    //作用：保存整个视频信息(解码器、编码器等等...)
    //信息：码率、帧率等...
    AVFormatContext* avformat_context = avformat_alloc_context();
    //参数二：视频路径
    const char *url = [inFilePath UTF8String];
    //在我们iOS里面
    //NSString* path = @"/user/dream/test.mov";
    //const char *url = [path UTF8String]
    //参数三：指定输入的格式
    //参数四：设置默认参数
    int avformat_open_input_result = avformat_open_input(&avformat_context, url, NULL, NULL);
    if (avformat_open_input_result != 0){
        //安卓平台下log
        NSLog(@"打开文件失败");
        //iOS平台下log
        //NSLog("打开文件失败");
        //不同的平台替换不同平台log日志
        return;
    }
    
    //第三步：查找视频流->拿到视频信息
    //参数一：封装格式上下文
    //参数二：指定默认配置
    int avformat_find_stream_info_result = avformat_find_stream_info(avformat_context, NULL);
    if (avformat_find_stream_info_result < 0){
        NSLog(@"查找失败");
        return;
    }
    
    //第四步：查找视频解码器
    //1、查找视频流索引位置
    int av_stream_index = -1;
    for (int i = 0; i < avformat_context->nb_streams; ++i) {
        //判断流类型：视频流、音频流、字母流等等...
        if (avformat_context->streams[i]-> codec->codec_type == AVMEDIA_TYPE_VIDEO){
            av_stream_index = i;
            break;
        }
    }
    
    //2、根据视频流索引，获取解码器上下文
    AVCodecContext *avcodec_context = avformat_context->streams[av_stream_index]-> codec;
    
    //3、根据解码器上下文，获得解码器ID，然后查找解码器
    AVCodec *avcodec = avcodec_find_decoder(avcodec_context->codec_id);
    
    
    //第五步：打开解码器
    int avcodec_open2_result = avcodec_open2(avcodec_context, avcodec, NULL);
    if (avcodec_open2_result != 0){
        NSLog(@"打开解码器失败");
        return;
    }
    
    //测试一下
    //打印信息
    NSLog(@"解码器名称：%s", avcodec->name);
    
    
    //第六步：读取视频压缩数据->循环读取
    //1、分析av_read_frame参数
    //参数一：封装格式上下文
    //参数二：一帧压缩数据 = 一张图片
    //av_read_frame()
    //结构体大小计算：字节对齐原则
    AVPacket* packet = (AVPacket*)av_malloc(sizeof(AVPacket));
    
    //3.2 解码一帧视频压缩数据->进行解码(作用：用于解码操作)
    //开辟一块内存空间
    AVFrame* avframe_in = av_frame_alloc();
    int decode_result = 0;
    
    
    //4、注意：在这里我们不能够保证解码出来的一帧视频像素数据格式是yuv格式
    //参数一：源文件->原始视频像素数据格式宽
    //参数二：源文件->原始视频像素数据格式高
    //参数三：源文件->原始视频像素数据格式类型
    //参数四：目标文件->目标视频像素数据格式宽
    //参数五：目标文件->目标视频像素数据格式高
    //参数六：目标文件->目标视频像素数据格式类型
    struct SwsContext *swscontext = sws_getContext(avcodec_context->width,
                                                   avcodec_context->height,
                                                   avcodec_context->pix_fmt,
                                                   avcodec_context->width,
                                                   avcodec_context->height,
                                                   AV_PIX_FMT_YUV420P,
                                                   SWS_BICUBIC,
                                                   NULL,
                                                   NULL,
                                                   NULL);
    
    //创建一个yuv420视频像素数据格式缓冲区(一帧数据)
    AVFrame* avframe_yuv420p = av_frame_alloc();
    //给缓冲区设置类型->yuv420类型
    //得到YUV420P缓冲区大小
    //参数一：视频像素数据格式类型->YUV420P格式
    //参数二：一帧视频像素数据宽 = 视频宽
    //参数三：一帧视频像素数据高 = 视频高
    //参数四：字节对齐方式->默认是1
    int buffer_size = av_image_get_buffer_size(AV_PIX_FMT_YUV420P,
                                               avcodec_context->width,
                                               avcodec_context->height,
                                               1);
    
    //开辟一块内存空间
    uint8_t *out_buffer = (uint8_t *)av_malloc(buffer_size);
    //向avframe_yuv420p->填充数据
    //参数一：目标->填充数据(avframe_yuv420p)
    //参数二：目标->每一行大小
    //参数三：原始数据
    //参数四：目标->格式类型
    //参数五：宽
    //参数六：高
    //参数七：字节对齐方式
    av_image_fill_arrays(avframe_yuv420p->data,
                         avframe_yuv420p->linesize,
                         out_buffer,
                         AV_PIX_FMT_YUV420P,
                         avcodec_context->width,
                         avcodec_context->height,
                         1);
    
    int y_size, u_size, v_size;
    
    
    //5.2 将yuv420p数据写入.yuv文件中
    //打开写入文件
    const char *outfile = [outFilePath UTF8String];
    FILE* file_yuv420p = fopen(outfile, "wb+");
    if (file_yuv420p == NULL){
        NSLog(@"输出文件打开失败");
        return;
    }
    
    int current_index = 0;
    
    while (av_read_frame(avformat_context, packet) >= 0){
        // >=:读取到了
        // <0:读取错误或者读取完毕
        //2、是否是我们的视频流
        if (packet->stream_index == av_stream_index){
            //第七步：解码
            //学习一下C基础，结构体
            //3、解码一帧压缩数据->得到视频像素数据->yuv格式
            //采用新的API
            //3.1 发送一帧视频压缩数据
            avcodec_send_packet(avcodec_context, packet);
            //3.2 解码一帧视频压缩数据->进行解码(作用：用于解码操作)
            decode_result = avcodec_receive_frame(avcodec_context, avframe_in);
            if (decode_result == 0){
                //解码成功
                //4、注意：在这里我们不能够保证解码出来的一帧视频像素数据格式是yuv格式
                //视频像素数据格式很多种类型: yuv420P、yuv422p、yuv444p等等...
                //保证：我的解码后的视频像素数据格式统一为yuv420P->通用的格式
                //进行类型转换: 将解码出来的视频像素点数据格式->统一转类型为yuv420P
                //sws_scale作用：进行类型转换的
                //参数一：视频像素数据格式上下文
                //参数二：原来的视频像素数据格式->输入数据
                //参数三：原来的视频像素数据格式->输入画面每一行大小
                //参数四：原来的视频像素数据格式->输入画面每一行开始位置(填写：0->表示从原点开始读取)
                //参数五：原来的视频像素数据格式->输入数据行数
                //参数六：转换类型后视频像素数据格式->输出数据
                //参数七：转换类型后视频像素数据格式->输出画面每一行大小
                sws_scale(swscontext,
                          (const uint8_t *const *)avframe_in->data,
                          avframe_in->linesize,
                          0,
                          avcodec_context->height,
                          avframe_yuv420p->data,
                          avframe_yuv420p->linesize);
                
                //方式一：直接显示视频上面去
                //方式二：写入yuv文件格式
                //5、将yuv420p数据写入.yuv文件中
                //5.1 计算YUV大小
                //分析一下原理?
                //Y表示：亮度
                //UV表示：色度
                //有规律
                //YUV420P格式规范一：Y结构表示一个像素(一个像素对应一个Y)
                //YUV420P格式规范二：4个像素点对应一个(U和V: 4Y = U = V)
                y_size = avcodec_context->width * avcodec_context->height;
                u_size = y_size / 4;
                v_size = y_size / 4;
                //5.2 写入.yuv文件
                //首先->Y数据
                fwrite(avframe_yuv420p->data[0], 1, y_size, file_yuv420p);
                //其次->U数据
                fwrite(avframe_yuv420p->data[1], 1, u_size, file_yuv420p);
                //再其次->V数据
                fwrite(avframe_yuv420p->data[2], 1, v_size, file_yuv420p);
                
                current_index++;
                NSLog(@"当前解码第%d帧", current_index);
            }
        }
    }
    
    //第八步：释放内存资源，关闭解码器
    av_packet_free(&packet);
    fclose(file_yuv420p);
    av_frame_free(&avframe_in);
    av_frame_free(&avframe_yuv420p);
    free(out_buffer);
    avcodec_close(avcodec_context);
    avformat_free_context(avformat_context);
}
//音频解码
+(void)ffmpegAudioDecode:(NSString*)inFilePath outFilePath:(NSString*)outFilePath{
    //第一步：组册组件->解码器、编码器等等…
    //视频解码器、视频编码器、音频解码器、音频编码器等等…
    av_register_all();
    
    //第二步：打开封装格式文件（解封装）
    //参数一：封装格式上下文
    AVFormatContext *avformat_context = avformat_alloc_context();
    //参数二：视频路径
    const char *cinFilePath = [inFilePath UTF8String];
    //参数三：指定输入的格式
    //参数四：设置默认参数
    if (avformat_open_input(&avformat_context, cinFilePath, NULL, NULL) != 0) {
        NSLog(@"打开文件失败");
        return;
    }
    
    //第三步：查找音频流（视频流、字母流等…）信息
    if (avformat_find_stream_info(avformat_context, NULL) < 0) {
        NSLog(@"查找失败");
        return;
    }
    
    //第四步：查找音频解码器
    //1、查找音频流索引位置
    int av_audio_stream_index = -1;
    for (int i = 0; i < avformat_context->nb_streams; ++i) {
        //判断流类型：视频流、音频流、字母流等等...
        if (avformat_context->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO){
            av_audio_stream_index = i;
            break;
        }
    }
    //2、根据视频流索引，获取解码器上下文
    AVCodecContext *avcodec_context = avformat_context->streams[av_audio_stream_index]->codec;
    //3、根据音频解码器上下文，获得解码器ID，然后查找音频解码器
    AVCodec *avcodec = avcodec_find_decoder(avcodec_context->codec_id);
    
    //第五步：打开音频解码器
    if (avcodec_open2(avcodec_context, avcodec, NULL) != 0) {
        NSLog(@"打开解码器失败");
        return;
    }
    //打印信息
    NSLog(@"解码器名称：%s", avcodec->name);
    
    //第六步：循环读取每一帧音频压缩数据
    //参数一：封装格式上下文呢
    //参数二：音频压缩数据(一帧)
    //返回值：>=0表示读取成功，<0表示失败或者解码完成(读取完毕)
    //准备一帧音频压缩数据
    AVPacket *avPacket = (AVPacket *) av_malloc(sizeof(AVPacket));
    //准备一帧音频采样数据
    AVFrame *avFrame = av_frame_alloc();
    
    //3、类型转换->统一转换为pcm格式->swr_convert()
    //初始化音频采样数据上下文
    //3.1：开辟一块内存空间
    SwrContext *swrContext = swr_alloc();
    //3.2：设置默认配置
    //参数一：音频采样数据上下文
    //参数二：输出声道布局(立体声、环绕声...)
    //参数三：输出采样精度(编码)
    //参数四：输出采样率
    //参数五：输入声道布局
    int64_t in_ch_layout = av_get_default_channel_layout(avcodec_context->channels);
    //参数六：输入采样精度
    //参数七：输入采样率
    //参数八：日志统计开始位置
    //参数九：日志上下文
    swr_alloc_set_opts(swrContext,
                       AV_CH_LAYOUT_STEREO,
                       AV_SAMPLE_FMT_S16,
                       avcodec_context->sample_rate,
                       in_ch_layout,
                       avcodec_context->sample_fmt,
                       avcodec_context->sample_rate,
                       0,
                       NULL);
    
    //3.3：初始化上下文
    swr_init(swrContext);
    
    //3.4：统一输出音频采样数据格式->pcm
    int MAX_AUDIO_SIZE = 44100 * 2;
    uint8_t *out_buffer = (uint8_t *) av_malloc(MAX_AUDIO_SIZE);
    
    //4、获取缓冲区实际大小
    int out_nb_channels = av_get_channel_layout_nb_channels(AV_CH_LAYOUT_STEREO);
    
    //5.1 打开文件
    const char *outfile = [outFilePath UTF8String];
    FILE* file_pcm = fopen(outfile, "wb+");
    if (file_pcm == NULL){
        NSLog(@"输出文件打开失败");
        return;
    }
    
    int current_index = 0;
    
    while (av_read_frame(avformat_context, avPacket) >= 0) {
        //判定这一帧数据是否音频流(视频流、音频流、字母流等等...)
        //1、音频解码->判定流类型
        if (avPacket->stream_index == av_audio_stream_index) {
            //音频流->处理
            //2、音频解码->开始解码
            //2.1 发送数据包->一帧音频压缩数据->acc格式、mp3格式
            avcodec_send_packet(avcodec_context, avPacket);
            //2.2 解码数据包->解码->一帧音频采样数据->pcm格式
            int ret = avcodec_receive_frame(avcodec_context, avFrame);
            if (ret == 0) {
                //表示解码成功，否则失败
                //3、类型转换->统一转换为pcm格式->swr_convert()
                //为什么呢？因为解码之后的音频采样数据格式->有很多种类型->保证格式一致
                //参数一：音频采样数据上下文
                //参数二：输出音频采样数据
                //参数三：输出音频采样数据大小
                //参数四：输入音频采样数据
                //参数五：输入音频采样数据大小
                swr_convert(swrContext,
                            &out_buffer,
                            MAX_AUDIO_SIZE,
                            (const uint8_t **) avFrame->data,
                            avFrame->nb_samples);
                
                //4、获取缓冲区实际大小
                //参数一：行大小
                //参数二：输出声道数量（单声道、双声道）
                //参数三：输入大小
                //参数四：输出音频采样数据格式
                //参数五：字节对齐方式->默认是1
                int buffer_size = av_samples_get_buffer_size(NULL,
                                                             out_nb_channels,
                                                             avFrame->nb_samples,
                                                             avcodec_context->sample_fmt,
                                                             1);
                
                //5、写入文件
                //5.1 打开文件
                //5.2 写入文件
                fwrite(out_buffer, 1, buffer_size, file_pcm);
                current_index++;
                NSLog(@"当前解码到了第%d帧", current_index);
            }
        }
    }
    
    //第八步：释放资源（内存）->关闭解码器
    av_packet_free(&avPacket);
    fclose(file_pcm);
    av_frame_free(&avFrame);
    free(out_buffer);
    avcodec_close(avcodec_context);
    avformat_free_context(avformat_context);

}

+(void)ffmpegVideoEncode:(NSString*)inFilePath outFilePath:(NSString*)outFilePath{
    //第一步：注册组件->编码器、解码器等等…
    av_register_all();
    
    //第二步：初始化封装格式上下文->视频编码->处理为视频压缩数据格式
    AVFormatContext *avformat_context = avformat_alloc_context();
    //注意事项：FFmepg程序推测输出文件类型->视频压缩数据格式类型
    const char *coutFilePath = [outFilePath UTF8String];
    //得到视频压缩数据格式类型(h264、h265、mpeg2等等...)
    AVOutputFormat *avoutput_format = av_guess_format(NULL, coutFilePath, NULL);
    //指定类型
    avformat_context->oformat = avoutput_format;
    
    //第三步：打开输出文件
    //参数一：输出流
    //参数二：输出文件
    //参数三：权限->输出到文件中
    if (avio_open(&avformat_context->pb, coutFilePath, AVIO_FLAG_WRITE) < 0) {
        NSLog(@"打开输出文件失败");
        return;
    }
    
    //第四步：创建输出码流->创建了一块内存空间->并不知道他是什么类型流->希望他是视频流
    AVStream *av_video_stream = avformat_new_stream(avformat_context, NULL);
    
    //第五步：查找视频编码器
    //1、获取编码器上下文
    AVCodecContext *avcodec_context = av_video_stream->codec;
    
    //2、设置编解码器上下文参数->必需设置->不可少
    //目标：设置为是一个视频编码器上下文->指定的是视频编码器
    //上下文种类：视频解码器、视频编码器、音频解码器、音频编码器
    //2.1 设置视频编码器ID
    avcodec_context->codec_id = avoutput_format->video_codec;
    //2.2 设置编码器类型->视频编码器
    //视频编码器->AVMEDIA_TYPE_VIDEO
    //音频编码器->AVMEDIA_TYPE_AUDIO
    avcodec_context->codec_type = AVMEDIA_TYPE_VIDEO;
    //2.3 设置读取像素数据格式->编码的是像素数据格式->视频像素数据格式->YUV420P(YUV422P、YUV444P等等...)
    //注意：这个类型是根据你解码的时候指定的解码的视频像素数据格式类型
    avcodec_context->pix_fmt = AV_PIX_FMT_YUV420P;
    //2.4 设置视频宽高->视频尺寸
    avcodec_context->width = 640;
    avcodec_context->height = 352;
    //2.5 设置帧率->表示每秒25帧
    //视频信息->帧率 : 25.000 fps
    //f表示：帧数
    //ps表示：时间(单位：每秒)
    avcodec_context->time_base.num = 1;
    avcodec_context->time_base.den = 25;
    //2.6 设置码率
    //2.6.1 什么是码率？
    //含义：每秒传送的比特(bit)数单位为 bps(Bit Per Second)，比特率越高，传送数据速度越快。
    //单位：bps，"b"表示数据量，"ps"表示每秒
    //目的：视频处理->视频码率
    //2.6.2 什么是视频码率?
    //含义：视频码率就是数据传输时单位时间传送的数据位数，一般我们用的单位是kbps即千位每秒
    //视频码率计算如下？
    //基本的算法是：【码率】(kbps)=【视频大小 - 音频大小】(bit位) /【时间】(秒)
    //例如：Test.mov时间 = 24，文件大小(视频+音频) = 1.73MB
    //视频大小 = 1.34MB（文件占比：77%） = 1.34MB * 1024 * 1024 * 8 = 字节大小 = 468365字节 = 468Kbps
    //音频大小 = 376KB（文件占比：21%）
    //计算出来值->码率 : 468Kbps->表示1000，b表示位(bit->位)
    //总结：码率越大，视频越大
    avcodec_context->bit_rate = 468000;
    
    //2.7 设置GOP->影响到视频质量问题->画面组->一组连续画面
    //MPEG格式画面类型：3种类型->分为->I帧、P帧、B帧
    //I帧->内部编码帧->原始帧(原始视频数据)
    //    完整画面->关键帧(必需的有，如果没有I，那么你无法进行编码，解码)
    //    视频第1帧->视频序列中的第一个帧始终都是I帧，因为它是关键帧
    //P帧->向前预测帧->预测前面的一帧类型，处理数据(前面->I帧、B帧)
    //    P帧数据->根据前面的一帧数据->进行处理->得到了P帧
    //B帧->前后预测帧(双向预测帧)->前面一帧和后面一帧
    //    B帧压缩率高，但是对解码性能要求较高。
    //总结：I只需要考虑自己 = 1帧，P帧考虑自己+前面一帧 = 2帧，B帧考虑自己+前后帧 = 3帧
    //    说白了->P帧和B帧是对I帧压缩
    //每250帧，插入1个I帧，I帧越少，视频越小->默认值->视频不一样
    avcodec_context->gop_size = 250;
    
    //2.8 设置量化参数->数学算法(高级算法)->不讲解了
    //总结：量化系数越小，视频越是清晰
    //一般情况下都是默认值，最小量化系数默认值是10，最大量化系数默认值是51
    avcodec_context->qmin = 10;
    avcodec_context->qmax = 51;
    
    //2.9 设置b帧最大值->设置不需要B帧
    avcodec_context->max_b_frames = 0;
    
    //第二点：查找编码器->h264
    //找不到编码器->h264
    //重要原因是因为：编译库没有依赖x264库（默认情况下FFmpeg没有编译进行h264库）
    //第一步：编译h264库
    AVCodec *avcodec = avcodec_find_encoder(avcodec_context->codec_id);
    if (avcodec == NULL) {
        NSLog(@"找不到编码器");
        return;
    }
    
    NSLog(@"编码器名称为：%s", avcodec->name);
    
    
    //第六步：打开h264编码器
    //缺少优化步骤？
    //编码延时问题
    //编码选项->编码设置
    AVDictionary *param = 0;
    if (avcodec_context->codec_id == AV_CODEC_ID_H264) {
        //需要查看x264源码->x264.c文件
        //第一个值：预备参数
        //key: preset
        //value: slow->慢
        //value: superfast->超快
        av_dict_set(&param, "preset", "slow", 0);
        //第二个值：调优
        //key: tune->调优
        //value: zerolatency->零延迟
        av_dict_set(&param, "tune", "zerolatency", 0);
    }
    if (avcodec_open2(avcodec_context, avcodec, &param) < 0) {
        NSLog(@"打开编码器失败");
        return;
    }
    
    //第七步：写入文件头信息
    avformat_write_header(avformat_context, NULL);
    
    //第8步：循环编码yuv文件->视频像素数据(yuv格式)->编码->视频压缩数据(h264格式)
    //8.1 定义一个缓冲区
    //作用：缓存一帧视频像素数据
    //8.1.1 获取缓冲区大小
    int buffer_size = av_image_get_buffer_size(avcodec_context->pix_fmt,
                                               avcodec_context->width,
                                               avcodec_context->height,
                                               1);
    
    //8.1.2 创建一个缓冲区
    int y_size = avcodec_context->width * avcodec_context->height;
    uint8_t *out_buffer = (uint8_t *) av_malloc(buffer_size);
    
    //8.1.3 打开输入文件
    const char *cinFilePath = [inFilePath UTF8String];
    FILE *in_file = fopen(cinFilePath, "rb");
    if (in_file == NULL) {
        NSLog(@"文件不存在");
        return;
    }
    
    //8.2.1 开辟一块内存空间->av_frame_alloc
    //开辟了一块内存空间
    AVFrame *av_frame = av_frame_alloc();
    //8.2.2 设置缓冲区和AVFrame类型保持一直->填充数据
    av_image_fill_arrays(av_frame->data,
                         av_frame->linesize,
                         out_buffer,
                         avcodec_context->pix_fmt,
                         avcodec_context->width,
                         avcodec_context->height,
                         1);
    
    int i = 0;
    
    //9.2 接收一帧视频像素数据->编码为->视频压缩数据格式
    AVPacket *av_packet = (AVPacket *) av_malloc(buffer_size);
    int result = 0;
    int current_frame_index = 1;
    while (true) {
        //8.1 从yuv文件里面读取缓冲区
        //读取大小：y_size * 3 / 2
        if (fread(out_buffer, 1, y_size * 3 / 2, in_file) <= 0) {
            NSLog(@"读取完毕...");
            break;
        } else if (feof(in_file)) {
            break;
        }
        
        //8.2 将缓冲区数据->转成AVFrame类型
        //给AVFrame填充数据
        //8.2.3 void * restrict->->转成->AVFrame->ffmpeg数据类型
        //Y值
        av_frame->data[0] = out_buffer;
        //U值
        av_frame->data[1] = out_buffer + y_size;
        //V值
        av_frame->data[2] = out_buffer + y_size * 5 / 4;
        av_frame->pts = i;
        //注意时间戳
        i++;
        //总结：这样一来我们的AVFrame就有数据了
        
        //第9步：视频编码处理
        //9.1 发送一帧视频像素数据
        avcodec_send_frame(avcodec_context, av_frame);
        //9.2 接收一帧视频像素数据->编码为->视频压缩数据格式
        result = avcodec_receive_packet(avcodec_context, av_packet);
        //9.3 判定是否编码成功
        if (result == 0) {
            //编码成功
            //第10步：将视频压缩数据->写入到输出文件中->outFilePath
            av_packet->stream_index = av_video_stream->index;
            result = av_write_frame(avformat_context, av_packet);
            NSLog(@"当前是第%d帧", current_frame_index);
            current_frame_index++;
            //是否输出成功
            if (result < 0) {
                NSLog(@"输出一帧数据失败");
                return;
            }
        }
    }
    
    //第11步：写入剩余帧数据->可能没有
    flush_encoder(avformat_context, 0);
    
    //第12步：写入文件尾部信息
    av_write_trailer(avformat_context);
    
    //第13步：释放内存
    avcodec_close(avcodec_context);
    av_free(av_frame);
    av_free(out_buffer);
    av_packet_free(&av_packet);
    avio_close(avformat_context->pb);
    avformat_free_context(avformat_context);
    fclose(in_file);
}
+(void)ffmpegAudioEncode:(NSString*)inFilePath outFilePath:(NSString*)outFilePath{
    //第一步：注册组件->音频编码器等等…
    av_register_all();
    
    //第二步：初始化封装格式上下文->视频编码->处理为音频压缩数据格式
    AVFormatContext *avformat_context = avformat_alloc_context();
    //注意事项：FFmepg程序推测输出文件类型->音频压缩数据格式类型->aac格式
    const char *coutFilePath = [outFilePath UTF8String];
    //得到音频压缩数据格式类型(aac、mp3等...)
    AVOutputFormat *avoutput_format = av_guess_format(NULL, coutFilePath, NULL);
    //指定类型
    avformat_context->oformat = avoutput_format;
    
    //第三步：打开输出文件
    //参数一：输出流
    //参数二：输出文件
    //参数三：权限->输出到文件中
    if (avio_open(&avformat_context->pb, coutFilePath, AVIO_FLAG_WRITE) < 0) {
        NSLog(@"打开输出文件失败");
        return;
    }
    
    //第四步：创建输出码流->创建了一块内存空间->并不知道他是什么类型流->希望他是视频流
    AVStream *audio_st = avformat_new_stream(avformat_context, NULL);
    
    //第五步：查找音频编码器
    //1、获取编码器上下文
    AVCodecContext *avcodec_context = audio_st->codec;
    
    //2、设置编解码器上下文参数->必需设置->不可少
    //目标：设置为是一个音频编码器上下文->指定的是音频编码器
    //上下文种类：音频解码器、音频编码器
    //2.1 设置音频编码器ID
    avcodec_context->codec_id = avoutput_format->audio_codec;
    //2.2 设置编码器类型->音频编码器
    //视频编码器->AVMEDIA_TYPE_VIDEO
    //音频编码器->AVMEDIA_TYPE_AUDIO
    avcodec_context->codec_type = AVMEDIA_TYPE_AUDIO;
    //2.3 设置读取音频采样数据格式->编码的是音频采样数据格式->音频采样数据格式->pcm格式
    //注意：这个类型是根据你解码的时候指定的解码的音频采样数据格式类型
    avcodec_context->sample_fmt = AV_SAMPLE_FMT_S16;
    //设置采样率
    avcodec_context->sample_rate = 44100;
    //立体声
    avcodec_context->channel_layout = AV_CH_LAYOUT_STEREO;
    //声道数量
    int channels = av_get_channel_layout_nb_channels(avcodec_context->channel_layout);
    avcodec_context->channels = channels;
    //设置码率
    //基本的算法是：【码率】(kbps)=【视频大小 - 音频大小】(bit位) /【时间】(秒)
    avcodec_context->bit_rate = 128000;
    
    //第二点：查找音频编码器->aac
    //    AVCodec *avcodec = avcodec_find_encoder(avcodec_context->codec_id);
    AVCodec *avcodec = avcodec_find_encoder_by_name("libfdk_aac");
    if (avcodec == NULL) {
        NSLog(@"找不到音频编码器");
        return;
    }
    
    
    //第六步：打开aac编码器
    if (avcodec_open2(avcodec_context, avcodec, NULL) < 0) {
        NSLog(@"打开音频编码器失败");
        return;
    }
    
    //第七步：写文件头（对于某些没有文件头的封装格式，不需要此函数。比如说MPEG2TS）
    avformat_write_header(avformat_context, NULL);
    
    //打开YUV文件
    const char *c_inFilePath = [inFilePath UTF8String];
    FILE *in_file = fopen(c_inFilePath, "rb");
    if (in_file == NULL) {
        NSLog(@"YUV文件打开失败");
        return;
    }
    
    //第十步：初始化音频采样数据帧缓冲区
    AVFrame *av_frame = av_frame_alloc();
    av_frame->nb_samples = avcodec_context->frame_size;
    av_frame->format = avcodec_context->sample_fmt;
    
    //得到音频采样数据缓冲区大小
    int buffer_size = av_samples_get_buffer_size(NULL,
                                                 avcodec_context->channels,
                                                 avcodec_context->frame_size,
                                                 avcodec_context->sample_fmt,
                                                 1);
    
    
    //创建缓冲区->存储音频采样数据->一帧数据
    uint8_t *out_buffer = (uint8_t *) av_malloc(buffer_size);
    avcodec_fill_audio_frame(av_frame,
                             avcodec_context->channels,
                             avcodec_context->sample_fmt,
                             (const uint8_t *)out_buffer,
                             buffer_size,
                             1);
    
    //第十二步：创建音频压缩数据->帧缓存空间
    AVPacket *av_packet = (AVPacket *) av_malloc(buffer_size);
    
    
    //第十三步：循环读取视频像素数据格式->编码压缩->视频压缩数据格式
    int frame_current = 1;
    int i = 0, ret = 0;
    
    //第八步：循环编码每一帧视频
    //即将AVFrame（存储YUV像素数据）编码为AVPacket（存储H.264等格式的码流数据）
    while (true) {
        //1、读取一帧音频采样数据
        if (fread(out_buffer, 1, buffer_size, in_file) <= 0) {
            NSLog(@"Failed to read raw data! \n");
            break;
        } else if (feof(in_file)) {
            break;
        }
        
        //2、设置音频采样数据格式
        //将outbuffer->av_frame格式
        av_frame->data[0] = out_buffer;
        av_frame->pts = i;
        i++;
        
        //3、编码一帧音频采样数据->得到音频压缩数据->aac
        //采用新的API
        //3.1 发送一帧音频采样数据
        ret = avcodec_send_frame(avcodec_context, av_frame);
        if (ret != 0) {
            NSLog(@"Failed to send frame! \n");
            return;
        }
        //3.2 编码一帧音频采样数据
        ret = avcodec_receive_packet(avcodec_context, av_packet);
        
        if (ret == 0) {
            //第九步：将编码后的音频码流写入文件
            NSLog(@"当前编码到了第%d帧", frame_current);
            frame_current++;
            av_packet->stream_index = audio_st->index;
            ret = av_write_frame(avformat_context, av_packet);
            if (ret < 0) {
                NSLog(@"写入失败! \n");
                return;
            }
        } else {
            NSLog(@"Failed to encode! \n");
            return;
        }
    }
    
    //第十步：输入的像素数据读取完成后调用此函数。用于输出编码器中剩余的AVPacket。
    ret = flush_encoder(avformat_context, 0);
    if (ret < 0) {
        NSLog(@"Flushing encoder failed\n");
        return;
    }
    
    //第十一步：写文件尾（对于某些没有文件头的封装格式，不需要此函数。比如说MPEG2TS）
    av_write_trailer(avformat_context);
    
    
    //第十二步：释放内存，关闭编码器
    avcodec_close(avcodec_context);
    av_free(av_frame);
    av_free(out_buffer);
    av_packet_free(&av_packet);
    avio_close(avformat_context->pb);
    avformat_free_context(avformat_context);
    fclose(in_file);
}
@end
