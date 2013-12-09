//
//  AppDelegate.m
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMDelegate.h"
#import "MUMLoginItem.h"
#import "SMJobBlesser.h"
#import "MUMInterface.h"

@implementation MUMDelegate
-(void)awakeFromNib{
    [[NSUserDefaults standardUserDefaults]registerDefaults:@{kShowManagedInstalls:@NO,
                                                             kShowOptionalInstalls:@YES,
                                                             kShowManagedUpdates:@NO,
                                                             kShowItemsToInsatll:@YES,
                                                             kShowItemsToRemove:@YES,
                                                             kNotificationsEnabled:@YES}];
    
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    NSError* error;
    
    if(![JobBlesser blessHelperWithLabel:kHelperName
                               andPrompt:@"To add Managed Software Update to the Status Bar"
                                   error:&error]){
        
        if(error){
            [NSApp presentError:error modalForWindow:NULL delegate:self
             didPresentSelector:@selector(setupDidEndWithTerminalError:) contextInfo:nil];
        }
    }
    
    [[NSNotificationCenter defaultCenter]postNotificationName:MUMFinishedLaunching object:self];
}

- (void)setupDidEndWithTerminalError:(NSAlert *)alert
{
    [NSApp terminate:self];
}

- (void)setupDidEndWithUninstallRequest{
    [JobBlesser removeHelperWithLabel:kHelperName];
    [NSApp presentError:[NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Helper Tool and associated files have been removed.  You can safely remove MunkiMenu from the Applications folder.  We will now quit"}] modalForWindow:NULL delegate:self
     didPresentSelector:@selector(setupDidEndWithTerminalError:) contextInfo:nil];
}

-(void)applicationWillTerminate:(NSNotification *)notification{
    NSXPCConnection *helperXPCConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName options:NSXPCConnectionPrivileged];
    helperXPCConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [helperXPCConnection resume];
    [[helperXPCConnection remoteObjectProxy] quitHelper];
}

@end
