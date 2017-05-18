//
//  DHRemoteAudioFile.h
//  DHRemotePlayer
//
//  Created by LDH on 17/5/18.
//  Copyright © 2017年 DHLau. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DHRemoteAudioFile : NSObject

+ (NSString *)cacheFilePath:(NSURL *)url;
+ (long long)cacheFileSize:(NSURL *)url;
+ (BOOL)cacheFileExists:(NSURL *)url;

+ (NSString *)tmpFilePath:(NSURL *)url;
+ (long long)tmpFileSize:(NSURL *)url;
+ (BOOL)tmpFileExists:(NSURL *)url;
+ (void)clearTmpFile:(NSURL *)url;

+ (NSString *)contentType:(NSURL *)url;
+ (void)moveTmpPathToCachePath:(NSURL *)url;

@end
