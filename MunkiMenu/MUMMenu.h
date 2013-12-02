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
-(NSString*)clientIdentifier:(MUMMenu*)menu;
-(NSString*)manifestName:(MUMMenu *)menu;
-(NSArray*)avaliableUpdates:(MUMMenu*)menu;
-(NSArray*)managedInstalls:(MUMMenu *)menu;
-(NSArray*)optionalInstalls:(MUMMenu *)menu;
-(NSArray*)processedInstalls:(MUMMenu *)menu;
-(NSArray*)installedItems:(MUMMenu *)menu;
-(NSArray*)itemsToInstall:(MUMMenu *)menu;
-(NSArray*)itemsToRemove:(MUMMenu *)menu;
-(NSArray*)warnings:(MUMMenu *)menu;

-(void)runManagedSoftwareUpdate:(id)sender;
-(void)aboutMunkiMenu:(id)sender;
-(void)uninstallHelper:(id)sender;
@end

@interface MUMMenu : NSMenu

@property (weak) id<MUMMenuDelegate>delegate;
-(void)addAlternateItemsToMenu;
-(void)addSettingsToMenu;
-(void)addManagedInstallListToMenu;
-(void)addOptionalInstallListToMenu;
-(void)refreshAllItems;
@end
