//
//  DHRemotePlayer.m
//  DHRemotePlayer
//
//  Created by LDH on 17/5/18.
//  Copyright © 2017年 DHLau. All rights reserved.
//

#import "DHRemotePlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "NSURL+DH.h"
#import "DHRemoteResourceLoaderDelegate.h"


@interface DHRemotePlayer ()<NSCopying, NSMutableCopying>
{
    BOOL _isUserPause;
}

@property (nonatomic, strong) AVPlayer *player;

/**
 资源加载代理
 */
@property (nonatomic, strong) DHRemoteResourceLoaderDelegate *resourceLoaderDelegate;

@end

static DHRemotePlayer *_shareInstace;

@implementation DHRemotePlayer


- (void)playWithURL:(NSURL *)url isCache:(BOOL)isCache
{
    NSURL *currentURL = [(AVURLAsset *)self.player.currentItem.asset URL];
    if ([url isEqual:currentURL] || [[url streamingURL] isEqual:currentURL]) {
        [self resume];
        return;
    }
    
    if (self.player.currentItem) {
        [self removeObserver];
    }
    _url = url;
    if (isCache) {
        url = [url streamingURL];
    }
    
    // 1.资源请求
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    self.resourceLoaderDelegate = [DHRemoteResourceLoaderDelegate new];
    [asset.resourceLoader setDelegate:self.resourceLoaderDelegate queue:dispatch_get_main_queue()];
    
    // 2.资源组织
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playInterupt) name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    // 资源播放
    self.player = [AVPlayer playerWithPlayerItem:item];
    
}


#pragma mark - Basic Methods
- (void)pause
{
    [self.player pause];
    _isUserPause = YES;
    if (self.player) {
        self.state = DHRemotePlayerStatePause;
    }
}

- (void)resume
{
    [self.player play];
    _isUserPause = NO;
    if (self.player && self.player.currentItem.playbackLikelyToKeepUp) {
        self.state = DHRemotePlayerStatePlaying;
    }
}

- (void)stop {
    [self.player pause];
    self.player = nil;
    if (self.player) {
        self.state = DHRemotePlayerStateStopped;
    }
}

- (void)seekWithProgress:(float)progress
{
    if (progress < 0 || progress > 1) {
        return;
    }
    
    CMTime totalTime = self.player.currentItem.duration;
    
    NSTimeInterval totalSec = CMTimeGetSeconds(totalTime);
    NSTimeInterval playTimeSec = totalSec *progress;
    CMTime currentTime = CMTimeMake(playTimeSec, 1);
    
    [self.player seekToTime:currentTime completionHandler:^(BOOL finished) {
        if (finished) {
            NSLog(@"确定加载这个时间点的音频");
        }else {
            NSLog(@"取消加载这个时间点的音频");
        }
    }];
    
}

- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer
{
    NSTimeInterval totalTimeSec = [self totalTime];
    
    NSTimeInterval playTimeSec = [self currentTime];
    playTimeSec += timeDiffer;
    
    [self seekWithProgress:playTimeSec / totalTimeSec];
}

- (void)setRate:(float)rate
{
    [self.player setRate:rate];
}
- (float)rate
{
    return self.player.rate;
}

- (void)setMuted:(BOOL)muted
{
    self.player.muted = muted;
}
- (BOOL)muted {
    return self.player.muted;
}

- (void)setVolume:(float)volume
{
    if (volume < 0 || volume > 1) {
        return;
    }
    if (volume > 0) {
        [self setMuted:NO];
    }
    self.player.volume = volume;
}
- (float)volume
{
    return self.player.volume;
}

- (NSTimeInterval)totalTime
{
    CMTime totalTime = self.player.currentItem.duration;
    NSTimeInterval totalTimeSec = CMTimeGetSeconds(totalTime);
    if (isnan(totalTimeSec)) {
        return 0;
    }
    return totalTimeSec;
}

- (NSString *)totalTimeFormat
{
    return [NSString stringWithFormat:@"%02zd:%02zd", (int)self.self.totalTime / 60, (int)self.totalTime % 60];
}

- (NSTimeInterval)currentTime
{
    CMTime playTime = self.player.currentItem.currentTime;
    NSTimeInterval playTimeSec = CMTimeGetSeconds(playTime);
    if (isnan(playTimeSec)) {
        return 0;
    }
    return playTimeSec;
}

- (NSString *)currentTimeFormat
{
    return [NSString stringWithFormat:@"%02zd:%02zd", (int)self.currentTime / 60 , (int)self.currentTime % 60];
}

- (float)progress
{
    if (self.totalTime == 0) {
        return 0;
    }
    return self.currentTime / self.totalTime;
}

- (float)loadDataProgress
{
    if (self.totalTime == 0) {
        return 0;
    }
    CMTimeRange timeRange = [[self.player.currentItem loadedTimeRanges].lastObject CMTimeRangeValue];
    CMTime loadTime = CMTimeAdd(timeRange.start, timeRange.duration);
    NSTimeInterval loadTimeSec = CMTimeGetSeconds(loadTime);
    
    return loadTimeSec / self.totalTime;
}


- (void)playEnd {
    self.state = DHRemotePlayerStateStopped;
}

- (void)playInterupt {
    self.state = DHRemotePlayerStatePause;
}

- (void)setState:(DHRemotePlayerState)state
{
    _state = state;
}


- (void)removeObserver
{
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerItemStatusReadyToPlay) {
            [self resume];
        } else {
            self.state = DHRemotePlayerStateFailed;
        }
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        BOOL ptk = [change[NSKeyValueChangeNewKey] boolValue];
        if (ptk) {
            if (!_isUserPause) {
                [self resume];
            } else {
                
            }
        } else {
            self.state = DHRemotePlayerStateLoading;
        }
    }
}

#pragma mark - init
+ (instancetype)shareInstance
{
    if (_shareInstace == nil) {
        _shareInstace = [[self alloc] init];
    }
    return _shareInstace;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    if (!_shareInstace) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _shareInstace = [super allocWithZone:zone];
        });
    }
    return _shareInstace;
}

- (id)copyWithZone:(NSZone *)zone
{
    return _shareInstace;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return _shareInstace;
}

@end
