//
//  ACAnnouncementManager.h
//  Tell
//
//  Created by Ben Liong on 8/6/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kACVoiceKey @"kACVoiceKey"

#define kACNotificationType							@"kACNotificationType"
#define kACNotificationTypeAlarm 					@"kACNtificationTypeAlarm"
#define kACNotificqtionTypeTimeAnnouncement00       @"kACNotificqtionTypeTimeAnnouncement00"
#define kACNotificqtionTypeTimeAnnouncement15       @"kACNotificqtionTypeTimeAnnouncement15"
#define kACNotificqtionTypeTimeAnnouncement30       @"kACNotificqtionTypeTimeAnnouncement30"
#define kACNotificqtionTypeTimeAnnouncement45       @"kACNotificqtionTypeTimeAnnouncement45"

#define kACMaximumNumberOfTimeAnnouncementNotifications     64

#define kACTimeAnnouncementEnabledKey               @"kACTimeAnnouncementEnabledKey"
#define kACTimeAnnouncementOptionKey                @"kACTimeAnnouncementOptionKey"
#define kACTimeANnouncementOptionOldValueKey        @"kACTimeANnouncementOptionOldValueKey"
#define kACTimeAnnouncementVoiceKey                 @"kACTimeAnnouncementVoiceKey"

#define kACTimeAnnouncementEnabledValueDidChangeNotification @"kACTimeAnnouncementEnabledValueDidChangeNotification"
#define kACTimeAnnouncementOptionValueDidChangeNotification @"kACTimeAnnouncementOptionValueDidChangeNotification"

typedef enum {
    kACVoiceFemaleEnglishSamantha = 0
} ACVoice;

typedef enum {
    kACTimeAnnouncementOptionUnknown,
    kACTimeAnnouncementOptionOnTheHour,
    kACTimeAnnouncementOptionOnTheHalfHour,
    kACTimeAnnouncementOptionOnTheQuarterHour
} TimeAnnouncementOption;

#define kACPushNotificationType                             @"type"
#define kACAppPreviouslyLaunchedKey                         @"kACAppPreviouslyLaunchedKey"
#define kACMaximumNumberOfTimeAnnouncementNotifications     64

typedef enum {
    kACPushNotificationTypeRefresh,
    kACPushNotificationTypeAlarm
} PushNotificationType;

@interface ACAnnouncementManager : NSObject
@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, assign) ACVoice voice;
@property (nonatomic, strong) NSArray *voicePostfixArray;
@property (nonatomic, assign) BOOL timeAnnouncementEnabled;
@property (nonatomic, assign) TimeAnnouncementOption timeAnnouncementOption;
@property (nonatomic, strong) NSArray *timeAnnouncementOptionNamesArray;
+ (ACAnnouncementManager *)sharedManager;

#pragma mark - Date Announcement

- (void)announceDate:(NSDate *)date;
- (void)announceDate:(NSDate *)date completion:(void (^)(BOOL finished))completion;

#pragma mark - Scheduling Local Notifications
- (void)reloadAndScheduleTimeAnnouncementNotifications;
- (void)reloadAndScheduleTimeAnnouncementNotificationsWithCompletion:(void (^)(BOOL finished))completion;
- (void)reloadTimeAnnouncementNotifications;
- (void)reloadTimeAnnouncementNotificationsWithCompletion:(void (^)(BOOL finished))completion;

#pragma mark - Push Notification

- (void)scheduleFutureTimeAnnouncementReloadOnDate:(NSDate *)scheduledDate;
- (void)scheduleFutureTimeAnnouncementReloadOnDate:(NSDate *)scheduledDate completion:(void (^)(BOOL finished))completion;

@end
