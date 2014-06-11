//
//  ACBigClockTableViewCell.m
//  Tell
//
//  Created by Ben Liong on 9/6/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import "ACBigClockTableViewCell.h"
#import "NSTimer+Blocks.h"
#import "ACAnnouncementManager.h"

@interface ACBigClockTableViewCell ()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation ACBigClockTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
    self.currentTimeLabel.text = [self.dateFormatter stringFromDate:[NSDate date]];
    [NSTimer scheduledTimerWithTimeInterval:1.0f block:^{
        NSDate *date = [NSDate date];
        self.currentTimeLabel.text = [self.dateFormatter stringFromDate:date];
        if ([[[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:date] hour] < 12)
            self.ampmLabel.text = @"AM";
        else
            self.ampmLabel.text = @"PM";
            
    } repeats:YES];
    [[NSNotificationCenter defaultCenter] addObserverForName:kACTimeAnnouncementOptionValueDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self reloadData];
                                                  }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Custom Getters

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"hh:mm:ss";
    }
    return _dateFormatter;
}

#pragma mark - 

- (void)reloadData {
    TimeAnnouncementOption timeAnnouncementOption = [[ACAnnouncementManager sharedManager] timeAnnouncementOption];
    NSArray *number = [NSArray arrayWithObjects:@"0", @"15", @"30", @"45", nil];
    
    NSMutableString *description = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"Announcing time every %@ minutes, at ", [number objectAtIndex:timeAnnouncementOption]]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"hh";
    NSString *hourString = [dateFormatter stringFromDate:[NSDate date]];
    switch (timeAnnouncementOption) {
        case kACTimeAnnouncementOptionOnTheQuarterHour:
        {
            [description appendFormat:@"%@:00, %@:15, %@:45 ...", hourString, hourString, hourString];
            self.timeAnnouncementDescriptionLabel.text = description;
        }
            break;
        case kACTimeAnnouncementOptionOnTheHalfHour:
        {
            [description appendFormat:@"%@:00, %@:30, %ld:30 ...", hourString, hourString, (long)([hourString integerValue]+1)];
            self.timeAnnouncementDescriptionLabel.text = description;
        }
            break;
        case kACTimeAnnouncementOptionOnTheHour:
        {
            [description appendFormat:@"%@:00, %ld:00, %ld:00 ...", hourString, (long)([hourString integerValue]+1), (long)([hourString integerValue]+2)];
            self.timeAnnouncementDescriptionLabel.text = description;
        }
            
        default:
            break;
    }
}

@end
