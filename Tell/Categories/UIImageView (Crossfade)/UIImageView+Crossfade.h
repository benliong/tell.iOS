//
//  UIImageView+Crossfade.h
//  Tell
//
//  Created by Ben Liong on 26/5/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImageView (Crossfade)
- (void)crossfadeToImage:(UIImage *)newImage duration:(NSTimeInterval)duration;
- (void)crossfadeFromImage:(UIImage *)firstImage toImage:(UIImage *)secondImage duration:(NSTimeInterval)duration; 
@end
