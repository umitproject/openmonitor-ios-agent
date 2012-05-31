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

- (void)performTestOnService:(Service*) service {
    GCDAsyncSocket* socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    socket.userData = service;
    NSError *err = nil;
    [socket connectToHost:service.host onPort:[service.port intValue] withTimeout:20.0 error:&err];
}

#pragma -
#pragma GCDAsyncSocketDelegate methods

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"Cool, I'm connected! That was easy.");
    Service* service = (Service*)sock.userData;
    service.status = [NSNumber numberWithInt:1];//TODO status enum
    service.lastcheck = [NSDate date];
    [ICMAppDelegate SaveContext];
}

@end
