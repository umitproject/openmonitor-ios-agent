//
//  ICMUpdater.h
//  icm-ios-agent
//
//  Created by shinysky on 12-6-16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import "ICMAggregatorEngine.h"
#import "Website.h"
#import "Service.h"

@interface ICMUpdater : NSObject
{
    NSTimer *updateTimer;
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
+ (void)fireUpdater;
+ (BOOL)connected;

- (ICMUpdater *) initWithTimeInterval:(NSTimeInterval)interval;
- (void)startTimers;
- (void)fireTimers;

@end
