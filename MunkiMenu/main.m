//
//  main.m
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AHLaunchCtl.h"

void previouse_release_fixes(){
    NSError *error;

    AHLaunchCtl *controller = [AHLaunchCtl new];
    NSString* badLaunchAgentNamed = [NSString stringWithFormat:@"%@launcher",[[NSBundle mainBundle]bundleIdentifier]];
    NSLog(@"%@",badLaunchAgentNamed);

    [controller remove:badLaunchAgentNamed fromDomain:kAHGlobalLaunchAgent error:&error];
}

int preinstall(){
    printf("preinstalling...\n");
    NSError *error;
    if(![AHLaunchCtl launchAtLogin:[[NSBundle mainBundle]bundlePath] launch:NO global:YES keepAlive:NO error:&error]){
        if(error){
            NSLog(@"%@",error.localizedDescription);
            return 1;
        }
    }
    previouse_release_fixes();
    
    return 0;
}

int postinstall(BOOL launchAtLogin){
    printf("postinstalling...\n");

    NSError *error;
    if(![AHLaunchCtl installHelper:@"com.googlecode.MunkiMenu.helper"
                            prompt:@"To add Managed Software Update to the Status Bar"
                             error:&error]){
        if(error){
            NSLog(@"%@",error.localizedDescription);
            return 1;
        }
    }
    
    if(![AHLaunchCtl launchAtLogin:[[NSBundle mainBundle]bundlePath] launch:launchAtLogin global:YES keepAlive:NO error:&error]){
        NSLog(@"error!");
        if(error){
            NSLog(@"%@",error.localizedDescription);
            return 1;
        }
    }
    return 0;
}

int preuninstall(){
    printf("preuninstalling...\n");
    NSError *error;
    if(![AHLaunchCtl uninstallHelper:@"com.googlecode.MunkiMenu.helper" error:&error]){
        if(error){
            NSLog(@"%@",error.localizedDescription);
            return 1;
        }
    }
    
    if(![AHLaunchCtl launchAtLogin:[[NSBundle mainBundle]bundlePath] launch:NO global:YES keepAlive:NO error:&error]){
        NSLog(@"error!");
        if(error){
            NSLog(@"%@",error.localizedDescription);
            return 1;
        }
    }
    return 0;
}

int main(int argc, const char * argv[])
{
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    if (args.count > 1){
        if([args[1] isEqualToString:@"--preinstall"]){
            return preinstall();
        }
        else if([args[1] isEqualToString:@"--postinstall"]){
            return postinstall(YES);
        }
        else if([args[1] isEqualToString:@"--postinstall-no-launch"]){
            return postinstall(NO);
        }
        else if([args[1] isEqualToString:@"--preuninstall"]){
            return preuninstall();
        }
    }
    return NSApplicationMain(argc, argv);
}
