//
//  MUMInterface.h
//  MunkiMenu
//
//  Created by Eldon on 11/29/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* const kHelperName = @"com.googlecode.MunkiMenu.helper";

@protocol HelperAgent
-(void)getPreferenceDictionary:(void (^)(NSDictionary *, NSError *))reply;
-(void)quitHelper;
-(void)installGlobalLoginItem:(NSURL*)loginItem withReply:(void (^)(NSError*))reply;
-(void)uninstall:(NSURL*)mainAppURL withReply:(void (^)(NSError*))reply;
@end
