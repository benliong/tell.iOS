//
//  ACSwitchTableViewCell.h
//  Tell
//
//  Created by Ben Liong on 9/6/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ACSwitchTableViewCellDelegate;

@interface ACSwitchTableViewCell : UITableViewCell
@property (nonatomic, assign) IBOutlet UISwitch *cellSwitch;
@property (nonatomic, assign) id<ACSwitchTableViewCellDelegate> delegate;
@end

@protocol ACSwitchTableViewCellDelegate <NSObject>

- (void)switchTableViewCell:(ACSwitchTableViewCell *)anACSwitchTableViewCell valueDidChange:(BOOL)isOn;

@end