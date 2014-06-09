//
//  ACSwitchTableViewCell.m
//  Tell
//
//  Created by Ben Liong on 9/6/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import "ACSwitchTableViewCell.h"

@interface ACSwitchTableViewCell ()
- (IBAction)switchValueDidChange:(id)sender;
@end

@implementation ACSwitchTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)switchValueDidChange:(id)sender {
    if ([self.delegate respondsToSelector:@selector(switchTableViewCell:valueDidChange:)])
        [self.delegate switchTableViewCell:self valueDidChange:self.cellSwitch.isOn];
}

@end
