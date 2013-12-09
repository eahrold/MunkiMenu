//
//  MUMMenu.h
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MUMMenu, MUMController;

@protocol MUMMenuDelegate <NSObject>
-(NSString*)repoURL:(MUMMenu*)menu;
-(NSString*)manifestURL:(MUMMenu*)menu;
-(NSString*)catalogURL:(MUMMenu*)menu;
-(NSString*)packageURL:(MUMMenu*)menu;
-(NSString*)clientIdentifier:(MUMMenu*)menu;
-(NSString*)logFile:(MUMMenu *)menu;
-(NSArray*)managedInstalls:(MUMMenu *)menu;
-(NSArray*)managedUpdates:(MUMMenu*)menu;
-(NSArray*)managedUninstalls:(MUMMenu*)menu;
-(NSArray*)optionalInstalls:(MUMMenu *)menu;
-(NSArray*)processedInstalls:(MUMMenu *)menu;
-(NSArray*)installedItems:(MUMMenu *)menu;
-(NSArray*)itemsToInstall:(MUMMenu *)menu;
-(NSArray*)itemsToRemove:(MUMMenu *)menu;
-(NSArray*)warnings:(MUMMenu *)menu;

-(IBAction)runManagedSoftwareUpdate:(id)sender;
-(void)openLogFile:(id)sender;
-(void)uninstallHelper:(id)sender;
-(void)quitNow:(id)sender;
-(void)openConfigSheet;

@end

@interface MUMMenu : NSMenu

@property (weak) id<MUMMenuDelegate>delegate;
@property (weak) NSMenuItem* notificationMenuItem;
-(void)addAlternateItemsToMenu;
-(void)addSettingsToMenu;
-(void)addManagedInstallListToMenu;
-(void)addOptionalInstallListToMenu;
-(void)addItemsToInstallListToMenu;
-(void)addItemsToRemoveListToMenu;
-(void)addManagedUpdateListToMenu;
-(void)refreshAllItems;
-(void)refreshing;
@end
