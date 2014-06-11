//
//  ACClockViewController.m
//  Tell
//
//  Created by Ben Liong on 9/6/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import "ACClockViewController.h"
#import "ACBigClockTableViewCell.h"
#import "ACSwitchTableViewCell.h"
#import "ACAnnouncementManager.h"
#import "UIImage+ImageEffects.h"
#import "UIImageView+Crossfade.h"
#import <FlickrKit/FlickrKit.h>

#define kACTableViewSectionBigClock             0
#define kACTableViewSectionTimeAnnouncement     1
#define kACTableViewSectionCredit               2
#define kACCrossFadeDuration                    1.0

CGFloat const kBlurredImageDefaultBlurRadius            = 20.0;
CGFloat const kBlurredImageDefaultSaturationDeltaFactor = 1.8;
CGFloat const kBackgroundDelta                          = 10.0f;

@interface ACClockViewController () <UITableViewDelegate, UITableViewDataSource, ACSwitchTableViewCellDelegate>
@property (nonatomic, assign) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, assign) IBOutlet UIImageView *blurredBackgroundImageView;
@property (nonatomic, assign) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *dawnImages;
@property (nonatomic, strong) NSArray *morningImages;
@property (nonatomic, strong) NSArray *afternoonImages;
@property (nonatomic, strong) NSArray *eveningImages;
@property (nonatomic, strong) NSArray *nightImages;
@property (nonatomic, assign) NSUInteger flickrDownloadCompletionCount;

@property (nonatomic, strong) NSArray *timeAnnouncementDescriptionsArray;
@end

@implementation ACClockViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    self.backgroundImageView.frame = CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height + kBackgroundDelta);
//    self.blurredBackgroundImageView.frame = self.backgroundImageView.frame;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setBackgroundWithImage:[UIImage imageNamed:@"background-night.jpg"]];
    });
  
    __weak ACClockViewController* sself = self;
    [self getImageFromFlickrForTags:@"dawn" completion:^(NSArray *photoDictionariesArray, NSError *error) {
        sself.dawnImages = photoDictionariesArray;
        dispatch_async(dispatch_get_main_queue(), ^{
            sself.flickrDownloadCompletionCount++;
            if (sself.flickrDownloadCompletionCount == 5)
                [sself reloadBackground];
        });
    }];
    
    [self getImageFromFlickrForTags:@"morning" completion:^(NSArray *photoDictionariesArray, NSError *error) {
        sself.morningImages = photoDictionariesArray;
        dispatch_async(dispatch_get_main_queue(), ^{
            sself.flickrDownloadCompletionCount++;
            if (sself.flickrDownloadCompletionCount == 5)
                [sself reloadBackground];
        });
    }];
    
    [self getImageFromFlickrForTags:@"afternoon" completion:^(NSArray *photoDictionariesArray, NSError *error) {
        sself.afternoonImages = photoDictionariesArray;
        dispatch_async(dispatch_get_main_queue(), ^{
            sself.flickrDownloadCompletionCount++;
            if (sself.flickrDownloadCompletionCount == 5)
                [sself reloadBackground];
        });
    }];
    
    [self getImageFromFlickrForTags:@"evening" completion:^(NSArray *photoDictionariesArray, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            sself.eveningImages = photoDictionariesArray;
            sself.flickrDownloadCompletionCount++;
            if (sself.flickrDownloadCompletionCount == 5)
                [sself reloadBackground];
        });
    }];
    
    [self getImageFromFlickrForTags:@"night" completion:^(NSArray *photoDictionariesArray, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            sself.nightImages = photoDictionariesArray;
            sself.flickrDownloadCompletionCount++;
            if (sself.flickrDownloadCompletionCount == 5)
                [sself reloadBackground];
        });
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    float maximumOffset = self.tableView.contentSize.height - self.tableView.bounds.size.height;
    float blurFactor = self.tableView.contentOffset.y / maximumOffset;
    float backgroundDelta = blurFactor;
    if (blurFactor > 1.0f) {
        blurFactor = 1.0f;
        backgroundDelta = 1.0f;
    }
    if (blurFactor <= 0.0f) {
        blurFactor = 0.1f;
        backgroundDelta = 0.0f;
    }
    
    self.blurredBackgroundImageView.alpha = blurFactor;
    CGRect oldFrame = self.backgroundImageView.frame;
    CGRect newFrame = oldFrame;
    newFrame.origin.y = self.view.frame.origin.y - (backgroundDelta * kBackgroundDelta);
    self.backgroundImageView.frame = newFrame;
    self.blurredBackgroundImageView.frame = newFrame;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == kACTableViewSectionTimeAnnouncement) {
    TimeAnnouncementOption selectedTimeAnnouncementOption = (TimeAnnouncementOption)(indexPath.row);
        if ([[ACAnnouncementManager sharedManager] timeAnnouncementOption] != selectedTimeAnnouncementOption) {
            TimeAnnouncementOption previousTimeAnnouncementOption = [[ACAnnouncementManager sharedManager] timeAnnouncementOption];
            [[ACAnnouncementManager sharedManager] setTimeAnnouncementOption:selectedTimeAnnouncementOption];
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:previousTimeAnnouncementOption inSection:kACTableViewSectionTimeAnnouncement], indexPath, nil] withRowAnimation:UITableViewRowAnimationAutomatic];
            
        }
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kACTableViewSectionBigClock:
            return 569.0f;
            break;
        case kACTableViewSectionCredit:
            return 20.0f;
        default:
            return tableView.rowHeight;
            break;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case kACTableViewSectionBigClock:
            return 1;
            break;
        case kACTableViewSectionTimeAnnouncement:
        {
            if ([[ACAnnouncementManager sharedManager] timeAnnouncementEnabled])
                return 4;
            else
                return 1;
        }
            break;
        case kACTableViewSectionCredit:
            return 1;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kACTableViewSectionBigClock) {
        ACBigClockTableViewCell *cell = (ACBigClockTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ACBigClockTableViewCell" forIndexPath:indexPath];
        return cell;
    } else if (indexPath.section == kACTableViewSectionTimeAnnouncement) {
        if (indexPath.row == kACTimeAnnouncementOptionOnTheHour ||
            indexPath.row == kACTimeAnnouncementOptionOnTheHalfHour ||
            indexPath.row == kACTimeAnnouncementOptionOnTheQuarterHour) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimeAnnouncementOptionCell" forIndexPath:indexPath];
            cell.textLabel.text = [[[ACAnnouncementManager sharedManager] timeAnnouncementOptionNamesArray] objectAtIndex:indexPath.row-1];
            if ([[ACAnnouncementManager sharedManager] timeAnnouncementOption] == indexPath.row) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            return cell;
        } else {
            ACSwitchTableViewCell *cell = (ACSwitchTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ACSwitchTableViewCell" forIndexPath:indexPath];
            cell.delegate = self;
            cell.cellSwitch.on = [[ACAnnouncementManager sharedManager] timeAnnouncementEnabled];
            return cell;
        }
        
    } else if (indexPath.section == kACTableViewSectionCredit) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CreditCell" forIndexPath:indexPath];
        cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, cell.bounds.size.width);
        return cell;
    }
    return [[UITableViewCell alloc] init];
}

#pragma mark - Flickr

- (void)getImageFromFlickrForTags:(NSString *)tags completion:(void (^)(NSArray *photoDictionariesArray, NSError *error))completion {
    [[FlickrKit sharedFlickrKit] initializeWithAPIKey:@"70333bf54a16ef9eb10727dccdd45599" sharedSecret:@"037c0593985ee59f"];
    FKFlickrGroupsPoolsGetPhotos *search = [[FKFlickrGroupsPoolsGetPhotos alloc] init];
    search.group_id = @"1463451@N25";
    search.tags = tags;
    search.per_page = @"500";
    [[FlickrKit sharedFlickrKit] call:search completion:^(NSDictionary *response, NSError *error) {
        if (!error) {
            NSArray *photoDictionariesArray = (NSArray *)[response valueForKeyPath:@"photos.photo"];
            if (completion)
                completion(photoDictionariesArray, error);
        } else {
            NSLog(@"Error = %@", [error localizedDescription]);
            if (completion)
                completion(nil, error);
        }
    }];
}

#pragma mark - ACSwitchTableViewCellDelegate

- (void)switchTableViewCell:(ACSwitchTableViewCell *)anACSwitchTableViewCell valueDidChange:(BOOL)isOn {
    [[ACAnnouncementManager sharedManager] setTimeAnnouncementEnabled:isOn];
    NSArray *indexPathsArray = [NSArray arrayWithObjects:
                                                [NSIndexPath indexPathForRow:kACTimeAnnouncementOptionOnTheHour inSection:kACTableViewSectionTimeAnnouncement],
                                                [NSIndexPath indexPathForRow:kACTimeAnnouncementOptionOnTheHalfHour inSection:kACTableViewSectionTimeAnnouncement],
                                                [NSIndexPath indexPathForRow:kACTimeAnnouncementOptionOnTheQuarterHour inSection:kACTableViewSectionTimeAnnouncement], nil];
    if ([[ACAnnouncementManager sharedManager] timeAnnouncementEnabled]) {
        [self.tableView insertRowsAtIndexPaths:indexPathsArray withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kACTableViewSectionCredit] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    } else {
        [self.tableView deleteRowsAtIndexPaths:indexPathsArray withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - Custom Getters


#pragma mark -

- (IBAction)didPressTestButton:(id)sender {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setHour:14];
    [components setMinute:45];
    NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:components];
    [[ACAnnouncementManager sharedManager] announceDate:date];
}

- (void)reloadBackground {
    __weak ACClockViewController* sself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSLog(@"Number of night images = %lu", (unsigned long)[sself.nightImages count]);
        NSUInteger randomIndex = arc4random() % ([sself.nightImages count] - 1);
        NSLog(@"Random Integer = %lu", (unsigned long)randomIndex);
        NSDictionary *randomPhotoDictionary = [sself.nightImages objectAtIndex:randomIndex];
        NSLog(@"randomPhotoDictionary: %@", randomPhotoDictionary);
        NSURL *url = [[FlickrKit sharedFlickrKit] photoURLForSize:FKPhotoSizeLarge1024 fromPhotoDictionary:randomPhotoDictionary];

        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
        if (!error && data) {
            UIImage* image = [[UIImage alloc] initWithData:data];
            [sself setBackgroundWithImage:image];
        }
    });
}

- (void)setBackgroundWithImage:(UIImage *)image {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        UIImage *blurredImage = [image applyBlurWithRadius:kBlurredImageDefaultBlurRadius
                                                 tintColor:nil
                                     saturationDeltaFactor:kBlurredImageDefaultSaturationDeltaFactor
                                                 maskImage:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            CABasicAnimation *crossFade = [CABasicAnimation animationWithKeyPath:@"contents"];
            crossFade.duration = kACCrossFadeDuration;
            crossFade.fromValue = (__bridge id)(self.backgroundImageView.image.CGImage);
            crossFade.toValue = (__bridge id)(image.CGImage);
            [self.backgroundImageView.layer addAnimation:crossFade forKey:@"animateContents"];
            self.backgroundImageView.image = image;

            crossFade.duration = kACCrossFadeDuration;
            crossFade.fromValue = (__bridge id)(self.blurredBackgroundImageView.image.CGImage);
            crossFade.toValue = (__bridge id)(blurredImage.CGImage);
            [self.blurredBackgroundImageView.layer addAnimation:crossFade forKey:@"animateContents"];
            self.blurredBackgroundImageView.image = blurredImage;
        });
    });
}

@end
