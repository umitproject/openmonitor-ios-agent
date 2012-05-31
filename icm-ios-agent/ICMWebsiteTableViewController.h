//
//  ICMWebsiteTableViewController.h
//  icm-ios-agent
//
//  Created by shinysky on 11-2-5.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

#import "CoreDataTableViewController.h"

@interface ICMWebsiteTableViewController : CoreDataTableViewController {

    __weak IBOutlet UIBarButtonItem *refreshBtn;

@private
    NSManagedObjectContext *managedObjectContext;
    //This is the index of the cell which will be expanded
    NSInteger selectedIndex;
    
    MKNetworkEngine *networkEngine;
    NSMutableDictionary *imageDownloadsInProgress;  // the set of IconDownloader objects for each app
    NSMutableDictionary *imageCache;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSMutableDictionary *imageDownloadsInProgress;
@property (nonatomic, retain) NSMutableDictionary *imageCache;

- (void)performFetchAndReload;
- (IBAction)refreshBtnTapped:(UIBarButtonItem *)sender;

@end
