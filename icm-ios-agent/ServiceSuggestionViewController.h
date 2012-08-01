//
//  ServiceSuggestionViewController.h
//  icm-ios-agent
//
//  Created by shinysky on 12-7-18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ServiceSuggestionViewControllerDelegate;

/*
message ServiceSuggestion {
	required string serviceName = 1;
	required string hostName = 2;
	required string ip = 3;
	required int64 port = 4;
}*/

@interface ServiceSuggestionViewController : UITableViewController {
    __weak id<ServiceSuggestionViewControllerDelegate> delegate;
    
    UITextField *nameTF;
    UITextField *hostTF;
    UITextField *ipTF;
    UITextField *portTF;
}

@property (weak) id <ServiceSuggestionViewControllerDelegate> delegate;

- (IBAction)doneBtnPressed:(id)sender;
- (IBAction)cancelBtnPressed:(id)sender;

@end

@protocol ServiceSuggestionViewControllerDelegate 

- (void)suggestServiceWithName:(NSString*)name host:(NSString*)host ip:(NSString*)ip port:(int)port;
- (void)cancel;

@end