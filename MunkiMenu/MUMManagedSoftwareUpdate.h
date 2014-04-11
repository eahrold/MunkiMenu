//
//  MUMManagedSoftwareUpdate.h
//  MunkiMenu
//
//  Created by Eldon on 4/10/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MUMManagedSoftwareUpdate : NSTask

#ifdef __RUN_AS_ROOT__
/**
 *  NSTask Wrapper to Run managedsoftwareupdate
 *
 *  @param args  Arguments normally passed to managedsoftwareupdate
 *  @param reply <#reply description#>
 */
+(void)runWithArgs:(NSArray *)args reply:(void (^)(NSArray *runErrors, NSError *execError))reply;
#endif

+(NSString*)version;
+(BOOL)instanceIsRunning;
@end