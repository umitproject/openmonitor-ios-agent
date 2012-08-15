//
//  ICMWebsite.m
//  icm-ios-agent
//
//  Created by shinysky on 12-8-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMWebsite.h"


@implementation ICMWebsite

@dynamic enabled;
@dynamic lastcheck;
@dynamic name;
@dynamic status;
@dynamic uid;
@dynamic url;

-(void) initWithUrl:(NSString*)u name:(NSString*)n enabled:(BOOL)e uid:(NSString*)i
{
    self.url = u;
    self.name = n;
    self.enabled = [NSNumber numberWithBool:e];
    self.uid = i;
    
    self.lastcheck = nil;
    self.status = [NSNumber numberWithInt:-1];
}

@end
