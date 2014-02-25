//
//  MUMNSXPC.m
//  MunkiMenu
//
//  Created by Eldon on 2/3/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import "MUMHelperConnection.h"
#import "MUMInterface.h"

@interface MUMHelperConnection ()
@property (atomic, strong, readwrite) NSXPCConnection * connection;
@end

@implementation MUMHelperConnection{
}

#pragma mark - Initializers
-(void)connectToHelper{
    assert([NSThread isMainThread]);
    if (self.connection == nil) {
        self.connection = [[NSXPCConnection alloc] initWithMachServiceName:kMUMHelperName
                                                                   options:NSXPCConnectionPrivileged];
        
        self.connection.remoteObjectInterface = [NSXPCInterface
                                                 interfaceWithProtocol:@protocol(MUMHelperAgent)];
        
        self.connection.invalidationHandler = ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
            self.connection.invalidationHandler = nil;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.connection = nil;
            }];
#pragma clang diagnostic pop
        };
        self.connection.exportedObject = self;
        
        [self.connection resume];
    }
}



@end
