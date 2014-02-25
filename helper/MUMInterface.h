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
-(void)configureMunki:(NSDictionary*)settings authorization:(NSData *)authData withReply:(void (^)(NSError*))reply;
-(void)uninstall:(NSURL*)mainAppURL authorization:(NSData *)authData withReply:(void (^)(NSError*))reply;
-(void)quitHelper;
@end



