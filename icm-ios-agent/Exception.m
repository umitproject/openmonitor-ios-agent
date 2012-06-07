//
//  Exception.m
//  iOSKuapay
//
//  Created by Patrick Hogan on 12/2/11.
//  Copyright (c) 2011 Kuapay LLC. All rights reserved.
//

#import "Global.h"
#import "Exception.h"


@interface Exception ()

+(NSString *)formatExceptionTypeToString:(ExceptionType)exceptionType;

@end


@implementation Exception


+(void)raise:(ExceptionType)exceptionType function:(const char *)function line:(NSInteger)line description:(NSString *)description
{
 [NSException raise:[Exception formatExceptionTypeToString:exceptionType] format:[NSString stringWithFormat:@"\nException raised:\n%s [Line %d]\n%@", function, line, description]];
}


+(NSString *)formatExceptionTypeToString:(ExceptionType)exceptionType 
{
 NSString *result;
 
 switch(exceptionType) 
 {
  case FAILURE:
   result = @"userDataCorrupted";
   break;
   break;
  default:
   [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Unexpected ExceptionType."];
 }
 
 return result;
}


@end
