//
//  Global.m
//  iOSKuapay
//
//  Created by Patrick Hogan on 11/29/11.
//  Copyright (c) 2011 Kuapay LLC. All rights reserved.
//

#import "Global.h"


void QuietLog (NSString *format, ...)
{
 if (format == nil) 
 {
  printf("nil\n");
  return;
 }
 
 va_list argList;
 va_start(argList, format);
 
 NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
 [timeFormat setDateFormat:@"HH:mm:ss:SSS"];
  
 NSString *s = [[NSString alloc] initWithFormat:format arguments:argList];
 printf("%s %s\n\n\n",  [[timeFormat stringFromDate:[NSDate date]] UTF8String], [[s stringByReplacingOccurrencesOfString:@"%%" withString:@"%%%%"] UTF8String]);
 [timeFormat release];
 [s release];
 
 va_end(argList);
}