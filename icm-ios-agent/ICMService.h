//
//  ICMService.h
//  icm-ios-agent
//
//  Created by shinysky on 12-8-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ICMService : NSManagedObject

@property (nonatomic, retain) NSNumber * enabled;
@property (nonatomic, retain) NSString * host;
@property (nonatomic, retain) NSDate * lastcheck;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * port;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSString * uid;

-(void) initWithHost:(NSString*)h port:(int)port name:(NSString*)n enabled:(BOOL)e uid:(NSString*)i;

@end
