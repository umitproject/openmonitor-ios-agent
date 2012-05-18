//
//  ICMFirstViewController.m
//  icm-ios-agent
//
//  Created by shinysky on 12-5-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMFirstViewController.h"


#include <stdlib.h>
#include <iostream>

// include libevent's header
#include <event.h>

// include libcage's header
#include "cage.hpp"

libcage::cage *cage;

// initialize libevent
struct event_base * eb = event_base_new();

void join_callback(bool result)
{
    if (result)
        std::cout << "join: succeeded" << std::endl;
    else
        std::cout << "join: failed" << std::endl;
    
    cage->print_state();
}


int start_node(int port, int join_port)
{
    std::cout << "starting node at port: " << port << std::endl;
    
    
    // create cage instance after initialize
    cage = new libcage::cage;
    
    // open UDP
    if (! cage->open(PF_INET, port)) {
        std::cerr << "cannot open port: Port = "
        << port
        << std::endl;
        return -1;
    }
    
    // set as global node
    cage->set_global();
    
    if (join_port > 0) {
        // join to the network
        cage->join("localhost", join_port, &join_callback);
    }
    
    // handle event loop
    event_base_dispatch(eb);
    
    return 0;
}

@interface ICMFirstViewController ()

@end

@implementation ICMFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    first_port = cur_port = 10000;
    backgroundQueue = dispatch_queue_create("com.razeware.imagegrabber.bgqueue", NULL); 
}

- (void)viewDidUnload
{
    startBtn = nil;
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

- (IBAction)startBtnTapped:(id)sender {
    if ([firstNodeSwitch isOn]) {
        [firstNodeSwitch setOn:false];
        dispatch_async(backgroundQueue, ^(void) {
            start_node(first_port, 0);
        });
    } else {
        dispatch_async(backgroundQueue, ^(void) {
            start_node(cur_port, first_port);
        });
    }
    cur_port++;
}
@end
