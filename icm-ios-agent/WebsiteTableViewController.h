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

    __weak IBOutlet UIBarButtonItem *refreshBtn;

@private
    NSManagedObjectContext *managedObjectContext;
    //This is the index of the cell which will be expanded
    NSInteger selectedIndex;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (void)performFetchAndReload;
- (IBAction)refreshBtnTapped:(UIBarButtonItem *)sender;

@end
