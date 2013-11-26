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
-(NSString*)managedSoftwareUpdateURL:(MUMMenu*)menu;
-(NSString*)manifestName:(MUMMenu *)menu;
-(NSArray*)avaliableUpdates:(MUMMenu*)menu;
-(NSArray*)optionalInstalls:(MUMMenu *)menu;
-(NSArray*)processedInstalls:(MUMMenu *)menu;
-(NSArray*)installedItems:(MUMMenu *)menu;
-(NSArray*)itemsToInstall:(MUMMenu *)menu;
-(NSArray*)itemsToRemove:(MUMMenu *)menu;
-(NSArray*)warnings:(MUMMenu *)menu;
@end

@interface MUMMenu : NSMenu

@property (weak) id<MUMMenuDelegate>delegate;
-(void)addInfoToMenu;
-(void)addManagedInstallListToMenu;
-(void)addOptionalInstallListToMenu;
@end
