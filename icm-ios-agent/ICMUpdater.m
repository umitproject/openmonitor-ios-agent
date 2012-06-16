//
//  ICMUpdater.m
//  icm-ios-agent
//
//  Created by shinysky on 12-6-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMUpdater.h"

@implementation ICMUpdater

@synthesize updateInterval, aggregatorEngine;
@synthesize websiteFetchedResultsController, serviceFetchedResultsController;
@synthesize managedObjectContext;

static ICMUpdater * sharedUpdater = nil;                                                

+ (ICMUpdater *)sharedUpdater
{
    @synchronized(self)
    {
        if (sharedUpdater == nil)
            sharedUpdater = [[self alloc] initWithTimeInterval:60];
    }
    return (sharedUpdater);
}

+ (void)fireUpdater
{
    [sharedUpdater fireTimers];
}

+ (BOOL)connected 
{
	//return NO; // force for offline testing
	Reachability *hostReach = [Reachability reachabilityForInternetConnection];	
	NetworkStatus netStatus = [hostReach currentReachabilityStatus];	
	return !(netStatus == NotReachable);
}

-(ICMAggregatorEngine *)aggregatorEngine
{
	if(!aggregatorEngine)
	{
        aggregatorEngine = [ICMAggregatorEngine sharedEngine];
	}
	return aggregatorEngine;
}

-(ICMUpdater*)initWithTimeInterval:(NSTimeInterval)interval
{
    if (self = [super init])
	{
        self.updateInterval = interval;
	}
	return self;
}

- (void)refetchData
{
    self.websiteFetchedResultsController = nil;
    self.serviceFetchedResultsController = nil;
    NSError *error = nil;
    if (![[self websiteFetchedResultsController] performFetch:&error]
        || ![[self serviceFetchedResultsController] performFetch:&error]
        //|| ![[self pageFetchedResultsController] performFetch:&error]
        ) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		//abort();
	}
}

-(void) startTimers
{
    [self refetchData];
    
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:self.updateInterval
                                                   target:self
                                                 selector:@selector(onUpdateTimer)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void)fireTimers
{
    [updateTimer fire];
}

- (void)dealloc
{
    [updateTimer invalidate];
    self.aggregatorEngine = nil;
    self.websiteFetchedResultsController = nil;
    self.serviceFetchedResultsController = nil;
}

#pragma mark -
#pragma mark Timer Methods

- (void)onUpdateTimer
{
    NSLog(@"onUpdateTimer triggered, update timeline now...");
    
    if (![ICMUpdater connected]) {
        NSLog(@"Not connected, canceling...");
        return;
    }
    
    for (Website* site in [self.websiteFetchedResultsController fetchedObjects]) {
        NSLog(@"website: %@", site.name);
        [self dispatchRefreshingRequestForWebsite:site];
    }
    
    for (Service* service in [self.serviceFetchedResultsController fetchedObjects]) {
        NSLog(@"service: %@", service.name);
        [self dispatchRefreshingRequestForService:service];
    }
}

- (void)dispatchRefreshingRequestForWebsite:(Website*)site
{
    @synchronized(self.aggregatorEngine)
    {
        [self.aggregatorEngine sendWebsiteReport];
    }
}

- (void)dispatchRefreshingRequestForService:(Service*)service
{
    @synchronized(self.aggregatorEngine)
    {
        [self.aggregatorEngine sendServiceReport];
    }
}

#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)websiteFetchedResultsController {
    // Set up the fetched results controller if needed.
    if (websiteFetchedResultsController == nil) {
        // Create the fetch request for the entity.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Website" inManagedObjectContext:managedObjectContext];
        [fetchRequest setEntity:entity];
        
        // Edit the sort key as appropriate.
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        
        [fetchRequest setSortDescriptors:sortDescriptors];
        fetchRequest.fetchBatchSize = 20;
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        [NSFetchedResultsController deleteCacheWithName:@"Websites"];
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                    managedObjectContext:managedObjectContext
                                                                                                      sectionNameKeyPath:nil//@"owner"
                                                                                                               cacheName:@"Websites"];
        //aFetchedResultsController.delegate = self;
        websiteFetchedResultsController = aFetchedResultsController;
        
        aFetchedResultsController = nil;
        fetchRequest = nil;
        sortDescriptor = nil;
        sortDescriptors = nil;
    }
	
	return websiteFetchedResultsController;
}

- (NSFetchedResultsController *)serviceFetchedResultsController {
    // Set up the fetched results controller if needed.
    if (serviceFetchedResultsController == nil) {
        // Create the fetch request for the entity.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Service" inManagedObjectContext:managedObjectContext];
        [fetchRequest setEntity:entity];
        
        // Edit the sort key as appropriate.
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        
        [fetchRequest setSortDescriptors:sortDescriptors];
        fetchRequest.fetchBatchSize = 20;
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        [NSFetchedResultsController deleteCacheWithName:@"Services"];
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                    managedObjectContext:managedObjectContext
                                                                                                      sectionNameKeyPath:nil//@"owner"
                                                                                                               cacheName:@"Services"];
        //aFetchedResultsController.delegate = self;
        serviceFetchedResultsController = aFetchedResultsController;
        
        aFetchedResultsController = nil;
        fetchRequest = nil;
        sortDescriptor = nil;
        sortDescriptors = nil;
    }
	
	return serviceFetchedResultsController;
}

@end
