//
//  MUMNSXPC.h
//  MunkiMenu
//
//  Created by Eldon on 2/3/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MUMSettings;

@interface MUMHelperConnection : NSObject
@property (atomic, strong, readonly) NSXPCConnection * connection;
-(void)connectToHelper;

@end
