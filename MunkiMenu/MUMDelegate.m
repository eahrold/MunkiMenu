//
//  AppDelegate.m
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMDelegate.h"
#import "MUMInterface.h"
#import "MUMHelperConnection.h"
#import "MUMError.h"
#import "AHLaunchCtl.h"

@implementation MUMDelegate
-(void)applicationWillFinishLaunching:(NSNotification *)notification{
    [[NSUserDefaults standardUserDefaults]registerDefaults:@{kMUMShowManagedInstalls:  @NO,
                                                             kMUMShowOptionalInstalls: @YES,
                                                             kMUMShowManagedUpdates:   @NO,
                                                             kMUMShowItemsToInsatll:   @YES,
                                                             kMUMShowItemsToRemove:    @YES,
                                                             kMUMNotificationsEnabled: @YES}];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    NSError *error;
    if(![[NSFileManager defaultManager]fileExistsAtPath:@"/Applications/Utilities/Managed Software Update.app"]){
        [MUMError presentErrorWithCode:kMUMErrorMunkiNotInstalled
                              delegate:self
                    didPresentSelector:@selector(setupDidEndWithTerminalError:)];
    }
   
    if(![AHLaunchCtl installHelper:kMUMHelperName
                            prompt:@"To add Managed Software Update to the Status Bar"
                             error:&error])
    {
        if(error)
        {
            NSLog(@"%@",error.localizedDescription);
            [MUMError presentErrorWithCode:kMUMErrorCouldNotInstallHelper
                                  delegate:self
                        didPresentSelector:@selector(setupDidEndWithTerminalError:)];
        }
        return;
    }
    [[NSNotificationCenter defaultCenter]postNotificationName:MUMFinishedLaunching object:self];
}

- (void)setupDidEndWithTerminalError:(NSAlert *)alert
{
    [NSApp terminate:self];
}

- (void)setupDidEndWithUninstallRequest{
    [MUMError presentErrorWithCode:kMUMErrorUninstallRequest
                          delegate:self
                didPresentSelector:@selector(setupDidEndWithTerminalError:)];
}

-(void)applicationWillTerminate:(NSNotification *)notification{
    MUMHelperConnection *helper = [MUMHelperConnection new];
    [helper connectToHelper];
    [[helper.connection remoteObjectProxy] quitHelper];
}

-(void)applicationWillResignActive:(NSNotification *)notification{
    [[NSNotificationCenter defaultCenter]postNotificationName:MUMClosePopover object:nil];
}
@end
