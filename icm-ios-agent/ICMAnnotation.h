//
//  ICMAnnotation.h
//  icm-ios-agent
//
//  Created by shinysky on 12-6-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface ICMAnnotation : NSObject <MKAnnotation>
{
    NSString *_name;
    NSString *_address;
    CLLocationCoordinate2D _coordinate;
}

@property (copy) NSString *name;
@property (copy) NSString *address;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate;

@end
