//
//  Website.m
//  icm-ios-agent
//
//  Created by shinysky on 12-5-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMWebsite.h"


@implementation ICMWebsite

@dynamic url;
@dynamic enabled;
@dynamic lastcheck;
@dynamic name;
@dynamic status;
@dynamic uid;

-(void) initWithUrl:(NSString*)u name:(NSString*)n enabled:(BOOL)e uid:(int)i
{
    self.url = u;
    self.name = n;
    self.enabled = [NSNumber numberWithBool:e];
    self.uid = [NSNumber numberWithInt:i];
    
    self.lastcheck = nil;
    self.status = [NSNumber numberWithInt:-1];
}

@end
