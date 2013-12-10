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
@interface MUMController ()
{
@private
    NSStatusItem* _statusItem;
    MSUSettings *_msuSettings;
    MUMMenuView* _menuView;
    
    NSPopover *_popover;
    BOOL _notificationsEnabled;
    BOOL _setupDone;
}
@end

@implementation MUMController{
    MUMConfigView* _configView;
}

@synthesize menu;

-(void)awakeFromNib{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureStatusBar) name:MUMFinishedLaunching object:NULL];
}

-(void)dealloc{
    [self removeAllObservers];
}

#pragma mark - Setup Menu Items / Status Bar
-(void)configureStatusBar{
    _notificationsEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kNotificationsEnabled];
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

    _statusItem = [[NSStatusBar systemStatusBar]statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setHighlightMode:YES];
    [_statusItem setMenu:menu];
    
    if(!_menuView){
        _menuView = [[MUMMenuView alloc]initWithStatusItem:_statusItem andMenu:menu];
    }
    
    _statusItem.view = _menuView;
    
    [menu setDelegate:self];
    [menu addAlternateItemsToMenu];
    
    [self addAllObservers];
    [self getMSUSettingsFromHelper];
}

-(void)configureMenu{
    [menu addSettingsToMenu];
    [menu addManagedInstallListToMenu];
    [menu addOptionalInstallListToMenu];
    [menu addItemsToInstallListToMenu];
    [menu addItemsToRemoveListToMenu];
    [menu addManagedUpdateListToMenu];
    [[menu itemWithTitle:@"Notifications"] setState:_notificationsEnabled];
    _setupDone=YES;
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
    _notificationsEnabled = !_notificationsEnabled;
    [(NSMenuItem*)sender setState:_notificationsEnabled ? NSOnState:NSOffState];
    [[NSUserDefaults standardUserDefaults]setBool:_notificationsEnabled forKey:kNotificationsEnabled];
}

-(void)quitNow:(id)sender{
    [NSApp terminate:self];
}

-(void)openLogFile:(id)sender{
    [[NSWorkspace sharedWorkspace]openFile:_msuSettings.logFile withApplication:@"/Applications/Utilities/Console.app"];
}

-(void)aboutMunkiMenu:(id)sender{
    [[NSApplication sharedApplication]orderFrontStandardAboutPanel:self];
}

#pragma mark - Config View
-(void)openConfigView{
    // We use the popupIsActive in the AppDelegate to bridge over to
    // the canBecomeKeyWindow Catagory in order to allow the statudItemView
    // to become a key view.
    
    if(!_configView){
        _configView = [[MUMConfigView alloc]initWithNibName:@"MUMConfigView" bundle:nil];
        [_configView setDelegate:self];
    }
    
    if (_popover == nil) {
        _popover = [[NSPopover alloc] init];
        _popover.contentViewController = _configView;
    }
    
    
    if (!_popover.isShown) {
        [_popover showRelativeToRect:_menuView.frame
                              ofView:_menuView
                       preferredEdge:NSMinYEdge];
    }
    ((MUMDelegate*)[NSApp delegate]).popupIsActive = YES;

    
    // If the computer is managed using MCX there's no use editing
    // the ManagedInsalls.plist, so we won't bother adding this to the menu
    BOOL mcxManaged = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Managed Preferences/ManagedInstalls.plist"];
    
    if(mcxManaged){
        [_configView.repoURLTF setEnabled:NO];
        [_configView.clientIDTF setEnabled:NO];
        [_configView.logFileTF setEnabled:NO];
        [_configView.manifestURLTF setEnabled:NO];
        [_configView.catalogURLTF setEnabled:NO];
        [_configView.packageURLTF setEnabled:NO];
        [_configView.ASUEnabledCB setEnabled:NO];
        [_configView.setButton setEnabled:NO];
        [_configView.managedByMCX setHidden:NO];
    }
    
    _configView.repoURLTF.stringValue = _msuSettings.softwareRepoURL;
    _configView.clientIDTF.stringValue = _msuSettings.clientIdentifier;
    _configView.logFileTF.stringValue = _msuSettings.logFile;
    _configView.manifestURLTF.stringValue = _msuSettings.manifestURL;
    _configView.catalogURLTF.stringValue = _msuSettings.catalogURL;
    _configView.packageURLTF.stringValue = _msuSettings.packageURL;
    _configView.ASUEnabledCB.state = _msuSettings.installASU;
}

-(void)closeConfigView{
    if (_popover != nil && _popover.isShown) {
        [_popover close];
    }
    
    ((MUMDelegate*)[NSApp delegate]).popupIsActive = NO;

    _configView = nil;
}

-(void)configureMunki{
    NSData* authorization = [self authorizeHelper];
    assert(authorization != nil);
    
    _msuSettings.softwareRepoURL  = _configView.repoURLTF.stringValue;
    _msuSettings.clientIdentifier = _configView.clientIDTF.stringValue;
    _msuSettings.logFile          = _configView.logFileTF.stringValue;
    _msuSettings.manifestURL      = _configView.manifestURLTF.stringValue;
    _msuSettings.catalogURL       = _configView.catalogURLTF.stringValue;
    _msuSettings.packageURL       = _configView.packageURLTF.stringValue;
    _msuSettings.installASU       = _configView.ASUEnabledCB.state;
    
    [self closeConfigView];
    
    NSXPCConnection *helperXPCConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName
                                                                                    options:NSXPCConnectionPrivileged];
    
    helperXPCConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [helperXPCConnection resume];
    
    [[helperXPCConnection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"MSU Configuration Error: %@",error.localizedDescription);
    }] configureMunki:_msuSettings authorization:authorization withReply:^(NSError * error)
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
                 _msuSettings = settings;
                 if(!_setupDone){
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
    if(_notificationsEnabled){
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Updates Complete!";
        notification.informativeText = [NSString stringWithFormat:@"All managed software updates have been completed"];
        [notification setHasActionButton:YES];
        notification.actionButtonTitle = @"Done";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

-(void)msuNeedsRunNotify{
    if(_notificationsEnabled){
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
    return _msuSettings.softwareRepoURL;
}

-(NSString*)manifestURL:(MUMMenu *)menu{
    return _msuSettings.manifestURL;
}

-(NSString*)catalogURL:(MUMMenu *)menu{
    return _msuSettings.catalogURL;
}

-(NSString*)packageURL:(MUMMenu*)menu{
    return _msuSettings.packageURL;
}

-(NSString *)clientIdentifier:(MUMMenu *)menu{
    return _msuSettings.clientIdentifier;
}

-(NSString*)logFile:(MUMMenu *)menu{
    return _msuSettings.logFile;
}

-(NSArray *)managedInstalls:(MUMMenu *)menu{
    return _msuSettings.managedInstalls;
}

-(NSArray *)managedUpdates:(MUMMenu *)menu{
    return _msuSettings.managedUpdates;
}

-(NSArray*)managedUninstalls:(MUMMenu*)menu{
    return _msuSettings.managedUninstalls;
}

-(NSArray*)processedInstalls:(MUMMenu *)menu{
    return _msuSettings.processedInstalls;
}

-(NSArray*)optionalInstalls:(MUMMenu *)menu{
   return _msuSettings.optionalInstalls;
}

-(NSArray *)installedItems:(MUMMenu *)menu{
    return _msuSettings.installedItems;
}

-(NSArray *)itemsToInstall:(MUMMenu *)menu{
    return _msuSettings.itemsToInstall;
}

-(NSArray *)itemsToRemove:(MUMMenu *)menu{
    return _msuSettings.itemsToRemove;
}

-(NSArray *)warnings:(MUMMenu *)menu{
    return _msuSettings.msuWarnings;
}

#pragma mark - NSMenuDelegate
- (void)menuDidClose:(NSMenu *)menu
{
    [_menuView setActive:NO];
}

#pragma mark - ConfigView Delegate
-(BOOL)popoverIsShown{
    return _popover.isShown;
}

@end
