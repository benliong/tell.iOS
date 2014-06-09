//
//  UISound.h
//
//  Created by Patrick Perini on 11/29/11.
//  Licensing information available in README.md
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class UISound;

#pragma mark UISound Delegate Protocol
//========================================================================//
@protocol UISoundDelegate <NSObject>

@optional
- (void)sound: (UISound *)sound didFinishPlaying: (BOOL)finishedPlaying;

@end
//========================================================================//
#pragma mark UISound Public Interface
//========================================================================//
@interface UISound : NSObject
{
    @private
    SystemSoundID audioEffect;
    void (^completionBlock) (BOOL finished);
}

@property (nonatomic, copy)   NSString *          name;
@property (nonatomic, retain) id<UISoundDelegate> delegate;
@property (nonatomic, copy) void (^completionBlock) (BOOL finished);


- (id)initWithName:           (NSString *)soundName;
- (id)initWithContentsOfURL:  (NSURL *)url;

+ (id)soundNamed:             (NSString *)soundName;
+ (id)soundWithContentsOfURL: (NSURL *)url;

+ (NSArray *)soundUnfilteredTypes;  

- (void)play;
- (void)alert;

- (void)playWithCompletion:(void (^)(BOOL finished))completion;
- (void)alertWithCompletion:(void (^)(BOOL finished))completion;
@end
//========================================================================//
