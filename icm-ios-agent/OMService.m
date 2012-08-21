//
//  OMService.m
//  icm-ios-agent
//
//  Created by shinysky on 12-8-21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "OMService.h"


@implementation OMService

@dynamic uid;
@dynamic status;
@dynamic port;
@dynamic name;
@dynamic lastcheck;
@dynamic host;
@dynamic enabled;

-(void) initWithHost:(NSString*)h port:(int)port name:(NSString*)n enabled:(BOOL)e uid:(NSString*)i
{
    self.host = h;
    self.port = [NSNumber numberWithInt:port];
    self.name = n;
    self.enabled = [NSNumber numberWithBool:e];
    self.uid = i;
}

@end
