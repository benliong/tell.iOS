//
//  ACPublicHolidayManager.m
//  Tell
//
//  Created by Ben Liong on 27/6/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import "ACPublicHolidayManager.h"
#import <MapKit/MapKit.h>

#define kACPublicHolidayAPIURL @"http://kayaposoft.com/enrico/json/v1.0/index.php"

@interface ACPublicHolidayManager ()
@property (nonatomic, strong) NSArray *supportedCountries;
@property (nonatomic, strong) NSString *currentCountryCode;
@property (nonatomic, strong) NSArray *holidaysArray;
@end

@implementation ACPublicHolidayManager

+ (id)sharedManager {
    static ACPublicHolidayManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)startUpdatingLocation {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    [self.locationManager startUpdatingLocation];
}

- (void)updateSupportedCountriesAsync {
    [self startUpdatingLocation];
    
    NSLocale *locale = [NSLocale currentLocale];
    NSArray *countryArray = [NSLocale ISOCountryCodes];
    
    //    NSMutableArray *sortedCountryArray = [[NSMutableArray alloc] init];
    
    for (NSString *countryCode in countryArray) {
        
        NSString *displayNameString = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
        NSLog(@"CountryCode: %@, %@", countryCode, displayNameString);
        //        [sortedCountryArray addObject:displayNameString];
        
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@?action=getSupportedCountries", kACPublicHolidayAPIURL];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setURL:[NSURL URLWithString:urlString]];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    __weak typeof(self) weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                           NSError *error = nil;
                                           NSArray* jsonArray = [NSJSONSerialization JSONObjectWithData:data
                                                                                                options:kNilOptions
                                                                                                  error:&error];
                                           weakSelf.supportedCountries = jsonArray;
                                           [weakSelf startUpdatingLocation];
                                       }];
}

- (void)updatePublicHolidayAsyncForCountry:(NSString *)countryCode
                                  fromDate:(NSDate *)fromDate
                                    toDate:(NSDate *)toDate {
    __weak typeof(self) weakSelf = self;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"dd-MM-yyyy";
    
    NSString *urlString = [NSString stringWithFormat:@"%@?action=getPublicHolidaysForDateRange&fromDate=%@&toDate=%@&country=%@&region=%@", kACPublicHolidayAPIURL, [dateFormatter stringFromDate:fromDate], [dateFormatter stringFromDate:toDate], countryCode, @""];
    NSLog(@"URL = %@", urlString);
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setURL:[NSURL URLWithString:urlString]];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                           NSError *error = nil;
                                           NSArray *holidaysArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                           NSMutableArray *holidaysMutableArray = [[NSMutableArray alloc] init];
                                           for (NSDictionary *holidayDictionary in holidaysArray) {
                                               NSDate *date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@-%@-%@",
                                                                                             [[holidayDictionary objectForKey:@"date"] objectForKey:@"day"],
                                                                                             [[holidayDictionary objectForKey:@"date"] objectForKey:@"month"],
                                                                                             [[holidayDictionary objectForKey:@"date"] objectForKey:@"year"]]];
                                               NSMutableDictionary *holidayMutableDictionary = [NSMutableDictionary dictionaryWithDictionary:holidayDictionary];
                                               [holidayMutableDictionary setObject:date forKey:@"nsdate"];
                                               [holidaysMutableArray addObject:holidayMutableDictionary];
                                           }
                                           weakSelf.holidaysArray = holidaysMutableArray;
                                           NSLog(@"From %@ to %@", [dateFormatter stringFromDate:fromDate], [dateFormatter stringFromDate:toDate]);
                                           NSLog(@"holidays: %@", weakSelf.holidaysArray);
                                       }];
}


- (void)updatePublicHolidayAsyncForCountry:(NSString *)countryCode {
    __weak typeof(self) weakSelf = self;
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:(NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:[NSDate date]];
    
    NSString *urlString = [NSString stringWithFormat:@"%@?action=getPublicHolidaysForMonth&month=%ld&year=%ld&country=%@&region=", kACPublicHolidayAPIURL, (long)[dateComponents month], (long)[dateComponents year], countryCode];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setURL:[NSURL URLWithString:urlString]];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                           NSError *error = nil;
                                           NSArray *holidaysArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                           NSMutableArray *holidaysMutableArray = [[NSMutableArray alloc] init];
                                           for (NSDictionary *holidayDictionary in holidaysArray) {
                                               NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                               dateFormatter.dateFormat = @"dd-MM-yyyy";
                                               NSDate *date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@-%@-%@",
                                                                                             [[holidayDictionary objectForKey:@"date"] objectForKey:@"day"],
                                                                                             [[holidayDictionary objectForKey:@"date"] objectForKey:@"month"],
                                                                                             [[holidayDictionary objectForKey:@"date"] objectForKey:@"year"]]];
                                               NSMutableDictionary *holidayMutableDictionary = [NSMutableDictionary dictionaryWithDictionary:holidayDictionary];
                                               [holidayMutableDictionary setObject:date forKey:@"nsdate"];
                                               [holidaysMutableArray addObject:holidayMutableDictionary];
                                           }
                                           weakSelf.holidaysArray = holidaysMutableArray;
                                           NSLog(@"holidays: %@", weakSelf.holidaysArray);
                                       }];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
	 didUpdateLocations:(NSArray *)locations {
    [manager stopUpdatingLocation];
    __weak typeof(self) weakSelf = self;
    CLLocation *location = [locations lastObject];
    [[[CLGeocoder alloc] init] reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = [placemarks firstObject];
        for (NSDictionary *countryDictionary in weakSelf.supportedCountries) {
            NSString *fullName = [countryDictionary objectForKey:@"fullName"];
            if ([placemark.country isEqualToString:fullName]) {
//                [weakSelf updatePublicHolidayAsyncForCountry:[countryDictionary objectForKey:@"countryCode"]];
                [weakSelf updatePublicHolidayAsyncForCountry:[countryDictionary objectForKey:@"countryCode"]
                                                    fromDate:[NSDate date]
                                                      toDate:[[NSDate date] dateByAddingTimeInterval:31 * 24 * 60 * 60]];
                break;
            }
        }
        NSLog(@"Current Country: %@ (%@)", placemark.country, placemark.ISOcountryCode);
    }];
}
@end
