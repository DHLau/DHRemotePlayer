//
//  DHRemoteResourceLoaderDelegate.m
//  DHRemotePlayer
//
//  Created by LDH on 17/5/18.
//  Copyright © 2017年 DHLau. All rights reserved.
//

#import "DHRemoteResourceLoaderDelegate.h"
#import "DHRemoteAudioFile.h"
#import "DHAudioDownLoader.h"
#import "NSURL+DH.h"

@interface DHRemoteResourceLoaderDelegate ()<DHAudioDownLoaderDelegate>
@property (nonatomic , strong) DHAudioDownLoader *downLoader;
@property (nonatomic, strong) NSMutableArray *loadingRequests;
@end

// 等待缓存的区间
static const NSInteger cacheSection = 1000;

@implementation DHRemoteResourceLoaderDelegate

- (DHAudioDownLoader *)downLoader
{
    if (!_downLoader) {
        _downLoader = [[DHAudioDownLoader alloc] init];
        _downLoader.delegate = self;
    }
    return _downLoader;
}

- (NSMutableArray *)loadingRequests
{
    if (!_loadingRequests) {
        _loadingRequests = [NSMutableArray array];
    }
    return _loadingRequests;
}

// 当外界，需要播放一段音频资源时，会抛给一个请求，给这个对象，
// 这个对象，到时候，会根据请求信息，抛数据给外界
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURL *url = [loadingRequest.request.URL httpURL];
    
    // 比对需要返回的偏移量
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    long long currentOffset = loadingRequest.dataRequest.currentOffset;
    if (requestOffset != currentOffset) {
        requestOffset = currentOffset;
    }
    
    if ([DHRemoteAudioFile cacheFileExists:url]) {
        // 处理本地文件
        [self handleLoadingRequest:loadingRequest];
        return YES;
    }
    
    // 保存本次请求
    [self.loadingRequests addObject:loadingRequest];
    
    // 判断有没有正在下载
    if (self.downLoader.loadedSize == 0) {
        // 开始下载数据
        [self.downLoader downLoadWithURL:url offset:requestOffset];
        return YES;
    }
    
    // 判断时候需要重新下载
    if (requestOffset < self.downLoader.offset || requestOffset > (self.downLoader.offset + self.downLoader.loadedSize + cacheSection)) {
        [self.downLoader downLoadWithURL:url offset:requestOffset];
        return YES;
    }
    
    // 开始处理资源请求
    [self handleAllLoadingRequest];
    
    return YES;
}

// 取消请求
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.loadingRequests removeObject:loadingRequest];
}

#pragma mark - <DHAudioDownLoaderDelegate>
- (void)downLoading
{
    [self handleAllLoadingRequest];
}

- (void)handleAllLoadingRequest
{
    NSMutableArray *deleteRequests = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in self.loadingRequests) {
        NSURL *url = loadingRequest.request.URL;
        long long totalSize = self.downLoader.totalSize;
        
        // 填充内容信息头
        loadingRequest.contentInformationRequest.contentLength = totalSize;
        NSString *contentType = self.downLoader.mimeType;
        loadingRequest.contentInformationRequest.contentType = contentType;
        loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        
        // 填充数据
        NSData *data = [NSData dataWithContentsOfFile:[DHRemoteAudioFile tmpFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
        if (data == nil) {
            data = [NSData dataWithContentsOfFile:[DHRemoteAudioFile cacheFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
        }
        
        long long requestOffset = loadingRequest.dataRequest.requestedOffset;
        long long currentOffset = loadingRequest.dataRequest.currentOffset;
        
        if (requestOffset != currentOffset) {
            requestOffset = currentOffset;
        }
        NSInteger requestLength = loadingRequest.dataRequest.requestedLength;
        
        long long responseOffset = requestOffset - self.downLoader.offset;
        long long responseLength = MIN(self.downLoader.offset + self.downLoader.loadedSize - requestOffset, requestLength);
        
        NSData *subData = [data subdataWithRange:NSMakeRange(responseOffset, responseLength)];
        [loadingRequest.dataRequest respondWithData:subData];
        
        // 完成请求
        if (requestLength == responseLength) {
            [loadingRequest finishLoading];
            [deleteRequests addObject:loadingRequest];
        }
    }
    [self.loadingRequests removeObjectsInArray:deleteRequests];
}


// 处理, 本地已经下载好的资源文件
- (void)handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURL *url = loadingRequest.request.URL;
    long long totalSize = [DHRemoteAudioFile cacheFileSize:url];
    loadingRequest.contentInformationRequest.contentLength = totalSize;
    
    NSString *contentType = [DHRemoteAudioFile contentType:url];
    loadingRequest.contentInformationRequest.contentType = contentType;
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    
    // 2.相应数据给外界
    NSData *data = [NSData dataWithContentsOfFile:[DHRemoteAudioFile cacheFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
    
    
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    NSInteger requestLength = loadingRequest.dataRequest.requestedLength;
    
    NSData *subData = [data subdataWithRange:NSMakeRange(requestOffset, requestLength)];
    [loadingRequest.dataRequest respondWithData:subData];
    
    
    // 完成本次请求(一点所有的数据都给完了，才能调动完成请求)
    [loadingRequest finishLoading];
}





@end
