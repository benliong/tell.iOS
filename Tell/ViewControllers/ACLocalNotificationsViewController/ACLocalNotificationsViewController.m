//
//  ACLocalNotificationsViewController.m
//  Tell
//
//  Created by Ben Liong on 8/6/14.
//  Copyright (c) 2014 Pixelicious Software. All rights reserved.
//

#import "ACLocalNotificationsViewController.h"
#import "ACAppDelegate.h"
#import "ACAnnouncementManager.h"

@interface ACLocalNotificationsViewController ()
@property (nonatomic, strong) NSArray *notificationsArray;
- (IBAction)didPressReloadButton:(id)sender;
- (IBAction)didPressDoneButton:(id)sender;
@end

@implementation ACLocalNotificationsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[ACAnnouncementManager sharedManager] announceDate:[[self.notificationsArray objectAtIndex:indexPath.row] fireDate]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.notificationsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"NotificationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MMM dd, yyyy HH:mm";

    UILocalNotification *notification = [self.notificationsArray objectAtIndex:indexPath.row];
    cell.textLabel.text = notification.soundName;
    cell.detailTextLabel.text = [dateFormatter stringFromDate:notification.fireDate];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - 

- (void)reloadData {
    self.notificationsArray = [[UIApplication sharedApplication] scheduledLocalNotifications];
}

- (IBAction)didPressReloadButton:(id)sender {
    [self reloadData];
    [self.tableView reloadData];
}

- (IBAction)didPressDoneButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
