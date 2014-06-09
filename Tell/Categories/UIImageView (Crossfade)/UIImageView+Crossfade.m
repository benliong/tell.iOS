//
//  UIImageView+Crossfade.m
//  Tell
//
//  Created by Ben Liong on 26/5/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import "UIImageView+Crossfade.h"

@implementation UIImageView (Crossfade)

- (void)crossfadeToImage:(UIImage *)newImage duration:(NSTimeInterval)duration {
    [self crossfadeFromImage:self.image toImage:newImage duration:duration];
}

- (void)crossfadeFromImage:(UIImage *)firstImage toImage:(UIImage *)secondImage duration:(NSTimeInterval)duration {
    CABasicAnimation *crossFade = [CABasicAnimation animationWithKeyPath:@"contents"];
    crossFade.duration = duration;
    crossFade.fromValue = CFBridgingRelease(firstImage.CGImage);
    crossFade.toValue = CFBridgingRelease(secondImage.CGImage);
    [self.layer addAnimation:crossFade forKey:@"animateContents"];
    self.image = secondImage;
}

@end
