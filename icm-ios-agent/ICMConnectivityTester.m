//
//  ICMConnectivityTester.m
//  icm-ios-agent
//
//  Created by shinysky on 12-5-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMConnectivityTester.h"


@implementation ICMConnectivityTester

static ICMConnectivityTester * connectivityTester = nil;                                                

+ (ICMConnectivityTester *)GetInstance
{
    @synchronized(self)
    {
        if (connectivityTester == nil)
            connectivityTester = [[self alloc] initWithHostName:nil];
    }
    return (connectivityTester);
}

- (void)performTestOnWebsite:(Website*) site {
    
    MKNetworkOperation *op = [self operationWithURLString:site.url
                                                   params:nil
                                               httpMethod:@"GET"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        DLog(@"[%d]%@", [operation HTTPStatusCode], operation);
        site.status = [NSNumber numberWithInt:[operation HTTPStatusCode]];
        site.lastcheck = [NSDate date];
        [ICMAppDelegate SaveContext];
    } onError:^(NSError *error) {
        DLog(@"[%d]%@", [op HTTPStatusCode], error);
        site.status = [NSNumber numberWithInt:[op HTTPStatusCode]];
        site.lastcheck = [NSDate date];
        [ICMAppDelegate SaveContext];
    }];
    
    [self enqueueOperation:op];
}

@end
