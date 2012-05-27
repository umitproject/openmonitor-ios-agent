//
//  Service.m
//  icm-ios-agent
//
//  Created by shinysky on 12-5-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "Service.h"


@implementation Service

@dynamic name;
@dynamic port;
@dynamic status;
@dynamic host;
@dynamic enabled;
@dynamic uid;
@dynamic lastcheck;

-(void) initWithHost:(NSString*)h port:(int)port name:(NSString*)n enabled:(BOOL)e uid:(int)i
{
    self.host = h;
    self.port = [NSNumber numberWithInt:port];
    self.name = n;
    self.enabled = [NSNumber numberWithBool:e];
    self.uid = [NSNumber numberWithInt:i];
}
@end
