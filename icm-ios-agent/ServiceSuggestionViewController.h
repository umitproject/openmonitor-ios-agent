//
//  ServiceSuggestionViewController.h
//  icm-ios-agent
//
//  Created by shinysky on 12-7-18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ServiceSuggestionViewControllerDelegate;

@interface ServiceSuggestionViewController : UITableViewController {
    __weak id<ServiceSuggestionViewControllerDelegate> delegate;
    
    UITextField *urlTF;
    UITextField *passwordTF;
}

@property (weak) id <ServiceSuggestionViewControllerDelegate> delegate;

- (IBAction)doneBtnPressed:(id)sender;
- (IBAction)cancelBtnPressed:(id)sender;

@end

@protocol ServiceSuggestionViewControllerDelegate 

- (void)suggestServiceWithUrl:(NSString*)url;
- (void)cancel;

@end