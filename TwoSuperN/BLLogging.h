//
//  BLLogging.h
//  TwoSuperN
//
//  Created by Ben La Monica on 5/3/14.
//  Copyright (c) 2014 Ben La Monica. All rights reserved.
//

#ifndef TwoSuperN_BLLogging_h
#define TwoSuperN_BLLogging_h

#define DBG_LVL 1

#define LDBUG(str,n...) if(DBG_LVL <= 1) NSLog([NSString stringWithFormat:@"[DBUG] %@", str],n)
#define LINFO(str,n...) if(DBG_LVL <= 2) NSLog([NSString stringWithFormat:@"[INFO] %@", str],n)
#define LWARN(str,n...) if(DBG_LVL <= 3) NSLog([NSString stringWithFormat:@"[WARN] %@", str],n)
#define LCRIT(str,n...) if(DBG_LVL <= 4) NSLog([NSString stringWithFormat:@"[CRIT] %@", str],n)

#define DBUG_ENABLED (DBG_LVL <= 1)
#define INFO_ENABLED (DBG_LVL <= 2)
#define WARN_ENABLED (DBG_LVL <= 3)
#define CRIT_ENABLED (DBG_LVL <= 4)

#ifndef bl_dispatch_after
#define bl_dispatch_after(delayInSeconds, block) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), block)
#endif


/*
 *  System Versioning Preprocessor Macros
 */

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#endif
