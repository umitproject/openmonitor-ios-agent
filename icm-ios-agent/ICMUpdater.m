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
            sharedUpdater = [[self alloc] initWithTimeInterval:10*60];
    }
    return (sharedUpdater);
}

+ (void)fireWebsiteTester
{
    [sharedUpdater fireWebsiteTimer];
}

+ (void)fireServiceTester
{
    [sharedUpdater fireServiceTimer];
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
    if (self = [super initWithHostName:nil])
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
    
    updateWebsiteTimer = [NSTimer scheduledTimerWithTimeInterval:self.updateInterval
                                                   target:self
                                                 selector:@selector(onUpdateWebsiteTimer)
                                                 userInfo:nil
                                                  repeats:YES];
    updateServiceTimer = [NSTimer scheduledTimerWithTimeInterval:self.updateInterval
                                                          target:self
                                                        selector:@selector(onUpdateServiceTimer)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)fireWebsiteTimer
{
    [updateWebsiteTimer fire];
}

- (void)fireServiceTimer
{
    [updateServiceTimer fire];
}

- (void)dealloc
{
    [updateWebsiteTimer invalidate];
    [updateServiceTimer invalidate];
    self.aggregatorEngine = nil;
    self.websiteFetchedResultsController = nil;
    self.serviceFetchedResultsController = nil;
}

#pragma mark -
#pragma mark Timer Methods

- (void)onUpdateWebsiteTimer
{
    NSLog(@"onUpdateTimer triggered, update Website now...");
    
    if (![ICMUpdater connected]) {
        NSLog(@"Not connected, canceling...");
        return;
    }
    
    for (ICMWebsite* site in [self.websiteFetchedResultsController fetchedObjects]) {
        NSLog(@"website: %@", site.name);
        [self dispatchRefreshingRequestForWebsite:site];
    }
}

- (void)onUpdateServiceTimer
{
    NSLog(@"onUpdateTimer triggered, update Service now...");
    
    if (![ICMUpdater connected]) {
        NSLog(@"Not connected, canceling...");
        return;
    }
    
    for (ICMService* service in [self.serviceFetchedResultsController fetchedObjects]) {
        NSLog(@"service: %@", service.name);
        [self dispatchRefreshingRequestForService:service];
    }
}

- (void)dispatchRefreshingRequestForWebsite:(ICMWebsite*)site
{
    @synchronized(self.aggregatorEngine)
    {
        MKNetworkOperation *op = [self operationWithURLString:site.url
                                                       params:nil
                                                   httpMethod:@"GET"];
        
        [op onCompletion:^(MKNetworkOperation *operation) {
            DLog(@"[%d]%@", [operation HTTPStatusCode], operation);
            site.status = [NSNumber numberWithInt:[operation HTTPStatusCode]];
            site.lastcheck = [NSDate date];
            [ICMAppDelegate SaveContext];
            [self.aggregatorEngine sendWebsiteReport:site];
        } onError:^(NSError *error) {
            DLog(@"[%d]%@", [op HTTPStatusCode], error);
            site.status = [NSNumber numberWithInt:[op HTTPStatusCode]];
            site.lastcheck = [NSDate date];
            [ICMAppDelegate SaveContext];
            [self.aggregatorEngine sendWebsiteReport:site];
        }];
        
        [self enqueueOperation:op];
    }
}

- (void)dispatchRefreshingRequestForService:(ICMService*)service
{
    @synchronized(self.aggregatorEngine)
    {
        GCDAsyncSocket* socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        socket.userData = service;
        NSError *err = nil;
        [socket connectToHost:service.host onPort:[service.port intValue] withTimeout:20.0 error:&err];
    }
}

#pragma -
#pragma GCDAsyncSocketDelegate methods

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"Cool, I'm connected! That was easy.");
    ICMService* service = (ICMService*)sock.userData;
    service.status = [NSNumber numberWithInt:kStatusNormal];
    service.lastcheck = [NSDate date];
    [ICMAppDelegate SaveContext];
    [self.aggregatorEngine sendServiceReport:service];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"Geez, not connected");
    ICMService* service = (ICMService*)sock.userData;
    service.status = [NSNumber numberWithInt:kStatusDown];
    service.lastcheck = [NSDate date];
    [ICMAppDelegate SaveContext];
    [self.aggregatorEngine sendServiceReport:service];
}

#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)websiteFetchedResultsController {
    // Set up the fetched results controller if needed.
    if (websiteFetchedResultsController == nil) {
        // Create the fetch request for the entity.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ICMWebsite" inManagedObjectContext:managedObjectContext];
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
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ICMService" inManagedObjectContext:managedObjectContext];
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
