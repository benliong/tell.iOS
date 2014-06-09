//
//  ACBigClockTableViewCell.m
//  Tell
//
//  Created by Ben Liong on 9/6/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import "ACBigClockTableViewCell.h"
#import "NSTimer+Blocks.h"

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
        self.currentTimeLabel.text = [self.dateFormatter stringFromDate:[NSDate date]];
    } repeats:YES];
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

@end
