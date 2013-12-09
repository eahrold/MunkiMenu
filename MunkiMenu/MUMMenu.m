//
//  MUMMenu.m
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMMenu.h"
#import "MUMInterface.h"
#import "NSString(TextField)+isNotBlank.h"

@implementation MUMMenu{
    NSMutableSet* currentMenuItems;
}
@synthesize delegate,notificationMenuItem;



#pragma mark - Menu Setup
-(void)awakeFromNib{
    // we use the currentMenuItems NSSet to hold the All of
    // the NSMenu items for easy removal during the menu refresh
    if(!currentMenuItems){
        currentMenuItems = [NSMutableSet new];
    }
}

-(NSInteger)insertIndex{
    return [self numberOfItems]-4;
}

-(void)refreshAllItems{
    for(NSMenuItem* item in currentMenuItems){
        [self removeItem:item];
    }
    
    [currentMenuItems removeAllObjects];
    
    [self addSettingsToMenu];
    [self addManagedInstallListToMenu];
    [self addOptionalInstallListToMenu];
    [self addItemsToInstallListToMenu];
    [self addItemsToRemoveListToMenu];
    [self addManagedUpdateListToMenu];
}

-(void)refreshing{
    for(NSMenuItem* item in currentMenuItems){
        [self removeItem:item];
    }
    
    [currentMenuItems removeAllObjects];
    [self addSettingsToMenu];
    
    NSMenuItem* refreshing = [NSMenuItem new];
    [refreshing setTitle:@"Refreshing Menu..."];
    
    [self insertItem:refreshing atIndex:[self insertIndex]];
    [currentMenuItems addObject:refreshing];    
}

-(void)addAlternateItemsToMenu{
    /*add the about an uninstall here so we can set the selectors programatically*/
    NSMenuItem* about = [[NSMenuItem alloc]initWithTitle:@"About..."
                                                  action:@selector(orderFrontStandardAboutPanel:)
                                           keyEquivalent:@""];
    
    [about setAlternate:YES];
    [about setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [about setTarget:[NSApplication sharedApplication]];
    [self insertItem:about atIndex:1];
    
    NSMenuItem* uninstall = [[NSMenuItem alloc]initWithTitle:@"Uninstall..."
                                                      action:@selector(uninstallHelper:)
                                               keyEquivalent:@""];
    [uninstall setAlternate:YES];
    [uninstall setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [uninstall setTarget:delegate];
    [self insertItem:uninstall atIndex:[self numberOfItems]];
    
    NSMenuItem* quit = [[NSMenuItem alloc]initWithTitle:@"Quit..."
                                                      action:@selector(quitNow:)
                                               keyEquivalent:@""];
    [quit setAlternate:YES];
    [quit setTarget:delegate];
    [self insertItem:quit atIndex:[self numberOfItems]];
}

#pragma mark - Menu Settings
-(void)addSettingsToMenu{
    NSString* repoURL       = [delegate repoURL:self];
    NSString* manifestURL   = [delegate manifestURL:self];
    NSString* catalogURL    = [delegate catalogURL:self];
    NSString* packageURL    = [delegate packageURL:self];
    NSString* clientID      = [delegate clientIdentifier:self];
    NSString* logFile       = [delegate logFile:self];
    
    NSMenuItem* settings = [NSMenuItem new];
    [settings setTitle:@"Settings"];
    [settings setAlternate:YES];

    NSMenu* details = [[NSMenu alloc]init];
    [settings setSubmenu:details];
   
    // Build out the details Menu
    if(repoURL.isNotBlank){
        NSMenuItem* menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Repo URL: %@",repoURL]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(manifestURL.isNotBlank){
        NSMenuItem* menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Manifest URL: %@",manifestURL]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(catalogURL.isNotBlank){
        NSMenuItem* menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Catalog URL: %@",catalogURL]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(packageURL.isNotBlank){
        NSMenuItem* menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Package URL: %@",packageURL]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(clientID.isNotBlank){
        NSMenuItem* menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Client Identifier: %@",clientID]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(logFile.isNotBlank){
        NSMenuItem* menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Open Log: %@",logFile]];
        [menu_item setAction:@selector(openLogFile:)];
        [menu_item setTarget:delegate];
        [details addItem:menu_item];
    }
    
    // If the computer is managed using MCX there's no use editing
    // the ManagedInsalls.plist, so we won't bother adding this to the menu
    BOOL mcxManaged = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Managed Preferences/ManagedInstalls.plist"];
    
    if(!mcxManaged){
        NSMenuItem* menu_item = [NSMenuItem new];
        [menu_item setTitle:@"Configure..."];
        [menu_item setAction:@selector(openConfigSheet)];
        [menu_item setTarget:delegate];
        [details addItem:menu_item];
    }
    
    [self insertItem:settings atIndex:1];
    [currentMenuItems addObject:settings];
}

#pragma mark - Menu Lists
/* Right now there are 4 lists we add to the menu, Managed Installs, Optionals Installs, Items to Install, and Items to Remove.  The delegate is wired up to get more values, but this seems to be a good amount without getting excessive */
-(void)addManagedInstallListToMenu{
    BOOL show = [[NSUserDefaults standardUserDefaults] boolForKey:kShowManagedInstalls];
    
    if(show){
        NSArray* managedInstals = [delegate managedInstalls:self];
        if(!managedInstals.count)return;
        
        NSMenuItem* menu_item = [NSMenuItem new];
        [menu_item setTitle:@"Managed Installs"];
        
        NSMenu* details = [NSMenu new];
        for (NSString* item in managedInstals){
            NSMenuItem* install = [NSMenuItem new];
            [install setTitle:item];
            [details addItem:install];
        }
        
        [self setSubmenu:details forItem:menu_item];
        [self insertItem:menu_item atIndex:[self insertIndex]];
        [currentMenuItems addObject:menu_item];
    }
}

-(void)addManagedUpdateListToMenu{
    BOOL show = [[NSUserDefaults standardUserDefaults] boolForKey:kShowManagedUpdates];
    
    if(show){
        NSArray* updates = [delegate managedUpdates:self];
        if(!updates.count)return;
        
        NSMenuItem* menu_item = [NSMenuItem new];
        [menu_item setTitle:@"Managed Updates"];
        
        NSMenu* details = [[NSMenu alloc]init];
        for (NSString* item in updates){
            NSMenuItem* install = [NSMenuItem new];
            [install setTitle:item];
            [details addItem:install];
        }
        
        [self setSubmenu:details forItem:menu_item];
        [self insertItem:menu_item atIndex:[self insertIndex]];
        [currentMenuItems addObject:menu_item];
    }
}

-(void)addOptionalInstallListToMenu{
    BOOL show = [[NSUserDefaults standardUserDefaults] boolForKey:kShowOptionalInstalls];
    
    if(show){
        NSArray* optionalInstals = [delegate optionalInstalls:self];
        if(!optionalInstals.count)return;

        NSMenuItem* menu_item = [NSMenuItem new];
        [menu_item setTitle:@"Optional Installs"];
        
        NSMenu* details = [[NSMenu alloc]init];
        for (NSDictionary* dict in optionalInstals){
            NSMenuItem* install = [NSMenuItem new];
            [install setTitle:dict[@"item"]];
            
            if([[dict valueForKey:@"installed"] boolValue]){
                [install setState:YES];
            }else{
                [install setTarget:delegate];
                [install setAction:@selector(runManagedSoftwareUpdate:)];
            }
            [details addItem:install];
        }
        
        [self setSubmenu:details forItem:menu_item];
        [self insertItem:menu_item atIndex:[self insertIndex]];
        [currentMenuItems addObject:menu_item];
    }
}

-(void)addItemsToInstallListToMenu{
    BOOL show = [[NSUserDefaults standardUserDefaults] boolForKey:kShowItemsToInsatll];
    if(show){
        NSArray* installs = [delegate itemsToInstall:self];
        if(!installs.count)return;
        
        NSMenuItem* menu_item = [NSMenuItem new];
        [menu_item setTitle:@"Items To Install"];
        
        NSMenu* details = [[NSMenu alloc]init];
        for (NSString* item in installs){
            NSMenuItem* install = [NSMenuItem new];
            [install setTitle:item];
            [details addItem:install];
        }
        
        [self setSubmenu:details forItem:menu_item];
        [self insertItem:menu_item atIndex:[self insertIndex]];
        [currentMenuItems addObject:menu_item];
    }
}

-(void)addItemsToRemoveListToMenu{
    BOOL show = [[NSUserDefaults standardUserDefaults] boolForKey:kShowItemsToRemove];
    
    if(show){
        NSArray* removals = [delegate itemsToRemove:self];
        if(!removals.count)return;
        
        NSMenuItem* menu_item = [NSMenuItem new];
        [menu_item setTitle:@"Items To Remove"];
        
        NSMenu* details = [[NSMenu alloc]init];
        for (NSString* item in removals){
            NSMenuItem* install = [NSMenuItem new];
            [install setTitle:item];
            [details addItem:install];
        }
        
        [self setSubmenu:details forItem:menu_item];
        [self insertItem:menu_item atIndex:[self insertIndex]];
        [currentMenuItems addObject:menu_item];
    }
}



@end
