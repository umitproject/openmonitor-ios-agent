//
//  ICMSettingsViewController.m
//  icm-ios-agent
//
//  Created by shinysky on 12-5-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMSettingsViewController.h"
#import "ICMUpdater.h"
#import "OMService.h"

@interface ICMSettingsViewController ()

@end

@implementation ICMSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    first_port = cur_port = 10000;
    backgroundQueue = dispatch_queue_create("org.umitproject.icm.bgqueue", NULL);
    engine = [ICMAggregatorEngine sharedEngine];
}

- (void)viewDidUnload
{
    startBtn = nil;
    logoutBtn = nil;
    firstNodeSwitch = nil;
    statusLabel = nil;
    dispatch_release(backgroundQueue);
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"websitesuggest"])
	{
        //NSLog(@"Setting ICMFirstVC as a delegate of LoginFormVC");
        WebsiteSuggestionViewController *lfvc = segue.destinationViewController;
        lfvc.delegate = self;
	}
    else if ([segue.identifier isEqualToString:@"servicesuggest"])
	{
        //NSLog(@"Setting ICMFirstVC as a delegate of LoginFormVC");
        ServiceSuggestionViewController *lfvc = segue.destinationViewController;
        lfvc.delegate = self;
	}
}

- (IBAction)startBtnTapped:(id)sender {
    /*
    dispatch_async(backgroundQueue, ^(void) {
        start_node();
    });
    
    GOOGLE_PROTOBUF_VERIFY_VERSION; */
    
    //if (engine.agentId == nil)
    //    [engine registerAgentWithUsername:@"test" password:@"test"];
    //[self logInWithUsername:@"test" password:@"test"];
    //fuck yeah!
    //[engine getEvents];
    //[engine sendWebsiteReport];
    //[engine sendServiceReport];
    [engine checkNewTests];
}

- (IBAction)logoutBtnTapped:(id)sender
{
    [engine logoutAgent];
}

#pragma mark -
#pragma mark WebsiteSuggestionViewControllerDelegate Methods

- (void)suggestWebsiteWithName:(NSString*)name url:(NSString*)url
{
    [self.navigationController popViewControllerAnimated:YES];
    [engine suggestWebsiteWithName:name url:url];
}
- (void)cancel
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark ServiceSuggestionViewControllerDelegate Methods

- (void)suggestServiceWithName:(NSString*)name host:(NSString*)host ip:(NSString*)ip port:(int)port
{
    [self.navigationController popViewControllerAnimated:YES];
    [engine suggestServiceWithName:name host:host ip:ip port:port];
}
/*
- (void)cancel
{
    [self.navigationController popViewControllerAnimated:YES];
}*/

@end
