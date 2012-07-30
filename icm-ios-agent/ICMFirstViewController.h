//
//  ICMFirstViewController.h
//  icm-ios-agent
//
//  Created by shinysky on 12-5-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>
#import "LoginFormViewController.h"
#import "WebsiteSuggestionViewController.h"
#import "ServiceSuggestionViewController.h"

@interface ICMFirstViewController : UIViewController <LoginFormViewControllerDelegate, WebsiteSuggestionViewControllerDelegate, ServiceSuggestionViewControllerDelegate> {
    __weak IBOutlet UIButton *startBtn;
    __weak IBOutlet UIButton *loginBtn;
    __weak IBOutlet UISwitch *firstNodeSwitch;
    __weak IBOutlet UILabel *statusLabel;
    
    dispatch_queue_t backgroundQueue;
    
    int first_port;
    int cur_port;
}

- (IBAction)startBtnTapped:(id)sender;


@end
