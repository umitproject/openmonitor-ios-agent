//
//  ICMAnnotation.m
//  icm-ios-agent
//
//  Created by shinysky on 12-6-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMAnnotation.h"

@implementation ICMAnnotation

@synthesize name = _name;
@synthesize address = _address;
@synthesize coordinate = _coordinate;

- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate {
    if ((self = [super init])) {
        _name = [name copy];
        _address = [address copy];
        _coordinate = coordinate;
    }
    return self;
}

- (NSString *)title {
    if ([_name isKindOfClass:[NSNull class]]) 
        return @"Unknown Event";
    else
        return _name;
}

- (NSString *)subtitle {
    return _address;
}

@end
