//
//  Exception.h
//  iOSKuapay
//
//  Created by Patrick Hogan on 12/2/11.
//  Copyright (c) 2011 Kuapay LLC. All rights reserved.
//

typedef enum 
{
 FAILURE
} ExceptionType;


@interface Exception : NSObject

+(void)raise:(ExceptionType)exceptionType function:(const char *)function line:(NSInteger)line description:(NSString *)description;

+(NSString *)formatExceptionTypeToString:(ExceptionType)exceptionType;

@end
