//
//  ACAnnouncementManager.m
//  Tell
//
//  Created by Ben Liong on 8/6/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import "ACAnnouncementManager.h"
#import "UISound.h"
#import "NSString+URLEncode.h"

@interface ACAnnouncementManager ()
@property (nonatomic, strong) NSDate *lastScheduledNotificationDate;
- (void)announceDateFromDateComponents:(NSDateComponents *)dateComponents;
- (void)announceDateFromDateComponents:(NSDateComponents *)dateComponents completion:(void (^)(BOOL finished))completion;
- (NSString *)audioFileNameForDateComponents:(NSDateComponents *)dateComponents voice:(ACVoice)voice includesExtension:(BOOL)includesExtension;
@end

@implementation ACAnnouncementManager
@synthesize timeAnnouncementOption = _timeAnnouncementOption;
@synthesize timeAnnouncementEnabled = _timeAnnouncementEnabled;

+ (ACAnnouncementManager *)sharedManager {
    static ACAnnouncementManager *sharedAnnouncementManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAnnouncementManager = [[self alloc] init];
    });
    return sharedAnnouncementManager;
}

#pragma mark - Date Announcement

- (void)announceDate:(NSDate *)date {
    [self announceDate:date completion:nil];
}
- (void)announceDate:(NSDate *)date completion:(void (^)(BOOL finished))completion {
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit) fromDate:date];
    [self announceDateFromDateComponents:dateComponents completion:completion];
}

- (void)announceDateFromDateComponents:(NSDateComponents *)dateComponents {
    [self announceDateFromDateComponents:dateComponents completion:nil];
}
- (void)announceDateFromDateComponents:(NSDateComponents *)dateComponents completion:(void (^)(BOOL finished))completion {
    NSInteger hour = [dateComponents hour];
    NSInteger minute = [dateComponents minute];
    NSString *ampm = @"AM";
    if (hour >= 12) {
        ampm = @"PM";
        if (hour != 12)
            hour -= 12;
    }
    
    switch (minute) {
        case 15:
        case 30:
        case 45:
        case 00:
        {
            NSLog(@"Filename = %@", [self audioFileNameForDateComponents:dateComponents voice:self.voice includesExtension:NO]);
            NSString *soundPath = [[NSBundle mainBundle] pathForResource:[self audioFileNameForDateComponents:dateComponents voice:self.voice includesExtension:NO] ofType:@"aiff"];
            UISound *sound = [UISound soundWithContentsOfURL:[NSURL fileURLWithPath:soundPath]];
            [sound alert];
            return;
        }
            break;
        default:
            break;
    }
    
    NSString *hourPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"Its-%.2ld", (long)hour] ofType:@"aiff"];
    NSString *minutePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%.2ld", (long)minute] ofType:@"aiff"];
    UISound *hourSound = [UISound soundWithContentsOfURL:[NSURL fileURLWithPath:hourPath]];
    UISound *minuteSound = [UISound soundWithContentsOfURL:[NSURL fileURLWithPath:minutePath]];
    
    [hourSound playWithCompletion:^(BOOL finished) {
        [minuteSound playWithCompletion:^(BOOL finished) {
            if (completion)
                completion(finished);
        }];
    }];
}

- (void)announceSilentNotification {
    NSString *silentPath = [[NSBundle mainBundle] pathForResource:@"silentN" ofType:@"aiff"];
    UISound *silentSound = [UISound soundWithContentsOfURL:[NSURL fileURLWithPath:silentPath]];

    [silentSound play];
}

- (NSString *)audioFileNameForDateComponents:(NSDateComponents *)dateComponents voice:(ACVoice)voice includesExtension:(BOOL)includesExtension {
    NSInteger hour = [dateComponents hour];
    if ([dateComponents hour] >= 12 && [dateComponents minute] != 00)
        hour -= 12;
    if (includesExtension)
        return [NSString stringWithFormat:@"%02d%02d-%@.aiff", (int)hour, (int)[dateComponents minute], [self.voicePostfixArray objectAtIndex:voice]];
    return [NSString stringWithFormat:@"%02d%02d-%@", (int)hour, (int)[dateComponents minute], [self.voicePostfixArray objectAtIndex:voice]];
}

#pragma mark - Scheduling Local Notifications
- (void)reloadAndScheduleTimeAnnouncementNotifications {
    [self reloadAndScheduleTimeAnnouncementNotificationsWithCompletion:nil];
}
- (void)reloadAndScheduleTimeAnnouncementNotificationsWithCompletion:(void (^)(BOOL finished))completion {
    [self reloadTimeAnnouncementNotificationsWithCompletion:^(BOOL finished) {
        NSArray *notificationsArray = [[UIApplication sharedApplication] scheduledLocalNotifications];
        if ([notificationsArray count] - 11 <= 0) {
            [self scheduleFutureTimeAnnouncementReloadOnDate:[NSDate dateWithTimeIntervalSinceNow:60] completion:completion];
        } else {
            [self scheduleFutureTimeAnnouncementReloadOnDate:[NSDate dateWithTimeIntervalSinceNow:60] completion:completion];
        }
    }];
}
- (void)reloadTimeAnnouncementNotifications {
    [self reloadTimeAnnouncementNotificationsWithCompletion:nil];
}
- (void)reloadTimeAnnouncementNotificationsWithCompletion:(void (^)(BOOL finished))completion {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *scheduledNotificationsArray = [[UIApplication sharedApplication] scheduledLocalNotifications];
        for (UILocalNotification *localNotification in scheduledNotificationsArray) {
            if (
                [[localNotification.userInfo objectForKey:kACNotificationType] isEqualToString:kACNotificqtionTypeTimeAnnouncement00] ||
                [[localNotification.userInfo objectForKey:kACNotificationType] isEqualToString:kACNotificqtionTypeTimeAnnouncement15] ||
                [[localNotification.userInfo objectForKey:kACNotificationType] isEqualToString:kACNotificqtionTypeTimeAnnouncement30] ||
                [[localNotification.userInfo objectForKey:kACNotificationType] isEqualToString:kACNotificqtionTypeTimeAnnouncement45]) {
                [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
            }
        }
        
        if ([self timeAnnouncementEnabled]) {
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[NSDate date]];
            
            NSUInteger numberOfNotifications = 0;
            
            if ([components minute] < 15 && [self timeAnnouncementOption] == kACTimeAnnouncementOptionOnTheQuarterHour) {
                [components setMinute:15];
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.fireDate = [calendar dateFromComponents:components];
                self.lastScheduledNotificationDate = localNotification.fireDate;
                localNotification.soundName = [self audioFileNameForDateComponents:components voice:self.voice includesExtension:YES];
                localNotification.userInfo = [NSDictionary dictionaryWithObject:kACNotificqtionTypeTimeAnnouncement15 forKey:kACNotificationType];
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            }
            if ([components minute] < 30) {
                if ([self timeAnnouncementOption] == kACTimeAnnouncementOptionOnTheHalfHour ||
                    [self timeAnnouncementOption] == kACTimeAnnouncementOptionOnTheQuarterHour) {
                    [components setMinute:30];
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.fireDate = [calendar dateFromComponents:components];
                    self.lastScheduledNotificationDate = localNotification.fireDate;
                    localNotification.soundName = [self audioFileNameForDateComponents:components voice:self.voice includesExtension:YES];
                    localNotification.userInfo = [NSDictionary dictionaryWithObject:kACNotificqtionTypeTimeAnnouncement30 forKey:kACNotificationType];
                    
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                }
            }
            if ([components minute] < 45 && [self timeAnnouncementOption] == kACTimeAnnouncementOptionOnTheQuarterHour) {
                [components setMinute:45];
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.fireDate = [calendar dateFromComponents:components];
                self.lastScheduledNotificationDate = localNotification.fireDate;
                localNotification.soundName = [self audioFileNameForDateComponents:components voice:self.voice includesExtension:YES];
                localNotification.userInfo = [NSDictionary dictionaryWithObject:kACNotificqtionTypeTimeAnnouncement45 forKey:kACNotificationType];
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            }
            
            [components setSecond:0];
            [components setMinute:0];
            NSDate *currentTimeAtZeroMinute = [calendar dateFromComponents:components];
            NSDate *oneHourIntoTheFutureDate = currentTimeAtZeroMinute;
            
            for (NSUInteger i = numberOfNotifications; i < 64; i++) {
                
                oneHourIntoTheFutureDate = [NSDate dateWithTimeInterval:3600 sinceDate:oneHourIntoTheFutureDate];
                NSDateComponents *oneHourIntoTheFutureDateComponents = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:oneHourIntoTheFutureDate];
                
                if ([self timeAnnouncementOption] == kACTimeAnnouncementOptionOnTheHour ||
                    [self timeAnnouncementOption] == kACTimeAnnouncementOptionOnTheHalfHour ||
                    [self timeAnnouncementOption] == kACTimeAnnouncementOptionOnTheQuarterHour) {
                    [oneHourIntoTheFutureDateComponents setMinute:00];
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.fireDate = [calendar dateFromComponents:oneHourIntoTheFutureDateComponents];
                    self.lastScheduledNotificationDate = localNotification.fireDate;
                    localNotification.soundName = [self audioFileNameForDateComponents:oneHourIntoTheFutureDateComponents voice:self.voice includesExtension:YES];
                    localNotification.userInfo = [NSDictionary dictionaryWithObject:kACNotificqtionTypeTimeAnnouncement00 forKey:kACNotificationType];
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                    numberOfNotifications++;
                    if (i >= kACMaximumNumberOfTimeAnnouncementNotifications)
                        break;
                }
                if ([self timeAnnouncementOption] == kACTimeAnnouncementOptionOnTheQuarterHour) {
                    [oneHourIntoTheFutureDateComponents setMinute:15];
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.fireDate = [calendar dateFromComponents:oneHourIntoTheFutureDateComponents];
                    self.lastScheduledNotificationDate = localNotification.fireDate;
                    localNotification.soundName = [self audioFileNameForDateComponents:oneHourIntoTheFutureDateComponents voice:self.voice includesExtension:YES];
                    localNotification.userInfo = [NSDictionary dictionaryWithObject:kACNotificqtionTypeTimeAnnouncement15 forKey:kACNotificationType];
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                    numberOfNotifications++;
                    i++;
                    if (i >= kACMaximumNumberOfTimeAnnouncementNotifications)
                        break;
                }
                if ([self timeAnnouncementOption] == kACTimeAnnouncementOptionOnTheQuarterHour ||
                    [self timeAnnouncementOption] == kACTimeAnnouncementOptionOnTheHalfHour) {
                    [oneHourIntoTheFutureDateComponents setMinute:30];
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.fireDate = [calendar dateFromComponents:oneHourIntoTheFutureDateComponents];
                    self.lastScheduledNotificationDate = localNotification.fireDate;
                    localNotification.soundName = [self audioFileNameForDateComponents:oneHourIntoTheFutureDateComponents voice:self.voice includesExtension:YES];
                    localNotification.userInfo = [NSDictionary dictionaryWithObject:kACNotificqtionTypeTimeAnnouncement30 forKey:kACNotificationType];
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                    numberOfNotifications++;
                    i++;
                    if (i >= kACMaximumNumberOfTimeAnnouncementNotifications)
                        break;
                }
                if ([self timeAnnouncementOption] == kACTimeAnnouncementOptionOnTheQuarterHour) {
                    [oneHourIntoTheFutureDateComponents setMinute:45];
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.fireDate = [calendar dateFromComponents:oneHourIntoTheFutureDateComponents];
                    self.lastScheduledNotificationDate = localNotification.fireDate;
                    localNotification.soundName = [self audioFileNameForDateComponents:oneHourIntoTheFutureDateComponents voice:self.voice includesExtension:YES];
                    localNotification.userInfo = [NSDictionary dictionaryWithObject:kACNotificqtionTypeTimeAnnouncement45 forKey:kACNotificationType];
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                    numberOfNotifications++;
                    i++;
                    if (i >= kACMaximumNumberOfTimeAnnouncementNotifications)
                        break;
                }
            }
        }
        if (completion)
            completion(YES);
    });
}

#pragma mark - Custom Getters

- (ACVoice)voice {
    return (ACVoice)[[NSUserDefaults standardUserDefaults] integerForKey:kACTimeAnnouncementVoiceKey];
}

- (NSArray *)voicePostfixArray {
	if (!_voicePostfixArray)
		_voicePostfixArray = [[NSArray alloc] initWithObjects:@"en-samantha-no-am-pm", nil];
	return _voicePostfixArray;
}

-(NSArray *)timeAnnouncementOptionNamesArray {
	if (!_timeAnnouncementOptionNamesArray)
		_timeAnnouncementOptionNamesArray = [NSArray arrayWithObjects:@"Every hour", @"Every half hour", @"Every 15 minutes", nil];
	return _timeAnnouncementOptionNamesArray;
}

- (BOOL)timeAnnouncementEnabled {
    _timeAnnouncementEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kACTimeAnnouncementEnabledKey];
    return _timeAnnouncementEnabled;
}

- (TimeAnnouncementOption)timeAnnouncementOption {
    NSInteger option = [[NSUserDefaults standardUserDefaults] integerForKey:kACTimeAnnouncementOptionKey];
    if (option != kACTimeAnnouncementOptionOnTheHour &&
        option != kACTimeAnnouncementOptionOnTheHalfHour &&
        option != kACTimeAnnouncementOptionOnTheQuarterHour) {
        _timeAnnouncementOption = kACTimeAnnouncementOptionOnTheQuarterHour;
        [[NSUserDefaults standardUserDefaults] setInteger:_timeAnnouncementOption forKey:kACTimeAnnouncementOptionKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else
        _timeAnnouncementOption = (TimeAnnouncementOption)option;
    return _timeAnnouncementOption;
}

#pragma mark - Custom Setters

- (void)setDeviceToken:(NSString *)deviceToken {
    if (_deviceToken != deviceToken) {
        _deviceToken = deviceToken;
        [self reloadAndScheduleTimeAnnouncementNotifications];
    }
}

- (void)setVoice:(ACVoice)voice {
    switch (voice) {
        case kACVoiceFemaleEnglishSamantha:
            [[NSUserDefaults standardUserDefaults] setInteger:voice forKey:kACTimeAnnouncementVoiceKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            break;
        default:
            break;
    }
}

- (void)setTimeAnnouncementEnabled:(BOOL)timeAnnouncementEnabled {
    if (_timeAnnouncementEnabled != timeAnnouncementEnabled) {
        _timeAnnouncementEnabled = timeAnnouncementEnabled;
        [[NSUserDefaults standardUserDefaults] setBool:_timeAnnouncementEnabled forKey:kACTimeAnnouncementEnabledKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:kACTimeAnnouncementEnabledValueDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:_timeAnnouncementEnabled], kACTimeAnnouncementEnabledKey, nil]];
        [self reloadAndScheduleTimeAnnouncementNotifications];
    }
}

- (void)setTimeAnnouncementOption:(TimeAnnouncementOption)timeAnnouncementOption {
    if (_timeAnnouncementOption != timeAnnouncementOption) {
        TimeAnnouncementOption oldTimeAnnouncementOption = _timeAnnouncementOption;
        _timeAnnouncementOption = timeAnnouncementOption;
        [[NSUserDefaults standardUserDefaults] setInteger:_timeAnnouncementOption forKey:kACTimeAnnouncementOptionKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:kACTimeAnnouncementOptionValueDidChangeNotification
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    [NSNumber numberWithInteger:_timeAnnouncementOption], kACTimeAnnouncementOptionKey,
                                                                    [NSNumber numberWithInteger:oldTimeAnnouncementOption], kACTimeANnouncementOptionOldValueKey, nil]];
        [self reloadAndScheduleTimeAnnouncementNotifications];
    }
}

#pragma mark - Push Notification

#pragma mark -
- (void)scheduleFutureTimeAnnouncementReloadOnDate:(NSDate *)scheduledDate {
    [self scheduleFutureTimeAnnouncementReloadOnDate:scheduledDate completion:nil];
}
- (void)scheduleFutureTimeAnnouncementReloadOnDate:(NSDate *)scheduledDate completion:(void (^)(BOOL finished))completion {

    NSDateFormatter *gmtDateFormatter = [[NSDateFormatter alloc] init];
    gmtDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    gmtDateFormatter.dateFormat = @"yyyy-MM-dd~HH:mm:ss";

    NSArray *sortedArrayOfNotifications = [[[UIApplication sharedApplication] scheduledLocalNotifications] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"fireDate" ascending:NO]]];
    UILocalNotification *lastNotification = [sortedArrayOfNotifications firstObject];
    
    if ([sortedArrayOfNotifications count] > 0) {
        NSLog(@"First Scheduled Notification: %@", [(UILocalNotification *)[sortedArrayOfNotifications objectAtIndex:0] fireDate]);
        NSLog(@"Last  Scheduled Notification: %@", [(UILocalNotification *)[sortedArrayOfNotifications lastObject] fireDate]);
        NSLog(@"Current Date: %@", [NSDate date]);
    } else {
        NSLog(@"No Notification Scheduled");
    }

    NSString *testingParameter = @"environment=production";
#ifdef DEBUG
    testingParameter = @"environment=sandbox&";
#endif
    NSString *versionNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSLog(@"VersionNumber = %@", versionNumber);
    NSLog(@"BuildNumber = %@", buildNumber);

    NSUInteger timeAnnouncementEnabledInteger = 0;
    NSDate *lastScheduledAnnouncementDate = [NSDate date];
    if (self.timeAnnouncementEnabled) {
        timeAnnouncementEnabledInteger = 1;
        lastScheduledAnnouncementDate = lastNotification.fireDate;
    }
    
    if (!self.deviceToken || [self.deviceToken isEqualToString:@""])
        return;
    
    NSString *urlString = [NSString stringWithFormat:@"http://pixelicious.com.hk/tellapp/didFinishReloading.php?%@time_announcement_enabled=%lu&time_announcement_option=%d&device_token=%@&last_scheduled_announcement_date=%@&version=%@&build=%@", testingParameter, (unsigned long)timeAnnouncementEnabledInteger, (int)self.timeAnnouncementOption, self.deviceToken, [gmtDateFormatter stringFromDate:lastScheduledAnnouncementDate], [versionNumber urlencode], [buildNumber urlencode]];
    NSLog(@"urlString = %@", urlString);
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            NSLog(@"ConnectionError: %@", [connectionError localizedDescription]);
            if (completion)
                completion(NO);
        } else {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"response: %@", responseString);
            if (completion)
                completion(YES);
        }
    }];
}



@end
