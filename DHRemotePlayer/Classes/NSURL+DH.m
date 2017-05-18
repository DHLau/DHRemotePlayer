//
//  NSURL+DH.m
//  DHRemotePlayer
//
//  Created by LDH on 17/5/18.
//  Copyright © 2017年 DHLau. All rights reserved.
//

#import "NSURL+DH.h"

@implementation NSURL (DH)

- (NSURL *)streamingURL
{
    NSURLComponents *components = [NSURLComponents componentsWithString:self.absoluteString];
    components.scheme = @"sreaming";
    return components.URL;
}

- (NSURL *)httpURL
{
    NSURLComponents *components = [NSURLComponents componentsWithString:self.absoluteString];
    components.scheme = @"http";
    return components.URL;
}

@end
