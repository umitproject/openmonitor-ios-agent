//
//  ICMService.m
//  icm-ios-agent
//
//  Created by shinysky on 12-8-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMService.h"


@implementation ICMService

@dynamic enabled;
@dynamic host;
@dynamic lastcheck;
@dynamic name;
@dynamic port;
@dynamic status;
@dynamic uid;

-(void) initWithHost:(NSString*)h port:(int)port name:(NSString*)n enabled:(BOOL)e uid:(NSString*)i
{
    self.host = h;
    self.port = [NSNumber numberWithInt:port];
    self.name = n;
    self.enabled = [NSNumber numberWithBool:e];
    self.uid = i;
}

@end
