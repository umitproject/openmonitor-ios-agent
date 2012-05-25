//
//  PageTableViewController.h
//  MageReader
//
//  Created by shinysky on 11-2-5.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

#import "CoreDataTableViewController.h"

@interface WebsiteTableViewController : CoreDataTableViewController {

@private
    NSManagedObjectContext *managedObjectContext;
}

- (void)performFetchAndReload;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end
