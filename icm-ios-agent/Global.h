//
//  Global.h
//  iOSKuapay
//
//  Created by Patrick Hogan on 11/29/11.
//  Copyright (c) 2011 Kuapay LLC. All rights reserved.
//

#ifdef DEBUG
#   define DLog(fmt, ...) QuietLog((@"%s [Line %d]\n" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

#define ALog(fmt, ...) QuietLog((@"%s [Line %d]\n" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#ifdef DEBUG
#   define ULog(fmt, ...)  { UIAlertView *alertU = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%s\n [Line %d]", __PRETTY_FUNCTION__, __LINE__] message:[NSString stringWithFormat:fmt, ##__VA_ARGS__]  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease]; [alertU show]; }
#else
#   define ULog(...)
#endif


void QuietLog (NSString *format, ...);