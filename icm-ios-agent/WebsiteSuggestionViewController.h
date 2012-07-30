//
//  WebsiteSuggestionViewController.h
//  icm-ios-agent
//
//  Created by shinysky on 12-7-18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WebsiteSuggestionViewControllerDelegate;

@interface WebsiteSuggestionViewController : UITableViewController {
    __weak id<WebsiteSuggestionViewControllerDelegate> delegate;
    
    UITextField *nameTF;
    UITextField *urlTF;
}

@property (weak) id <WebsiteSuggestionViewControllerDelegate> delegate;

- (IBAction)doneBtnPressed:(id)sender;
- (IBAction)cancelBtnPressed:(id)sender;

@end

@protocol WebsiteSuggestionViewControllerDelegate 

- (void)suggestWebsiteWithName:(NSString*)name Url:(NSString*)url;
- (void)cancel;

@end