//
//  ICMConnectivityTester.h
//  icm-ios-agent
//
//  Created by shinysky on 12-5-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Website.h"

@interface ICMConnectivityTester : MKNetworkEngine

+ (ICMConnectivityTester *)GetInstance;

- (void)performTestOnWebsite:(Website*) site;

@end
