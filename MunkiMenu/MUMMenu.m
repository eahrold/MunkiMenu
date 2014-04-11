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
    return [self numberOfItems]-4;
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
    [self addManagedInstallListToMenu:settings];
    [self addOptionalInstallListToMenu:settings];
    [self addItemsToInstallListToMenu:settings];
    [self addItemsToRemoveListToMenu:settings];
    [self addManagedUpdateListToMenu:settings];
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
    NSString *repoURL       = settings.softwareRepoURL;
    NSString *manifestURL   = settings.manifestURL;
    NSString *catalogURL    = settings.catalogURL;
    NSString *packageURL    = settings.packageURL;
    NSString *clientID      = settings.clientIdentifier;
    NSString *logFile       = settings.logFile;
    
    NSMenuItem *settingsMenu = [NSMenuItem new];
    [settingsMenu setTitle:@"Settings"];
    [settingsMenu setAlternate:YES];

    NSMenu *details = [[NSMenu alloc]init];
    [settingsMenu setSubmenu:details];
   
    // Build out the details Menu
    if(repoURL.isNotBlank){
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Repo URL: %@",repoURL]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(manifestURL.isNotBlank){
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Manifest URL: %@",manifestURL]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(catalogURL.isNotBlank){
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Catalog URL: %@",catalogURL]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(packageURL.isNotBlank){
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Package URL: %@",packageURL]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(clientID.isNotBlank){
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Client Identifier: %@",clientID]];
        [menu_item setTarget:self];
        [details addItem:menu_item];
    }
    
    if(logFile.isNotBlank){
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:[NSString stringWithFormat:@"Open Log: %@",logFile]];
        [menu_item setAction:@selector(openLogFile:)];
        [menu_item setTarget:delegate];
        [details addItem:menu_item];
    }
    
    NSMenuItem *config_menu = [NSMenuItem new];
    [config_menu setTitle:@"Configure..."];
    [config_menu setAction:@selector(openConfigView)];
    [config_menu setTarget:delegate];
    [details addItem:config_menu];
   
    [self insertItem:settingsMenu atIndex:1];
    [_currentMenuItems addObject:settingsMenu];
}

#pragma mark - Menu Lists
/** Right now there are 4 lists we add to the menu, Managed Installs,
 *  Optionals Installs, Items to Install, and Items to Remove.
 *  The delegate is wired up to get more values,
 *  but this seems to be a good amount without getting excessive
 */

-(void)addManagedInstallListToMenu:(MUMSettings*)settings{
    BOOL show = [[NSUserDefaults standardUserDefaults] boolForKey:kMUMShowManagedInstalls];
    
    if(show){
        NSArray *managedInstals = settings.managedInstalls;
        if(!managedInstals.count)return;
        
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:@"Managed Installs"];
        
        NSMenu *details = [NSMenu new];
        for (NSString *item in managedInstals){
            NSMenuItem *install = [NSMenuItem new];
            [install setTitle:item];
            [details addItem:install];
        }
        
        [self setSubmenu:details forItem:menu_item];
        [self insertItem:menu_item atIndex:[self insertIndex]];
        [_currentMenuItems addObject:menu_item];
    }
}

-(void)addManagedUpdateListToMenu:(MUMSettings*)settings{
    BOOL show = [[NSUserDefaults standardUserDefaults] boolForKey:kMUMShowManagedUpdates];
    
    if(show){
        NSArray *updates = settings.managedUpdates;
        if(!updates.count)return;
        
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:@"Managed Updates"];
        
        NSMenu *details = [[NSMenu alloc]init];
        for (NSString *item in updates){
            NSMenuItem *install = [NSMenuItem new];
            [install setTitle:item];
            [details addItem:install];
        }
        
        [self setSubmenu:details forItem:menu_item];
        [self insertItem:menu_item atIndex:[self insertIndex]];
        [_currentMenuItems addObject:menu_item];
    }
}

-(void)addOptionalInstallListToMenu:(MUMSettings*)settings{
    BOOL show = [[NSUserDefaults standardUserDefaults] boolForKey:kMUMShowOptionalInstalls];
    
    if(show){
        NSArray *optionalInstals = settings.optionalInstalls;
        if(!optionalInstals.count)return;

        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:@"Optional Installs"];
        
        NSMenu *details = [[NSMenu alloc]init];
        for (NSDictionary *dict in optionalInstals){
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
}

-(void)addItemsToInstallListToMenu:(MUMSettings*)settings{
    BOOL show = [[NSUserDefaults standardUserDefaults] boolForKey:kMUMShowItemsToInsatll];
    if(show){
        NSArray *installs = settings.itemsToInstall;
        if(!installs.count)return;
        
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:@"Items To Install"];
        
        NSMenu *details = [[NSMenu alloc]init];
        for (NSString *item in installs){
            NSMenuItem *install = [NSMenuItem new];
            [install setTitle:item];
            [details addItem:install];
        }
        
        [self setSubmenu:details forItem:menu_item];
        [self insertItem:menu_item atIndex:[self insertIndex]];
        [_currentMenuItems addObject:menu_item];
    }
}

-(void)addItemsToRemoveListToMenu:(MUMSettings*)settings{
    BOOL show = [[NSUserDefaults standardUserDefaults] boolForKey:kMUMShowItemsToRemove];
    
    if(show){
        NSArray *removals = settings.itemsToRemove;
        if(!removals.count)return;
        
        NSMenuItem *menu_item = [NSMenuItem new];
        [menu_item setTitle:@"Items To Remove"];
        
        NSMenu *details = [[NSMenu alloc]init];
        for (NSString *item in removals){
            NSMenuItem *install = [NSMenuItem new];
            [install setTitle:item];
            [details addItem:install];
        }
        
        [self setSubmenu:details forItem:menu_item];
        [self insertItem:menu_item atIndex:[self insertIndex]];
        [_currentMenuItems addObject:menu_item];
    }
}


@end
