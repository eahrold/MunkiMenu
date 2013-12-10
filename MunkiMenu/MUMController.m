//
//  MUMController.m
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMController.h"
#import "MUMHelper.h"
#import "MUMInterface.h"
#import "MUMDelegate.h"
#import "MUMMenuView.h"

#import "Authorizer.h"

@implementation MUMController{
    MSUSettings *msuSettings;
    MUMMenuView* menuView;
    MUMConfigView* configView;

    NSPopover *popover;
    BOOL notificationsEnabled;
    BOOL setupDone;
}

@synthesize menu;

-(void)awakeFromNib{
    // We don't want to do too much here, because the MUMController is the file owner of
    // the Config View and everything here gets reloaded
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureStatusBar) name:MUMFinishedLaunching object:NULL];
}

-(void)dealloc{
    [self removeAllObservers];
}

#pragma mark - Setup Menu Items / Status Bar
-(void)configureStatusBar{
    notificationsEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kNotificationsEnabled];
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

    statusItem = [[NSStatusBar systemStatusBar]statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setImage:[NSImage imageNamed:@"Managed Software Update18x18"]];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:menu];
    
    if(!menuView){
        menuView = [[MUMMenuView alloc]initWithStatusItem:statusItem andMenu:menu];
    }
    
    statusItem.view = menuView;
    
    [self addAllObservers];
    [self getMSUSettingsFromHelper];
}

-(void)configureMenu{
    [menu setDelegate:self];
    [menu addAlternateItemsToMenu];
    [menu addSettingsToMenu];
    [menu addManagedInstallListToMenu];
    [menu addOptionalInstallListToMenu];
    [menu addItemsToInstallListToMenu];
    [menu addItemsToRemoveListToMenu];
    [menu addManagedUpdateListToMenu];
    [[menu itemWithTitle:@"Notifications"] setState:notificationsEnabled];
    setupDone=YES;
}

-(void)refreshMenu{
    [self getMSUSettingsFromHelper];
}

-(void)defaultsChanged:(id)sender{
    [menu refreshAllItems];
}

#pragma mark - Controller IBActions / Selectors
-(IBAction)runManagedSoftwareUpdate:(id)sender{
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/Utilities/Managed Software Update.app"];
}

-(IBAction)enableNotifications:(id)sender{
    notificationsEnabled = !notificationsEnabled;
    if(notificationsEnabled){
        [(NSMenuItem*)sender setState:NSOnState];
    }else{
        [(NSMenuItem*)sender setState:NSOffState];
    }
    [[NSUserDefaults standardUserDefaults]setBool:notificationsEnabled forKey:kNotificationsEnabled];
}

-(void)quitNow:(id)sender{
    [NSApp terminate:self];
}

-(void)openLogFile:(id)sender{
    [[NSWorkspace sharedWorkspace]openFile:msuSettings.logFile withApplication:@"/Applications/Utilities/Console.app"];
}

-(void)aboutMunkiMenu:(id)sender{
    [[NSApplication sharedApplication]orderFrontStandardAboutPanel:self];
}

#pragma mark - Config View
-(void)openConfigView{
    if(!configView){
        configView = [[MUMConfigView alloc]initWithNibName:@"MUMConfigView" bundle:nil];
        [configView setDelegate:self];
    }
    
    if (popover == nil) {
        popover = [[NSPopover alloc] init];
        popover.contentViewController = configView;
    }
    
    
    if (!popover.isShown) {
        [popover showRelativeToRect:menuView.frame
                              ofView:menuView
                       preferredEdge:NSMinYEdge];
    }
    
    // If the computer is managed using MCX there's no use editing
    // the ManagedInsalls.plist, so we won't bother adding this to the menu
    BOOL mcxManaged = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Managed Preferences/ManagedInstalls.plist"];
    
    if(mcxManaged){
        [configView.repoURLTF setEnabled:NO];
        [configView.clientIDTF setEnabled:NO];
        [configView.logFileTF setEnabled:NO];
        [configView.manifestURLTF setEnabled:NO];
        [configView.catalogURLTF setEnabled:NO];
        [configView.packageURLTF setEnabled:NO];
        [configView.ASUEnabledCB setEnabled:NO];
        [configView.setButton setEnabled:NO];
        [configView.managedByMCX setHidden:NO];
    }
    
    configView.repoURLTF.stringValue = msuSettings.softwareRepoURL;
    configView.clientIDTF.stringValue = msuSettings.clientIdentifier;
    configView.logFileTF.stringValue = msuSettings.logFile;
    configView.manifestURLTF.stringValue = msuSettings.manifestURL;
    configView.catalogURLTF.stringValue = msuSettings.catalogURL;
    configView.packageURLTF.stringValue = msuSettings.packageURL;
    configView.ASUEnabledCB.state = msuSettings.installASU;
}

-(void)closeConfigView{
    if (popover != nil && popover.isShown) {
        [popover close];
    }
    
    configView = nil;
}

-(void)configureMunki{
    NSData* authorization = [self authorizeHelper];
    assert(authorization != nil);
    
    msuSettings.softwareRepoURL  = configView.repoURLTF.stringValue;
    msuSettings.clientIdentifier = configView.clientIDTF.stringValue;
    msuSettings.logFile          = configView.logFileTF.stringValue;
    msuSettings.manifestURL      = configView.manifestURLTF.stringValue;
    msuSettings.catalogURL       = configView.catalogURLTF.stringValue;
    msuSettings.packageURL       = configView.packageURLTF.stringValue;
    msuSettings.installASU       = configView.ASUEnabledCB.state;
    
    [self closeConfigView];
    
    NSXPCConnection *helperXPCConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName
                                                                                    options:NSXPCConnectionPrivileged];
    
    helperXPCConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [helperXPCConnection resume];
    
    [[helperXPCConnection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"MSU Configuration Error: %@",error.localizedDescription);
    }] configureMunki:msuSettings authorization:authorization withReply:^(NSError * error)
     {[[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if(error){
            NSLog(@"%@",[error localizedDescription]);
            [NSApp presentError:error];
        }else{
            [menu refreshing];
        }
    }];
         [helperXPCConnection invalidate];
         // we don't need to keep the helper app alive so send the quit signal.
         // when needed we'll just launch it later.
         [self quitHelper];
     }];
    

}

#pragma mark - Helper Agent (NSXPC)
-(void)getMSUSettingsFromHelper{
    // This gets the MSU details from the helper app.  We use a helper app
    // here to handle the situation where the ManagedInstall.plist is
    // in the root's ~/Library/Preferences/ folder.  Since the helper app
    // runs as root it can read the values and pass it back to us.
    NSXPCConnection *helperXPCConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName
                                                                                    options:NSXPCConnectionPrivileged];
    
    helperXPCConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [helperXPCConnection resume];
    
    [[helperXPCConnection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"%@",[error localizedDescription]);
    }] getPreferenceDictionary:^(MSUSettings * settings, NSError * error)
     {[[NSOperationQueue mainQueue] addOperationWithBlock:^{
             if(error){
                 NSLog(@"%@",[error localizedDescription]);
                 [NSApp presentError:error];
             }else{
                 msuSettings = settings;
                 if(!setupDone){
                     [self configureMenu];
                     [self installGlobalLogin];
                 }else{
                     [menu refreshAllItems];
                 }
             }
         }];
         [helperXPCConnection invalidate];
         // we don't need to keep the helper app alive so send the quit signal.
         // when needed we'll just launch it later.
       [self quitHelper];
     }];
}


-(void)installGlobalLogin{
    NSXPCConnection *helperXPCConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName options:NSXPCConnectionPrivileged];
    helperXPCConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [helperXPCConnection resume];
    [[helperXPCConnection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"%@",[error localizedDescription]);
    }] installGlobalLoginItem:[[NSBundle mainBundle]bundleURL] withReply:^(NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(error){
                NSLog(@"%@",error.localizedDescription);
            }
        }];
        [helperXPCConnection invalidate];
    }];
}

-(void)uninstallHelper:(MUMMenu *)menu{
    NSData* authorization = [self authorizeHelper];
    assert(authorization != nil);
    
    // Uninstall the Helper app and launchD files, then unload the launchd job.
    // The Helper App removes the files then we call a selector on the App delegate
    // To do the SMJob Unblessing
    NSXPCConnection *helperXPCConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName options:NSXPCConnectionPrivileged];
    helperXPCConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [helperXPCConnection resume];
    [[helperXPCConnection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"%@",[error localizedDescription]);
    }] uninstall:[[NSBundle mainBundle] bundleURL] authorization:authorization withReply:^(NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(error){
                NSLog(@"error from helper: %@", error.localizedDescription);
            }else{
                [[NSApp delegate] performSelector:@selector(setupDidEndWithUninstallRequest) withObject:nil];
            }
        }];
        [helperXPCConnection invalidate];
    }];
}

-(void)quitHelper{
    NSXPCConnection *helperXPCConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName options:NSXPCConnectionPrivileged];
    helperXPCConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [helperXPCConnection resume];
    [[helperXPCConnection remoteObjectProxy] quitHelper];
}



#pragma mark - UserNotifications Delegate/Methods
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if([notification.actionButtonTitle isEqualToString:@"Install"]){
        [self runManagedSoftwareUpdate:nil];
    }
    [center removeDeliveredNotification:notification];
}

#pragma mark -
-(void)msuCompletNotify{
    if(notificationsEnabled){
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Updates Complete!";
        notification.informativeText = [NSString stringWithFormat:@"All managed software updates have been completed"];
        [notification setHasActionButton:YES];
        notification.actionButtonTitle = @"Done";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

-(void)msuNeedsRunNotify{
    if(notificationsEnabled){
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Avaliable Software Updates";
        notification.informativeText = [NSString stringWithFormat:@"There are software updates that need installed."];
        notification.soundName = nil;
        [notification setHasActionButton:YES];
        notification.actionButtonTitle = @"Install";
        notification.otherButtonTitle = @"Dismiss";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

#pragma mark - Observing/Observers
-(void)addAllObservers{
    NSDistributedNotificationCenter *dndc = [NSDistributedNotificationCenter defaultCenter];
    [dndc addObserver:self selector:@selector(refreshMenu) name:MSUUpdate object:nil];
    [dndc addObserver:self selector:@selector(refreshMenu) name:MSUUpdateComplete object:nil];
    [dndc addObserver:self selector:@selector(msuNeedsRunNotify) name:MSUUpdateAvaliable object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
}

-(void)removeAllObservers{
    [[NSDistributedNotificationCenter defaultCenter]removeObserver:self];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    NSLog(@"%@",keyPath);
}

#pragma mark - utils

-(NSData*)authorizeHelper{
    OSStatus                    err;
    AuthorizationExternalForm   extForm;
    AuthorizationRef            authRef;
    NSData*                     authorization;
    
    err = AuthorizationCreate(NULL, NULL, 0, &authRef);
    if (err == errAuthorizationSuccess) {
        err = AuthorizationMakeExternalForm(authRef, &extForm);
    }
    if (err == errAuthorizationSuccess) {
        authorization = [[NSData alloc] initWithBytes:&extForm length:sizeof(extForm)];
    }
    assert(err == errAuthorizationSuccess);
    
    if (authRef) {
        [Authorizer setupAuthorizationRights:authRef];
    }
    return authorization;
}

#pragma mark - Menu Delegate
-(NSString*)repoURL:(MUMMenu*)menu{
    return msuSettings.softwareRepoURL;
}

-(NSString*)manifestURL:(MUMMenu *)menu{
    return msuSettings.manifestURL;
}

-(NSString*)catalogURL:(MUMMenu *)menu{
    return msuSettings.catalogURL;
}

-(NSString*)packageURL:(MUMMenu*)menu{
    return msuSettings.packageURL;
}

-(NSString *)clientIdentifier:(MUMMenu *)menu{
    return msuSettings.clientIdentifier;
}

-(NSString*)logFile:(MUMMenu *)menu{
    return msuSettings.logFile;
}

-(NSArray *)managedInstalls:(MUMMenu *)menu{
    return msuSettings.managedInstalls;
}

-(NSArray *)managedUpdates:(MUMMenu *)menu{
    return msuSettings.managedUpdates;
}

-(NSArray*)managedUninstalls:(MUMMenu*)menu{
    return msuSettings.managedUninstalls;
}

-(NSArray*)processedInstalls:(MUMMenu *)menu{
    return msuSettings.processedInstalls;
}

-(NSArray*)optionalInstalls:(MUMMenu *)menu{
   return msuSettings.optionalInstalls;
}

-(NSArray *)installedItems:(MUMMenu *)menu{
    return msuSettings.installedItems;
}

-(NSArray *)itemsToInstall:(MUMMenu *)menu{
    return msuSettings.itemsToInstall;
}

-(NSArray *)itemsToRemove:(MUMMenu *)menu{
    return msuSettings.itemsToRemove;
}

-(NSArray *)warnings:(MUMMenu *)menu{
    return msuSettings.msuWarnings;
}

#pragma mark - NSMenuDelegate
- (void)menuDidClose:(NSMenu *)menu
{
    [menuView setActive:NO];
}


@end
