//
//  MUMInterface.h
//  MunkiMenu
//
//  Created by Eldon on 11/29/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MUMConstants.h"
#import "MUMSettings.h"
#import "MUMError.h"

static NSString * const kMUMHelperName = @"com.googlecode.MunkiMenu.helper";

@protocol MUMHelperAgent
@required
-(void)getPreferenceDictionary:(void (^)(MUMSettings *, NSError *))reply;

/**
 *  Change the munki configuration settings
 *
 *  @param settings New Values to set
 *  @param authData external form authorization data
 *  @param reply    reply block that takes two objects, MUMSettings and NSError
 */
-(void)configureMunki:(NSDictionary*)settings
        authorization:(NSData *)authData
            withReply:(void (^)(MUMSettings *, NSError *))reply;

/**
 *  Install an optional item
 *
 *  @param install passing YES will install passing NO will remove
 *  @param title   title of the Managed Update item to install
 *  @param reply   reply block takes one object, NSError
 */
-(void)installOptionalItems:(BOOL)install
                      title:(NSString *)title
                  withReply:(void (^)(NSError*))reply;

/**
 *  Uninstall MunkiMenu helper tool components, and Application launcher
 *
 *  @param mainAppURL path to the main app
 *  @param authData external form authorization data
 *  @param reply   reply block takes one object, NSError
 */
-(void)uninstall:(NSURL*)mainAppURL
   authorization:(NSData *)authData
       withReply:(void (^)(NSError*))reply;

-(void)quitHelper;
@end



