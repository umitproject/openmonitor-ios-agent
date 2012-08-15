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
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [self performLoginIfRequired];
}

-(void) willEnterForeground: (NSNotification *)notification {
    [self performLoginIfRequired];
}

#pragma mark -
#pragma Preparing Methods

- (void) performLoginIfRequired {
    
    ICMAggregatorEngine* engine = [ICMAggregatorEngine sharedEngine];
    if (![engine isLoggedIn]) {
        
        NSLog(@"Is not logged in");
        
        UIStoryboard *storyboard = [UIApplication sharedApplication].delegate.window.rootViewController.storyboard;
        
        UIViewController *loginController = [storyboard instantiateViewControllerWithIdentifier:@"loginFormNVC"];
        NSLog(@"dest vc: %@", NSStringFromClass([loginController class]));
        [self presentModalViewController:loginController animated:YES];
        //[self performSegueWithIdentifier:@"loginSegue" sender:self];
        
    } else {
        NSLog(@"Is logged in");
        [self performSegueWithIdentifier:@"tabbarSegue" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"dest vc: %@", NSStringFromClass([[segue destinationViewController] class]));
    
	if ([segue.identifier isEqualToString:@"loginSegue"])
	{
        //NSLog(@"Setting ICMFirstVC as a delegate of LoginFormVC");
        UINavigationController *dest = segue.destinationViewController;
        NSArray *viewControllers = [dest viewControllers];
        LoginFormViewController* lfvc = [viewControllers objectAtIndex:0];
        NSLog(@"dest vc: %@", NSStringFromClass([lfvc class]));
        lfvc.delegate = self;
	}
}

#pragma mark -
#pragma mark LoginFormViewControllerDelegate Methods
- (void)logInWithUsername:(NSString *)name password:(NSString*)pass
{
    //[self.navigationController popViewControllerAnimated:YES];
    ICMAggregatorEngine* engine = [ICMAggregatorEngine sharedEngine];
    if (engine.agentId == nil) {
        //FIXME name and pass
        [engine registerAgentWithUsername:name password:name];
    } else {
        [engine loginStep1];
    }
}

@end
