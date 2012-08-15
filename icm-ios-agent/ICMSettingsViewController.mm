//
//  ICMSettingsViewController.m
//  icm-ios-agent
//
//  Created by shinysky on 12-5-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMSettingsViewController.h"
#import "ICMUpdater.h"
#import "ICMService.h"

#include <stdlib.h>
#include <iostream>
#include <fstream>

// include libevent's header
#include <event.h>

// include libcage's header
#include "cage.hpp"

extern "C" {
#include "Base64Transcoder.h"
}


const int max_node = 10;
const int port     = 10000;
libcage::cage *cage;

class join_callback
{
public:
    int n;
    
    void operator() (bool result)
    {
        // print state
        if (result)
            std::cout << "join: succeeded, n = "
            << n
            << std::endl;
        else
            std::cout << "join: failed, n = "
            << n
            << std::endl;
        
        cage[n].print_state();
        n++;
        
        if (n < max_node) {
            // start nodes recursively
            if (! cage[n].open(PF_INET, port + n)) {
                std::cerr << "cannot open port: Port = "
                << port + n
                << std::endl;
                return;
            }
            
            cage[n].set_global();
            cage[n].join("localhost", 10000, *this);
        }
    }
};


void
timer_callback(int fd, short ev, void *arg)
{
    timeval tval;
    
    tval.tv_sec  = 60;
    tval.tv_usec = 0;
    
    evtimer_add((event*)arg, &tval);
    
    for (int i = 0; i < max_node; i++) {
        cage[i].print_state();
    }
}

int start_node()
{
    // initialize libevent
    event_init();
    
    cage = new libcage::cage[max_node];
    
    // start bootstrap node
    if (! cage[0].open(PF_INET, port)) {
        std::cerr << "cannot open port: Port = "
        << port
        << std::endl;
        return -1;
    }
    cage[0].set_global();
    
    
    // start other nodes
    join_callback func;
    func.n = 1;
    
    if (! cage[1].open(PF_INET, port + func.n)) {
        std::cerr << "cannot open port: Port = "
        << port + func.n
        << std::endl;
        return -1;
    }
    cage[1].set_global();
    cage[1].join("localhost", 10000, func);
    
    
    // start timer
    timeval tval;
    event  *ev = new event;
    
    tval.tv_sec  = 60;
    tval.tv_usec = 0;
    
    evtimer_set(ev, timer_callback, ev);
    evtimer_add(ev, &tval);
    
    
    // handle event loop
    event_dispatch();
    
    return 0;
}

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
    loginBtn = nil;
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
