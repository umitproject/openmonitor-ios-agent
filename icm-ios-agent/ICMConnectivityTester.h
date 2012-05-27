//
//  ICMConnectivityTester.h
//  icm-ios-agent
//
//  Created by shinysky on 12-5-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Website.h"
#import "Service.h"
#import "GCDAsyncSocket.h"

@interface ICMConnectivityTester : MKNetworkEngine <GCDAsyncSocketDelegate>

+ (ICMConnectivityTester *)GetInstance;

- (void)performTestOnWebsite:(Website*) site;
- (void)performTestOnService:(Service*) service;

@end
