//
//  MUMHelper.h
//  MunkiMenu
//
//  Created by Eldon on 11/28/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MUMInterface.h"

@interface MUMHelper : NSObject <HelperAgent,NSXPCListenerDelegate> {
    void (^replyBlock)(NSFileHandle *, NSError *);
}

// This property is a weak reference because the connection will retain this object, so we don't want to create a retain cycle.
@property (weak) NSXPCConnection *xpcConnection;
@property (nonatomic, assign) BOOL helperToolShouldQuit;
+ (MUMHelper *)sharedAgent;

@end
