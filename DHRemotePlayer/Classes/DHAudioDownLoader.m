//
//  DHAudioDownLoader.m
//  DHRemotePlayer
//
//  Created by LDH on 17/5/18.
//  Copyright © 2017年 DHLau. All rights reserved.
//  下载一个区间内的数据

#import "DHAudioDownLoader.h"
#import "DHRemoteAudioFile.h"

@interface DHAudioDownLoader ()<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSOutputStream *outputStream;

@property (nonatomic, strong) NSURL *url;

@end

@implementation DHAudioDownLoader

- (NSURLSession *)session
{
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue  mainQueue]];
    }
    return _session;
}

- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset
{
    [self cancelAndClean];
    
    self.url = url;
    self.offset = offset;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    [task resume];
    
}

- (void)cancelAndClean
{
    [self.session invalidateAndCancel];
    self.session = nil;
    
    [DHRemoteAudioFile clearTmpFile:self.url];
    self.loadedSize = 0;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    self.totalSize = [response.allHeaderFields[@"content-Length"] longLongValue];
    NSString *contentRangeStr = response.allHeaderFields[@"content-Range"];
    if (contentRangeStr.length != 0) {
        self.totalSize = [[contentRangeStr componentsSeparatedByString:@"/"].lastObject longLongValue];
    }
    
    self.mimeType = response.MIMEType;
    
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:[DHRemoteAudioFile tmpFilePath:self.url] append:YES];
    [self.outputStream open];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    self.loadedSize += data.length;
    [self.outputStream write:data.bytes maxLength:data.length];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(downLoading)]) {
        [self.delegate downLoading];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error == nil) {
        NSURL *url = self.url;
        if ([DHRemoteAudioFile tmpFileSize:url] == self.totalSize) {
            [DHRemoteAudioFile moveTmpPathToCachePath:self.url];
        }
    } else {
        NSLog(@"error");
    }
}

@end
