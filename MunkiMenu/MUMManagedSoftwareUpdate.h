//
//  MUMManagedSoftwareUpdate.h
//  MunkiMenu
//
//  Created by Eldon on 4/10/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Wraper for /usr/local/munki/managedsoftwareupdate.
 *  @discussion to actually perform a run, this class needs to run as root, so put #define __RUN_AS_ROOT__ in the helper tool's .pch file 
 */
@interface MUMManagedSoftwareUpdate : NSObject

#ifdef __RUN_AS_ROOT__
/**
 *  NSTask Wrapper to Run managedsoftwareupdate
 *
 *  @param args  Arguments normally passed to managedsoftwareupdate
 *  @param reply block argument that takes 2 values Array of run errors represented as strings, and an NSError populated with an execution error generated from a managedsoftwareupdate run. 
 */
+(void)runWithArgs:(NSArray *)args reply:(void (^)(NSArray *runErrors, NSError *execError))reply;
#endif

/**
 *  Get the current version of managedsoftwareupdate
 *
 *  @return Current Version string
 */
+(NSString*)version;

/**
 *  Get the majorVersion of managedsoftwareupdate, i.e. 0.9.8 is 0, 1.1 is 1, and 2.0 is 2
 *
 *  @return majorVerson
 */
+(NSInteger)majorVerson;

/**
 *  Determine if an instance of managedsoftwareupdat is currently running
 *
 *  @return YES if instance is running, NO if no
 */
+(BOOL)instanceIsRunning;
@end
