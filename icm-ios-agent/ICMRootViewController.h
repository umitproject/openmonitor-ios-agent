//
//  ICMRootViewController.h
//  icm-ios-agent
//
//  Created by shinysky on 12-8-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginFormViewController.h"

@interface ICMRootViewController : UITabBarController <LoginFormViewControllerDelegate, ICMAggregatorEngineDelegate>
{
    ICMAggregatorEngine* engine;
}

@end
