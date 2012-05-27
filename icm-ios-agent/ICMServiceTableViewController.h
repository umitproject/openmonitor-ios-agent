//
//  ICMServiceTableViewController.h
//  icm-ios-agent
//
//  Created by shinysky on 12-5-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

#import "CoreDataTableViewController.h"

@interface ICMServiceTableViewController : CoreDataTableViewController {
    
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
