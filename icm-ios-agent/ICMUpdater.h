//
//  ICMUpdater.h
//  icm-ios-agent
//
//  Created by shinysky on 12-6-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import "GCDAsyncSocket.h"
#import "ICMAggregatorEngine.h"
#import "OMWebsite.h"
#import "OMService.h"

@interface ICMUpdater : MKNetworkEngine <GCDAsyncSocketDelegate>
{
    NSTimer *updateWebsiteTimer;
    NSTimer *updateServiceTimer;
    NSTimeInterval updateInterval;
    
    ICMAggregatorEngine *aggregatorEngine;
    
    NSFetchedResultsController *websiteFetchedResultsController;
    NSFetchedResultsController *serviceFetchedResultsController;
    
    NSManagedObjectContext *managedObjectContext;
    
    //NSOperationQueue *nsqueue;
}

@property (nonatomic) NSTimeInterval updateInterval;
@property (nonatomic, retain) ICMAggregatorEngine *aggregatorEngine;
@property (nonatomic, retain) NSFetchedResultsController *websiteFetchedResultsController;
@property (nonatomic, retain) NSFetchedResultsController *serviceFetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
//@property (nonatomic, retain) NSOperationQueue *nsqueue;

+ (ICMUpdater *)sharedUpdater;
+ (void)fireWebsiteTester;
+ (void)fireServiceTester;
+ (BOOL)connected;

- (ICMUpdater *) initWithTimeInterval:(NSTimeInterval)interval;
- (void)startTimers;
- (void)fireWebsiteTimer;
- (void)fireServiceTimer;

- (void)upsertWebsiteWithUrl:(NSString*)url name:(NSString*)name uid:(NSString*)uid;
- (void)upsertServiceWithHost:(NSString*)host port:(int)port name:(NSString*)name uid:(NSString*)uid;

@end
