//
//  MUMController.m
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMController.h"

const NSString* MSUbundleID = @"ManagedInstalls";

@implementation MUMController{
    NSDictionary* msuInfo;
    NSDictionary* msuReport;
    NSDictionary* msuInventory;
}
@synthesize menu;

-(void)awakeFromNib{
    [self getMSUProperties];
    statusItem = [[NSStatusBar systemStatusBar]statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:menu];
    [statusItem setImage:[NSImage imageNamed:@"Managed Software Update18x18"]];
    [statusItem setHighlightMode:YES];
    [menu setDelegate:self];
    
    [menu addManagedInstallListToMenu];
    [menu addOptionalInstallListToMenu];
    [menu addInfoToMenu];
}

#pragma mark - IBActions
-(IBAction)runManagedSoftwareUpdate:(id)sender{
    NSTask* task = [[NSTask alloc]init];
    [task setLaunchPath:@"/Applications/Utilities/Managed Software Update.app/Contents/MacOS/Managed Software Update"];
    [task launch];
}

-(IBAction)quitNow:(id)sender{
    [NSApp terminate:self];
}


#pragma mark - Menu Delegate
-(NSString*)managedSoftwareUpdateURL:(MUMMenu*)menu{
    return [self stringFromCFPref:@"SoftwareRepoURL"];
}

-(NSString *)manifestName:(MUMMenu *)menu{
    return msuReport[@"ManifestName"];
}

-(NSArray *)avaliableUpdates:(MUMMenu *)menu{
    return msuInfo[@"managed_installs"];
}

-(NSArray*)optionalInstalls:(MUMMenu *)menu{
    return msuInfo[@"optional_installs"];
}

-(NSArray*)processedInstalls:(MUMMenu *)menu{
    return msuInfo[@"processed_installs"];
}

-(NSArray *)installedItems:(MUMMenu *)menu{
    return msuReport[@"InstalledItems"];
}

-(NSArray *)itemsToInstall:(MUMMenu *)menu{
    return msuReport[@"ItemsToInstall"];
}

-(NSArray *)itemsToRemove:(MUMMenu *)menu{
    return msuReport[@"ItemsToRemove"];
}

-(NSArray *)warnings:(MUMMenu *)menu{
    return msuReport[@"Warnings"];
}

#pragma mark - utils
-(NSString*)stringFromCFPref:(NSString*)pref{
    NSString* string = (__bridge NSString *)(CFPreferencesCopyAppValue((__bridge CFStringRef)(pref), (__bridge CFStringRef)(MSUbundleID)));
    return string;
}


-(void)getMSUProperties{
    NSString* msuDir = [self stringFromCFPref:@"ManagedInstallDir"];
    if(!msuDir)return;
    
    NSString *info = [NSString stringWithFormat:@"%@/InstallInfo.plist",msuDir];
    NSString *inventory = [NSString stringWithFormat:@"%@/ApplicationInventory.plist",msuDir];
    NSString *reports = [NSString stringWithFormat:@"%@/ManagedInstallReport.plist",msuDir];

    msuInfo = [NSDictionary dictionaryWithContentsOfFile:info];
    msuInventory = [NSDictionary dictionaryWithContentsOfFile:inventory];
    msuReport = [NSDictionary dictionaryWithContentsOfFile:reports];
}

@end
