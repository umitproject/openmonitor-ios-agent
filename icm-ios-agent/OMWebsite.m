//
//  OMWebsite.m
//  icm-ios-agent
//
//  Created by shinysky on 12-8-21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "OMWebsite.h"


@implementation OMWebsite

@dynamic url;
@dynamic uid;
@dynamic status;
@dynamic name;
@dynamic lastcheck;
@dynamic enabled;

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
