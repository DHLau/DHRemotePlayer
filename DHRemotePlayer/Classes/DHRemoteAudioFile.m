//
//  DHRemoteAudioFile.m
//  DHRemotePlayer
//
//  Created by LDH on 17/5/18.
//  Copyright © 2017年 DHLau. All rights reserved.
//

#import "DHRemoteAudioFile.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define kCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
#define kTmpPath NSTemporaryDirectory()

@implementation DHRemoteAudioFile

#pragma mark - cache
+ (NSString *)cacheFilePath:(NSURL *)url
{
    return [kCachePath stringByAppendingString:url.lastPathComponent];
}

+ (long long)cacheFileSize:(NSURL *)url
{
    if (![self cacheFileExists:url]) {
        return 0;
    }
    NSString *path = [self cacheFilePath:url];
    NSDictionary *fileInfoDic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [fileInfoDic[NSFileSize] longLongValue];
}

+ (BOOL)cacheFileExists:(NSURL *)url
{
    NSString *path = [self cacheFilePath:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

#pragma mark - tmp
+ (NSString *)tmpFilePath:(NSURL *)url
{
    return [kTmpPath stringByAppendingString:url.lastPathComponent];
}

+ (BOOL)tmpFileExists:(NSURL *)url
{
    NSString *path = [self tmpFilePath:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (long long)tmpFileSize:(NSURL *)url
{
    if (![self tmpFileExists:url]) {
        return 0;
    }
    NSString *path = [self tmpFilePath:url];
    NSDictionary *fileInfoDic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [fileInfoDic[NSFileSize] longLongValue];
}

+ (NSString *)contentType:(NSURL *)url
{
    NSString *path = [self cacheFilePath:url];
    // 文件拓展名
    NSString *fileExtension = path.pathExtension;
    
    CFStringRef contentTypeCF = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(fileExtension), NULL);
    NSString *contentType = CFBridgingRelease(contentTypeCF);
    return contentType;
}

+ (void)moveTmpPathToCachePath:(NSURL *)url
{
    NSString *tmpPath = [self tmpFilePath:url];
    NSString *cachePath = [self cacheFilePath:url];
    [[NSFileManager defaultManager] moveItemAtURL:tmpPath toURL:cachePath error:nil];
}

@end
