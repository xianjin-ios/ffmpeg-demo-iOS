//
//  ViewController.m
//  ffmpeg-demo
//
//  Created by 孟现进 on 2018/3/17.
//  Copyright © 2018年 孟现进. All rights reserved.
//

#import "ViewController.h"
#import "FFmpegtest.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [FFmpegtest ffmpegTestConfig];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Test" ofType:@"mov"];
    if (path) {
        [FFmpegtest ffmpegOpenfile:path];
    }
    
    

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
