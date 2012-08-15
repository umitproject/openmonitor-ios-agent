//
//  ICMRootViewController.m
//  icm-ios-agent
//
//  Created by shinysky on 12-8-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMRootViewController.h"
#import "ICMAggregatorEngine.h"

@implementation ICMRootViewController

-(void)viewDidLoad {
    engine = [ICMAggregatorEngine sharedEngine];
    engine.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self performLoginIfRequired];
}

-(void) willEnterForeground: (NSNotification *)notification {
    [self performLoginIfRequired];
}

#pragma mark -
#pragma Preparing Methods

- (void) performLoginIfRequired {
    
    if (![engine isLoggedIn]) {
        NSLog(@"Not logged in");
        UIStoryboard *storyboard = [UIApplication sharedApplication].delegate.window.rootViewController.storyboard;
        UINavigationController *loginNVC = [storyboard instantiateViewControllerWithIdentifier:@"loginNVC"];
        NSArray *viewControllers = [loginNVC viewControllers];
        LoginFormViewController* lfvc = [viewControllers objectAtIndex:0];
        NSLog(@"dest vc: %@", NSStringFromClass([lfvc class]));
        lfvc.delegate = self;
        [self presentModalViewController:loginNVC animated:YES];
    } else {
        NSLog(@"Already logged in");
    }
}

#pragma mark -
#pragma mark LoginFormViewControllerDelegate Methods
- (void)logInWithUsername:(NSString *)name password:(NSString*)pass
{
    engine.delegate = self;
    if (engine.agentId == nil) {
        //FIXME name and pass
        [engine registerAgentWithUsername:name password:name];
    } else {
        [engine loginStep1];
    }
}

#pragma mark -
#pragma mark ICMAggregatorEngineDelegate Methods
- (void)agentLoggedInWithError:(NSError*)error
{
    if (error != nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" 
                                                        message:error.localizedDescription
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)agentLoggedOutWithError:(NSError*)error
{
    if (error != nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logout Failed" 
                                                        message:error.localizedDescription
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        [self performLoginIfRequired];
    }
}

@end
