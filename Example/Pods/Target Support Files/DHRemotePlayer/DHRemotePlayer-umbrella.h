#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "DHAudioDownLoader.h"
#import "DHRemoteAudioFile.h"
#import "DHRemotePlayer.h"
#import "DHRemoteResourceLoaderDelegate.h"
#import "NSURL+DH.h"

FOUNDATION_EXPORT double DHRemotePlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char DHRemotePlayerVersionString[];

