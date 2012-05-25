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

@implementation WebsiteTableViewController

@synthesize managedObjectContext;


-(id)initWithCoder:(NSCoder *)aDecoder {
    
    if ((self = [super initWithCoder:aDecoder])) {
        self.managedObjectContext = [ICMAppDelegate GetContext];;
		self.titleKey = @"name";
		self.subtitleKey = nil;
		//self.searchKey = nil;//@"text";
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Website";
    [self performFetchAndReload];
}

- (void)viewDidUnload {

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
        [site initWithUrl:@"http://www.flickr.com" name:@"flickr" enabled:true uid:1010];
        site = [NSEntityDescription insertNewObjectForEntityForName:@"Website"
                                             inManagedObjectContext:managedObjectContext];
        [site initWithUrl:@"http://www.hotmail.com" name:@"Hotmail" enabled:true uid:1011];
        
        [ICMAppDelegate SaveContext];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//[self managedObjectSelected:[[self fetchedResultsControllerForTableView:tableView] objectAtIndexPath:indexPath]];
    Website *site = (Website *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    NSLog(@"selected site with url %@", site.url);
}
/*
- (void)managedObjectSelected:(NSManagedObject *)managedObject
{
	Website *site = (Website *)managedObject;
}*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

@end
