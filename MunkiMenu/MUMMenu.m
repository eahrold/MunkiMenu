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
    NSMutableSet *_currentMenuItems;
}
@synthesize delegate;



#pragma mark - Menu Setup
-(void)awakeFromNib{
    // we use the currentMenuItems NSSet to hold the All of
    // the NSMenu items for easy removal during the menu refresh
    if(!_currentMenuItems){
        _currentMenuItems = [NSMutableSet new];
    }
}

-(NSInteger)insertIndex{
    return self.numberOfItems-4;
}

-(void)refreshAllItems:(MUMSettings*)settings{
    for(NSMenuItem *item in _currentMenuItems){
        @try {
            [self removeItem:item];
        }
        @catch (NSException *exception) {
            NSLog(@"that menu item dosn't exist: %@",item);
        }
    }
    [_currentMenuItems removeAllObjects];

    [self addSettingsToMenu:settings];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults boolForKey:kMUMShowOptionalInstalls])
       [self addOptionalInstallListToMenu:settings.optionalInstalls];
    
    if([defaults boolForKey:kMUMShowManagedInstalls])
        [self addItemsToMenu:settings.managedInstalls title:@"Managed Installs"];

    if([defaults boolForKey:kMUMShowItemsToInsatll])
        [self addItemsToMenu:settings.itemsToInstall title:@"Items to Install"];

    if([defaults boolForKey:kMUMShowItemsToRemove])
        [self addItemsToMenu:settings.itemsToInstall title:@"Items to Remove"];
    
    if([defaults boolForKey:kMUMShowManagedUpdates])
        [self addItemsToMenu:settings.managedUpdates title:@"Managed Updates"];
}

-(void)refreshing:(NSString*)title{
    for(NSMenuItem *item in _currentMenuItems){
        [self removeItem:item];
    }
    
    [_currentMenuItems removeAllObjects];
    
    NSMenuItem *refreshing = [NSMenuItem new];
    [refreshing setTitle:title ? title : @"Refreshing Menu..."];
    
    [self insertItem:refreshing atIndex:[self insertIndex]];
    [_currentMenuItems addObject:refreshing];    
}


-(void)addAlternateItemsToMenu{
    /*add the about an uninstall here so we can set the selectors programatically*/
    NSMenuItem *about = [[NSMenuItem alloc]initWithTitle:@"About..."
                                                  action:@selector(orderFrontStandardAboutPanel:)
                                           keyEquivalent:@""];
    
    [about setAlternate:YES];
    [about setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [about setTarget:[NSApplication sharedApplication]];
    [self insertItem:about atIndex:1];
    
    NSMenuItem *uninstall = [[NSMenuItem alloc]initWithTitle:@"Uninstall..."
                                                      action:@selector(uninstallHelper:)
                                               keyEquivalent:@""];
    [uninstall setAlternate:YES];
    [uninstall setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [uninstall setTarget:delegate];
    [self insertItem:uninstall atIndex:[self numberOfItems]];
    
    NSMenuItem *quit = [[NSMenuItem alloc]initWithTitle:@"Quit..."
                                                      action:@selector(quitNow:)
                                               keyEquivalent:@""];
    [quit setAlternate:YES];
    [quit setTarget:delegate];
    [self insertItem:quit atIndex:[self numberOfItems]];
}

#pragma mark - Menu Settings
-(void)addSettingsToMenu:(MUMSettings *)settings{
    NSMenuItem *settingsMenu = [NSMenuItem new];
    [settingsMenu setTitle:@"Settings"];
    [settingsMenu setAlternate:YES];

    NSMenu *details = [[NSMenu alloc]init];
    [settingsMenu setSubmenu:details];

    // Build out the details Menu
    if(settings.softwareRepoURL.isNotBlank){
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Repo URL: %@",settings.softwareRepoURL]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(settings.manifestURL.isNotBlank){
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Manifest URL: %@",settings.manifestURL]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(settings.catalogURL.isNotBlank){
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Catalog URL: %@",settings.catalogURL]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(settings.packageURL.isNotBlank){
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Package URL: %@",settings.packageURL]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(settings.clientIdentifier.isNotBlank){
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Client Identifier: %@",settings.clientIdentifier]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(settings.logFile.isNotBlank){
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Open Log: %@",settings.logFile]];
        [menu_item setAction:@selector(openLogFile:)];
        [menu_item setTarget:delegate];
        [details addItem:menu_item];
    }
    
    NSMenuItem *configMenuItem = [NSMenuItem new];
    [configMenuItem setTitle:@"Configure..."];
    [configMenuItem setAction:@selector(openConfigView)];
    [configMenuItem setTarget:delegate];
    [details addItem:configMenuItem];
   
    [self insertItem:settingsMenu atIndex:1];
    [_currentMenuItems addObject:settingsMenu];
}

#pragma mark - Menu Lists
-(void)addOptionalInstallListToMenu:(NSArray*)installs{
    if(!installs.count)return;
    
    NSMenuItem *menu_item = [NSMenuItem new];
    [menu_item setTitle:@"Optional Installs"];
    
    NSMenu *details = [[NSMenu alloc]init];
    for (NSDictionary *dict in installs){
        NSMenuItem *install = [NSMenuItem new];
        [install setTitle:dict[@"item"]];
        
        if([[dict valueForKey:@"installed"] boolValue]){
            [install setState:YES];
        }
        
        [install setTarget:delegate];
        [install setAction:@selector(chooseOptionalInstall:)];
        [details addItem:install];
    }
    
    [self setSubmenu:details forItem:menu_item];
    [self insertItem:menu_item atIndex:[self insertIndex]];
    [_currentMenuItems addObject:menu_item];
}

-(void)addItemsToMenu:(NSArray*)items title:(NSString*)title{
    if(!items.count)return;
    
    NSMenuItem *menuItem = [NSMenuItem new];
    [menuItem setTitle:title];
    
    NSMenu *subMenu = [[NSMenu alloc]init];
    for (NSString *item in items){
        NSMenuItem *subMenuItem = [NSMenuItem new];
        [subMenuItem setTitle:item];
        [subMenu addItem:subMenuItem];
    }
    
    [self setSubmenu:subMenu forItem:menuItem];
    [self insertItem:menuItem atIndex:self.insertIndex];
    [_currentMenuItems addObject:menuItem];
}

@end
