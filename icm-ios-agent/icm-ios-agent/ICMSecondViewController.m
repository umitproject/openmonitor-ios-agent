//
//  ICMSecondViewController.m
//  icm-ios-agent
//
//  Created by shinysky on 12-5-3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMSecondViewController.h"

@interface ICMSecondViewController ()

@end

@implementation ICMSecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    putKeyTF = nil;
    putValueTF = nil;
    putResultLabel = nil;
    putKVBtn = nil;
    getKeyTF = nil;
    getValueTF = nil;
    getKVBtn = nil;
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

- (IBAction)putKVBtnTapped:(id)sender {
}

- (IBAction)getKVBtnTapped:(id)sender {
}
@end
