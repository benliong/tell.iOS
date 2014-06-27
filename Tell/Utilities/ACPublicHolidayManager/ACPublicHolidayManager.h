//
//  ACPublicHolidayManager.h
//  Tell
//
//  Created by Ben Liong on 27/6/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface ACPublicHolidayManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
+ (id)sharedManager;
- (void)updateSupportedCountriesAsync;
- (void)updatePublicHolidayAsyncForCountry:(NSString *)countryCode;
- (void)updatePublicHolidayAsyncForCountry:(NSString *)countryCode
                                  fromDate:(NSDate *)fromDate
                                    toDate:(NSDate *)toDate;
@end
