//
//  MUMMenu.m
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMMenu.h"
#import "NSString(TextField)+isNotBlank.h"

@implementation MUMMenu{
    NSMutableSet* currentMenuItems;
}
@synthesize delegate,notificationMenuItem;



#pragma mark - Menu Setup
-(void)awakeFromNib{
    if(!currentMenuItems){
        currentMenuItems = [NSMutableSet new];
    }
}

-(void)refreshAllItems{
    for(NSMenuItem* item in currentMenuItems){
        [self removeItem:item];
    }
    [currentMenuItems removeAllObjects];
    
    [self addSettingsToMenu];
    [self addManagedInstallListToMenu];
    [self addOptionalInstallListToMenu];
}

-(void)addAlternateItemsToMenu{
    /*add the about an uninstall here so we can set the selectors programatically*/
    NSMenuItem* about = [[NSMenuItem alloc]initWithTitle:@"About..."
                                                  action:@selector(orderFrontStandardAboutPanel:)
                                           keyEquivalent:@""];
    
    [about setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [about setTarget:[NSApplication sharedApplication]];
    [about setAlternate:YES];
    [self insertItem:about atIndex:1];
    
    NSMenuItem* uninstall = [[NSMenuItem alloc]initWithTitle:@"Uninstall..."
                                                      action:@selector(uninstallHelper:)
                                               keyEquivalent:@""];
    
    [uninstall setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [uninstall setTarget:delegate];
    [uninstall setAlternate:YES];
    [self insertItem:uninstall atIndex:[self numberOfItems]];
    
    NSMenuItem* quit = [[NSMenuItem alloc]initWithTitle:@"Quit..."
                                                      action:@selector(quitNow:)
                                               keyEquivalent:@""];
    
    [quit setTarget:delegate];
    [quit setAlternate:YES];
    [self insertItem:quit atIndex:[self numberOfItems]];
}

#pragma mark - Menu Settings
-(void)addSettingsToMenu{
    NSString* repoURL = [delegate repoURL:self];
    NSString* manifestURL = [delegate manifestURL:self];
    NSString* catalogURL = [delegate catalogURL:self];
    NSString* packageURL = [delegate packageURL:self];

    NSString* clientID = [delegate clientIdentifier:self];
    
    NSMenuItem* info = [[NSMenuItem alloc]initWithTitle:@"Settings"
                                                 action:NULL
                                          keyEquivalent:@""];
    
    NSMenu* details = [[NSMenu alloc]init];
    
    if(repoURL.isNotBlank){
        NSMenuItem* menu_url;
        menu_url = [[NSMenuItem alloc]initWithTitle:[NSString stringWithFormat:@"Repo URL: %@",repoURL]
                                         action:NULL
                                  keyEquivalent:@""];
        [menu_url setTarget:self];
        [details addItem:menu_url];
    }
    
    if(manifestURL.isNotBlank){
        NSMenuItem* menu_url;
        menu_url = [[NSMenuItem alloc]initWithTitle:[NSString stringWithFormat:@"Manifest URL: %@",manifestURL]
                                             action:NULL
                                      keyEquivalent:@""];
        [menu_url setTarget:self];
        [details addItem:menu_url];
    }
    
    if(catalogURL.isNotBlank){
        NSMenuItem* menu_url;
        menu_url = [[NSMenuItem alloc]initWithTitle:[NSString stringWithFormat:@"Catalog URL: %@",catalogURL]
                                             action:NULL
                                      keyEquivalent:@""];
        [menu_url setTarget:self];
        [details addItem:menu_url];
    }
    
    if(packageURL.isNotBlank){
        NSMenuItem* menu_url;
        menu_url = [[NSMenuItem alloc]initWithTitle:[NSString stringWithFormat:@"Package URL: %@",packageURL]
                                             action:NULL
                                      keyEquivalent:@""];
        [menu_url setTarget:self];
        [details addItem:menu_url];
    }
    
    if(clientID.isNotBlank){
        NSMenuItem* menu_cid;
        menu_cid = [[NSMenuItem alloc]initWithTitle:[NSString stringWithFormat:@"Client Identifier: %@",clientID]
                                         action:NULL
                                  keyEquivalent:@""];
        
        [menu_cid setTarget:self];
        [details addItem:menu_cid];
    }
    
    NSMenuItem* menu_logfile;
    menu_logfile = [[NSMenuItem alloc]initWithTitle:[NSString stringWithFormat:@"Open Log: %@",[delegate logFile:self]]
                                         action:@selector(openLogFile:)
                                  keyEquivalent:@""];
    
    [menu_logfile setTarget:delegate];
    [details addItem:menu_logfile];

    // If the computer is managed using MCX there's no use editing the ManagedInsalls.plist
    // so we won't bother adding this to the menu
    BOOL mcxManaged = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Managed Preferences/ManagedInstalls.plist"];
    
    if(!mcxManaged){
        NSMenuItem* menu_configure = [[NSMenuItem alloc]initWithTitle:@"Configure..."
                                                          action:@selector(openConfigSheet)
                                                   keyEquivalent:@""];
        
        [menu_configure setTarget:delegate];
        [details addItem:menu_configure];
    }
    
    [info setSubmenu:details];
    [info setAlternate:YES];
    [self insertItem:info atIndex:1];
    [currentMenuItems addObject:info];
}

#pragma mark - Menu Lists
-(void)addManagedInstallListToMenu{
    NSArray* managedInstals = [delegate managedInstalls:self];
    if(!managedInstals.count)return;
    
    NSMenuItem* mums = [[NSMenuItem alloc]initWithTitle:@"Managed Installs"
                                                 action:NULL
                                          keyEquivalent:@""];
    
    NSMenu* details = [[NSMenu alloc]init];
    for (NSString* item in managedInstals){
        NSMenuItem* install = [[NSMenuItem alloc]initWithTitle:item action:NULL keyEquivalent:@""];
        
        [details addItem:install];
        
    }
    
    [self setSubmenu:details forItem:mums];
    [self insertItem:mums atIndex:4];
    [currentMenuItems addObject:mums];
}

-(void)addOptionalInstallListToMenu{
    NSArray* optionalInstals = [delegate optionalInstalls:self];
    if(!optionalInstals.count)return;

    NSMenuItem* mums = [[NSMenuItem alloc]initWithTitle:@"Optional Installs"
                                                 action:NULL
                                          keyEquivalent:@""];

    NSMenu* details = [[NSMenu alloc]init];
    for (NSDictionary* dict in optionalInstals){
        NSMenuItem* install = [[NSMenuItem alloc]initWithTitle:dict[@"item"] action:NULL keyEquivalent:@""];
        
        if([[dict objectForKey:@"installed"] isEqual:[NSNumber numberWithBool:YES]]){
            [install setState:YES];
        }else{
            [install setTarget:delegate];
            [install setAction:@selector(runManagedSoftwareUpdate:)];
        }
        [details addItem:install];
    }
    
    [self setSubmenu:details forItem:mums];
    [self insertItem:mums atIndex:4];
    [currentMenuItems addObject:mums];
}


@end
