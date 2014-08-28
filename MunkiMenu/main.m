//
//  main.m
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "AHLaunchCtl.h"
#import <SystemConfiguration/SystemConfiguration.h>

NSString* const kPreinstall          = @"--preinstall";
NSString* const kPostinstall         = @"--postinstall";
NSString* const kPreuninstall        = @"--preuninstall";
NSString* const kPostinstallNoLaunch = @"--postinstall-no-launch";
NSString* const kCliHelp             = @"--help";

int usage(int rc){
    printf("\nMunkiMenu install script usage:\n" );
    printf("  %s   : unload/quit running instance and clean up previous verson issues\n" ,kPreinstall.UTF8String);
    printf("  %s  : install Priviledge Helper Tool and install launchd agent to launch at login\n",kPostinstall.UTF8String);
    printf("  %s : remove helper tool and remove launch at login agent\n" ,kPreuninstall.UTF8String);
    
    printf( "\nOther Options:\n" );
    printf("  %s : install privileged helper tool only, do not launch at login\n\n" ,kPostinstallNoLaunch.UTF8String);
    return rc;
}

void previouse_release_fixes(){
    NSError *error;
    AHLaunchCtl *controller = [AHLaunchCtl new];
    // Previous post install script was missing a "." in a os.path.join,
    // which could result in two instances of the application in the menu bar
    [controller remove:@"com.googlecode.MunkiMenulauncher" fromDomain:kAHGlobalLaunchAgent error:&error];
}

int preinstall(){
    printf("Starting preinstall...\n");
    NSError *error;
    if(![AHLaunchCtl launchAtLogin:[[NSBundle mainBundle]bundlePath] launch:NO global:YES keepAlive:NO error:&error]){
        if(error){
            NSLog(@"%@",error.localizedDescription);
        }
    }
    previouse_release_fixes();
    printf("done with preinsatll...\n");

    return 0;
}

int postinstall(BOOL launchAtLogin){
    printf("Starting postinstall...\n");
    NSError *error;
    if(![AHLaunchCtl installHelper:@"com.googlecode.MunkiMenu.helper"
                            prompt:@"To add Managed Software Update to the Status Bar"
                             error:&error]){
        if(error){
            NSLog(@"ERROR during postinstall: %@",error.localizedDescription);
            return (int)error.code;
        }
    }

    if(![AHLaunchCtl launchAtLogin:[[NSBundle mainBundle]bundlePath] launch:launchAtLogin global:YES keepAlive:NO error:&error]){
        if(error){
            NSLog(@"%@",error.localizedDescription);
            return (int)error.code;
        }
    }
    printf("done with postinstall...\n");
    return 0;
}

int preuninstall(){
    printf("Starting preuninstall...\n");
    NSError *error;
    if(![AHLaunchCtl removeFilesForHelperWithLabel:@"com.googlecode.MunkiMenu.helper" error:&error]){
        NSLog(@"ERROR during pre-uninstall:%@",error.localizedDescription);
        return (int)error.code;
    }
    
    if(![AHLaunchCtl uninstallHelper:@"com.googlecode.MunkiMenu.helper" prompt:@"" error:&error]){
        NSLog(@"%@",error.localizedDescription);
        return (int)error.code;
    }
    
    if(![AHLaunchCtl launchAtLogin:[[NSBundle mainBundle]bundlePath] launch:NO global:YES keepAlive:NO error:&error]){
        NSLog(@"error!");
        if(error){
            NSLog(@"%@",error.localizedDescription);
            return (int)error.code;
        }
    }
    printf("done with preuninsatll...\n");

    return 0;
}

int main(int argc, const char * argv[])
{
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    NSPredicate *isOptArgPred = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH '--' AND SELF CONTAINS[CD] 'install'"];
    
    if (args.count > 1){
        NSString *installArg =  [[args filteredArrayUsingPredicate:isOptArgPred] lastObject];
        BOOL isMunkiScriptKey =  installArg ? YES:NO;
            
        if(isMunkiScriptKey) {
            if([installArg isEqualToString:kPreinstall]){
                return preinstall();
            }
            else if([installArg isEqualToString:kPostinstall]){
                return postinstall(YES);
            }
            else if([installArg isEqualToString:kPostinstallNoLaunch]){
                return postinstall(NO);
            }
            else if([installArg isEqualToString:kPreuninstall]){
                return preuninstall();
            }
            else if([installArg isEqualToString:kCliHelp]){
                return usage(0);
            }else{
                printf( "\nWarning: \"%s\" is not a valid option!",[installArg UTF8String]);
                return usage(1);
            }
        }
    }
    return NSApplicationMain(argc, argv);
}
