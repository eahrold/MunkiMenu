//
//  MUMMenu.h
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MUMMenu, MUMController, MUMSettings;

@protocol MUMMenuDelegate <NSObject,NSMenuDelegate>
-(IBAction)runManagedSoftwareUpdate:(id)sender;
-(void)chooseOptionalInstall:(NSMenuItem*)sender;
-(void)openLogFile:(id)sender;
-(void)uninstallHelper:(id)sender;
-(void)quitNow:(id)sender;
-(void)openConfigView;
@end

@interface MUMMenu : NSMenu

@property (weak) id<MUMMenuDelegate>delegate;
-(void)addAlternateItemsToMenu;
-(void)addSettingsToMenu:(MUMSettings*)settings;
-(void)addManagedInstallListToMenu:(MUMSettings*)settings;
-(void)addOptionalInstallListToMenu:(MUMSettings*)settings;
-(void)addItemsToInstallListToMenu:(MUMSettings*)settings;
-(void)addItemsToRemoveListToMenu:(MUMSettings*)settings;
-(void)addManagedUpdateListToMenu:(MUMSettings*)settings;
-(void)refreshAllItems:(MUMSettings*)settings;
-(void)refreshing:(NSString*)title;
@end
