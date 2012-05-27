//
//  WebsiteTableViewController.m
//  MageReader
//
//  Created by shinysky on 11-2-5.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "QuartzCore/QuartzCore.h"
#import "WebsiteTableViewController.h"
#import "Website.h"
#import "ICMAppDelegate.h"
#import "ICMConnectivityTester.h"

@implementation WebsiteTableViewController

@synthesize managedObjectContext;


-(id)initWithCoder:(NSCoder *)aDecoder {
    
    if ((self = [super initWithCoder:aDecoder])) {
        self.managedObjectContext = [ICMAppDelegate GetContext];;
		self.titleKey = @"name";
		self.subtitleKey = nil;
		//self.searchKey = nil;//@"text";
        selectedIndex = -1;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Website";
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    [self performFetchAndReload];
}

- (void)viewDidUnload {
    refreshBtn = nil;
}

- (void)dealloc {

    self.managedObjectContext = nil;
}

- (void)performFetchAndReload
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Website" inManagedObjectContext:self.managedObjectContext];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                     ascending:YES
                                                                                      selector:nil]];

    //request.predicate = [NSPredicate predicateWithFormat:@"(tags CONTAINS %@)", tag];
    request.fetchBatchSize = 20;
    
    [NSFetchedResultsController deleteCacheWithName:nil];
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc]
                                       initWithFetchRequest:request
                                       managedObjectContext:self.managedObjectContext
                                       sectionNameKeyPath:nil
                                       cacheName:@"WebsiteCache"];
    
    request = nil;
    
    self.fetchedResultsController = frc;
    frc = nil;
    
    // fetch and reload
    [self performFetchForTableView:self.tableView];
    
    NSArray* websites = [self.fetchedResultsController fetchedObjects];
    if ([websites count] <= 0) {
        // init database
        
        Website* site = [NSEntityDescription insertNewObjectForEntityForName:@"Website"
                                                      inManagedObjectContext:managedObjectContext];
        [site initWithUrl:@"http://www.google.com" name:@"Google" enabled:true uid:1001];
        site = [NSEntityDescription insertNewObjectForEntityForName:@"Website"
                                             inManagedObjectContext:managedObjectContext];
        [site initWithUrl:@"http://www.facebook.com" name:@"Facebook" enabled:true uid:1002];
        site = [NSEntityDescription insertNewObjectForEntityForName:@"Website"
                                             inManagedObjectContext:managedObjectContext];
        [site initWithUrl:@"http://www.youtube.com" name:@"YouTube" enabled:true uid:1003];
        site = [NSEntityDescription insertNewObjectForEntityForName:@"Website"
                                             inManagedObjectContext:managedObjectContext];
        [site initWithUrl:@"http://www.twitter.com" name:@"Twitter" enabled:true uid:1004];
        site = [NSEntityDescription insertNewObjectForEntityForName:@"Website"
                                             inManagedObjectContext:managedObjectContext];
        [site initWithUrl:@"http://www.yahoo.com" name:@"Yahoo" enabled:true uid:1005];
        site = [NSEntityDescription insertNewObjectForEntityForName:@"Website"
                                             inManagedObjectContext:managedObjectContext];
        [site initWithUrl:@"http://www.cnn.com" name:@"CNN" enabled:true uid:1006];
        site = [NSEntityDescription insertNewObjectForEntityForName:@"Website"
                                             inManagedObjectContext:managedObjectContext];
        [site initWithUrl:@"http://www.bbc.com" name:@"BBC" enabled:true uid:1007];
        site = [NSEntityDescription insertNewObjectForEntityForName:@"Website"
                                             inManagedObjectContext:managedObjectContext];
        [site initWithUrl:@"http://www.gmail.com" name:@"GMail" enabled:true uid:1008];
        site = [NSEntityDescription insertNewObjectForEntityForName:@"Website"
                                             inManagedObjectContext:managedObjectContext];
        [site initWithUrl:@"http://www.umitproject.org" name:@"Umit Project" enabled:true uid:1009];
        site = [NSEntityDescription insertNewObjectForEntityForName:@"Website"
                                             inManagedObjectContext:managedObjectContext];
        [site initWithUrl:@"http://www.flickr.com" name:@"Flickr" enabled:true uid:1010];
        site = [NSEntityDescription insertNewObjectForEntityForName:@"Website"
                                             inManagedObjectContext:managedObjectContext];
        [site initWithUrl:@"http://www.hotmail.com" name:@"Hotmail" enabled:true uid:1011];
        
        [ICMAppDelegate SaveContext];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForManagedObject:(NSManagedObject *)managedObject atIndex:(NSIndexPath *)indexPath
{
    //do customizing here
    static NSString *ReuseIdentifier = @"CoreDataTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];
    if (cell == nil) {
        //cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:ReuseIdentifier] autorelease];
        
        UITableViewCellStyle cellStyle = UITableViewCellStyleSubtitle;//self.subtitleKey ? UITableViewCellStyleSubtitle : UITableViewCellStyleDefault;
        cell = [[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:ReuseIdentifier];
        cell.textLabel.backgroundColor = [UIColor clearColor];
		//cell.textLabel.textColor = [UIColor lightGrayColor];
        
        //cell.contentView.backgroundColor = [UIColor blackColor];
    }
    if (self.titleKey) cell.textLabel.text = [managedObject valueForKey:self.titleKey];
    if (selectedIndex == indexPath.row) {
        cell.detailTextLabel.textColor = [UIColor darkTextColor];
        cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.detailTextLabel.numberOfLines = 4;
        Website* site = (Website*)managedObject;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"URL: %@\nStatus: %@\nTesting Date: %@", site.url, site.status, [site.lastcheck descriptionWithLocale:[NSLocale currentLocale]]];
    } else {
        cell.detailTextLabel.text = nil;
    }

    UIImage *statusImage = [self statusImageForManagedObject:managedObject];
    if (statusImage) cell.imageView.image = statusImage;//?
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Website *site = (Website *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    NSLog(@"selected site with url %@", site.url);
    
    //The user is selecting the cell which is currently expanded
    //we want to minimize it back
    if(selectedIndex == indexPath.row)
    {
        selectedIndex = -1;
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        return;
    }

    //First we check if a cell is already expanded.
    //If it is we want to minimize make sure it is reloaded to minimize it back
    if(selectedIndex >= 0)
    {
        NSIndexPath *previousPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
        selectedIndex = indexPath.row;
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:previousPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    //Finally set the selected index to the new selection and reload it to expand
    selectedIndex = indexPath.row;
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(selectedIndex == indexPath.row) {
        return 120;
    } else {
        return 40;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma -
#pragma events handler

- (IBAction)refreshBtnTapped:(UIBarButtonItem *)sender {
    
    ICMConnectivityTester* connectivityTester = [ICMConnectivityTester GetInstance];
    for (Website* site in [self.fetchedResultsController fetchedObjects]) {
        [connectivityTester performTestOnWebsite:site];
    }
}


@end
