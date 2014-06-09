//
//  ACAnnouncementManager.m
//  Tell
//
//  Created by Ben Liong on 8/6/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import "ACAnnouncementManager.h"
#import "UISound.h"

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

- (NSString *)audioFileNameForDateComponents:(NSDateComponents *)dateComponents voice:(ACVoice)voice includesExtension:(BOOL)includesExtension {
    if (includesExtension)
        return [NSString stringWithFormat:@"%02d%02d-%@.aiff", (int)[dateComponents hour], (int)[dateComponents minute], [self.voicePostfixArray objectAtIndex:voice]];
    return [NSString stringWithFormat:@"%02d%02d-%@", (int)[dateComponents hour], (int)[dateComponents minute], [self.voicePostfixArray objectAtIndex:voice]];
}

#pragma mark - Scheduling Local Notifications

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
    BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:kACTimeAnnouncementEnabledKey];
    return enabled;
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

- (void)setTimeAnnouncementEnabled:(BOOL)timeAnnouncementEnabled {
    if (_timeAnnouncementEnabled != timeAnnouncementEnabled) {
        _timeAnnouncementEnabled = timeAnnouncementEnabled;
        [[NSUserDefaults standardUserDefaults] setBool:_timeAnnouncementEnabled forKey:kACTimeAnnouncementEnabledKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:kACTimeAnnouncementEnabledValueDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:_timeAnnouncementEnabled], kACTimeAnnouncementEnabledKey, nil]];
        [self reloadTimeAnnouncementNotifications];
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
        [self reloadTimeAnnouncementNotifications];
    }
}

#pragma mark - Push Notification

- (void)scheduleFutureTimeAnnouncementReload {
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
//    
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    NSLog(@"Device Token = %@", [currentInstallation deviceToken]);
//    NSLog(@"Date = %@", self.lastScheduledNotificationDate);
//    //
//    //    PFQuery *devicesFilter = [PFInstallation query];
//    //    [devicesFilter whereKey:@"deviceToken" containedIn:[NSArray arrayWithObject:[currentInstallation deviceToken]]];
//    //
//    //    [PFPush sendPushMessageToQueryInBackground:devicesFilter
//    //                                   withMessage:@"You have a new todo!"];
//    
//    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.parse.com/1/push"]];
//    [urlRequest setHTTPMethod:@"POST"];
//    [urlRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
//    [urlRequest setValue:@"rZLWR0IcWvwRU6aBkAZxqCyfbYamoH35onufGz49" forHTTPHeaderField:@"X-Parse-Application-Id"];
//    [urlRequest setValue:@"24J9SiWbHAw328rzncXuYzBYJIrfBEBgyGLYJ6fR" forHTTPHeaderField:@"X-Parse-REST-API-Key"];
//    
//    NSMutableDictionary *postDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
//                                           [NSDictionary dictionaryWithObjectsAndKeys:
//                                            [currentInstallation deviceToken], @"deviceToken",
//                                            //                                            @"ios", @"deviceType",
//                                            nil],                                                               @"where",
//                                           [dateFormatter stringFromDate:self.lastScheduledNotificationDate], @"push_time",
//                                           [NSDictionary dictionaryWithObjectsAndKeys:
//                                            [NSNumber numberWithBool:YES], @"content-available",
//                                            [NSNumber numberWithInteger:kACPushNotificationTypeRefresh],            kACPushNotificationType,
//                                            //
//                                            //                                            @"test", @"alert",
//                                            nil],                                                                   @"data",
//                                           nil];
//    NSError *error = nil;
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postDictionary
//                                                       options:0
//                                                         error:&error];
//    //    NSLog(@"Payload size: %lu", (unsigned long)[jsonData length]);
//    //    NSLog(@"JSON String: %@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
//    [urlRequest setHTTPBody:jsonData];
//    
//    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
//        //        NSLog(@"Data Received: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//    }];
}


@end
