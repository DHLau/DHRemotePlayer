//
//  DHAudioDownLoader.h
//  DHRemotePlayer
//
//  Created by LDH on 17/5/18.
//  Copyright © 2017年 DHLau. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DHAudioDownLoaderDelegate <NSObject>

- (void)downLoading;

@end

@interface DHAudioDownLoader : NSObject

@property (nonatomic, weak) id<DHAudioDownLoaderDelegate> delegate;

@property (nonatomic, assign) long long totalSize;

@property (nonatomic, assign) long long loadedSize;

@property (nonatomic, assign) long long offset;

@property (nonatomic, strong) NSString *mimeType;

- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset;

@end
