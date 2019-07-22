//
//  KJPlayerTool.m
//  KJPlayerDemo
//
//  Created by 杨科军 on 2019/7/21.
//  Copyright © 2019 杨科军. All rights reserved.
//

#import "KJPlayerTool.h"
#import <CommonCrypto/CommonDigest.h>
#import <AVFoundation/AVFoundation.h>

//#define DOCUMENTS_FOLDER_AUDIO @"audio" //你定义的audio对应的文件目录
#define DOCUMENTS_FOLDER_VEDIO  @"playerVedio" //你定义的vedio对应的文件目录

@implementation KJPlayerTool

/// 判断是否含有视频轨道
+ (BOOL)kj_playerHaveTracksWithURL:(NSURL*)url{
    //1.判断是否含有视频轨道（判断视频是否可以正常播放）
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    BOOL hasVideoTrack = [tracks count] > 0;
    return hasVideoTrack;
}

/// 判断是否是URL
+ (BOOL)kj_playerIsURL:(NSURL*)url{
    if(url == nil) return NO;
    NSString *string = [url absoluteString];
//    if (string.length>4 && [[string substringToIndex:4] isEqualToString:@"www."]) {
//        string = [NSString stringWithFormat:@"http://%@",self];
//    }
    NSString *urlRegex = @"(https|http|ftp|rtsp|igmp|file|rtspt|rtspu)://((((25[0-5]|2[0-4]\\d|1?\\d?\\d)\\.){3}(25[0-5]|2[0-4]\\d|1?\\d?\\d))|([0-9a-z_!~*'()-]*\\.?))([0-9a-z][0-9a-z-]{0,61})?[0-9a-z]\\.([a-z]{2,6})(:[0-9]{1,4})?([a-zA-Z/?_=]*)\\.\\w{1,5}";
    /// 谓词判断
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegex];
    return [urlTest evaluateWithObject:string];
}

/// 判断url地址是否可用
+ (void)kj_playerValidateUrl:(NSURL*)url CompletionHandler:(void(^)(BOOL success))completionHandler{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(error ? NO : YES);
        }
    }];
    [task resume];
}

/// md5加密
+ (NSString*)kj_playerMD5WithString:(NSString*)string{
    const char *original_str = [string UTF8String];
    unsigned char digist[CC_MD5_DIGEST_LENGTH]; //CC_MD5_DIGEST_LENGTH = 16
    CC_MD5(original_str, (uint)strlen(original_str), digist);
    NSMutableString *outPutStr = [NSMutableString stringWithCapacity:10];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [outPutStr appendFormat:@"%02X", digist[i]];//小写x表示输出的是小写MD5，大写X表示输出的是大写MD5
    }
    return [outPutStr lowercaseString];
}

/// 根据 url 得到完整路径、
+ (NSString*)kj_playerGetIntegrityPathWithUrl:(NSURL*)url{
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *videoPath = [document stringByAppendingPathComponent:DOCUMENTS_FOLDER_VEDIO];
    // 判断存放音频、视频的文件夹是否存在，不存在则创建对应文件夹
    [self kj_playerCreateFileDirectoriesWithPath:videoPath];
    NSString *urlString = [url absoluteString];
    /// 分割字符串
    NSArray *array = [urlString componentsSeparatedByString:@"://"];
    NSString *name = array.count > 1 ? array[1] : urlString; /// 去掉 :// 之前的数据
    /// 加密名字
    NSString *md5Name = [self kj_playerMD5WithString:name];
    NSString *videoName = [md5Name stringByAppendingString:@".mp4"];
    NSString *filePath = [videoPath stringByAppendingPathComponent:videoName];
    return filePath;
}

// 判断存放视频的文件夹是否存在，不存在则创建对应文件夹
+ (BOOL)kj_playerCreateFileDirectoriesWithPath:(NSString*)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:path
                                   isDirectory:&isDir];
    if(!(isDirExist && isDir)){
        BOOL bCreateDir = [fileManager createDirectoryAtPath:path
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:nil];
        if(!bCreateDir){
            NSLog(@"Create vedio Directory Failed.");
            return NO;
        }
    }
    return YES;
}

// 获取视频第一帧图片和视频总时长
+ (NSArray*)kj_playerFristImageWithURL:(NSURL*)url{
//    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(NO) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    // 初始化视频媒体文件
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    /// 获取视频第一帧图片
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    
    /// 获取视频总时长 单位秒
    NSInteger seconds = ceil(asset.duration.value / asset.duration.timescale);
    
    return @[videoImage,@(seconds)];
}

@end