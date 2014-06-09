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

#define kACTableViewSectionBigClock             0
#define kACTableViewSectionTimeAnnouncement     1
#define kACCrossFadeDuration                    1.0

CGFloat const kBlurredImageDefaultBlurRadius            = 20.0;
CGFloat const kBlurredImageDefaultSaturationDeltaFactor = 1.8;

@interface ACClockViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, assign) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, assign) IBOutlet UIImageView *blurredBackgroundImageView;
@property (nonatomic, assign) IBOutlet UITableView *tableView;
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setBackgroundWithImage:[UIImage imageNamed:@"background-night.jpg"]];
    });
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
    if (blurFactor > 1.0f)
        blurFactor = 1.0f;
    if (blurFactor <= 0.0f)
        blurFactor = 0.1;
    self.blurredBackgroundImageView.alpha = blurFactor;
    NSLog(@"maximumOffset = %f", maximumOffset);
    NSLog(@"contentOffset.y = %f", self.tableView.contentOffset.y);
    NSLog(@"blurFactor = %f", blurFactor);
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kACTableViewSectionBigClock:
            return 569.0f;
            break;
            
        default:
            return tableView.rowHeight;
            break;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case kACTableViewSectionBigClock:
            return 1;
            break;
        case kACTableViewSectionTimeAnnouncement:
            return 4;
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
            cell.cellSwitch.on = [[ACAnnouncementManager sharedManager] timeAnnouncementEnabled];
            return cell;
        }
        
    }
    return [[UITableViewCell alloc] init];
}

#pragma mark -

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
