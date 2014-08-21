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
#import "MUMHelperConnection.h"
#import "MUMAuthorizer.h"
#import "NSString(TextField)+isNotBlank.h"
#import "MUMManagedSoftwareUpdate.h"

@interface MUMController ()<MUMMenuDelegate,NSUserNotificationCenterDelegate,MUMViewControllerDelegate>
{
@private
    NSStatusItem *_statusItem;
    MUMMenuView  *_menuView;
    NSPopover    *_popover;
    
    BOOL _notificationsEnabled;
    BOOL _selfInitiatedRun;
    BOOL _setupDone;
}
@property (strong) MUMSettings *msuSettings;
@property (strong) IBOutlet MUMMenu *menu;

@end

@implementation MUMController{
    MUMConfigView *_configView;
}

-(void)awakeFromNib{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setupStatusBar)
                                                 name:MUMFinishedLaunching
                                               object:NULL];
}

-(void)dealloc{
    [self removeAllObservers];
}

#pragma mark - Setup Menu Items / Status Bar
-(void)setupStatusBar{
    _notificationsEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kMUMNotificationsEnabled];
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

    _statusItem = [[NSStatusBar systemStatusBar]statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setHighlightMode:YES];
    [_statusItem setMenu:_menu];
    
    if(!_menuView){
        _menuView = [[MUMMenuView alloc]initWithStatusItem:_statusItem andMenu:_menu];
    }
    
    _statusItem.view = _menuView;
    _menu.delegate = self;
    
    [_menu addAlternateItemsToMenu];
    
    [self addAllObservers];
    [self getSettingsFromHelper:nil];
}

-(void)setupMenu{
    [_menu refreshAllItems:_msuSettings];
    [[_menu itemWithTitle:@"Notifications"] setState:_notificationsEnabled];
    _setupDone=YES;
}

#pragma mark - Controller IBActions / Selectors
-(IBAction)runManagedSoftwareUpdate:(id)sender{
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/Utilities/Managed Software Update.app"];
}

-(void)chooseOptionalInstall:(NSMenuItem*)sender{
    if([MUMManagedSoftwareUpdate instanceIsRunning]){
        [MUMError presentErrorWithCode:kMUMErrorManagedSoftwareUpdateInstanceIsRunning delegate:self didPresentSelector:nil];
        return;
    }
    
    MUMHelperConnection *helper = [MUMHelperConnection new];
    [self msuRunStarted:[NSString stringWithFormat:@"%@ %@...",!sender.state ? @"Installing":@"Removing",sender.title]];
    
    [helper connectToHelper];
    [[helper.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"%@",error.localizedDescription);
    }] installOptionalItems:!sender.state title:sender.title withReply:^(NSError *error) {
        [self msuRunEnded];
        if(error){
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [NSApp presentError:error];
            }];
        }else{
            [self optionalItemChangedNotification:!sender.state ? YES:NO titile:sender.title success:error ? NO:YES];
            [sender setState:!sender.state];
        }
        
        // get this back on the main thread...
        [self performSelectorOnMainThread:@selector(getSettingsFromHelper:)
                               withObject:nil
                            waitUntilDone:NO];
    }];
}

-(IBAction)enableNotifications:(NSMenuItem*)sender{
    _notificationsEnabled = !_notificationsEnabled;
    [sender setState:_notificationsEnabled ? NSOnState:NSOffState];
    [[NSUserDefaults standardUserDefaults]setBool:_notificationsEnabled
                                           forKey:kMUMNotificationsEnabled];
}

-(void)quitNow:(id)sender{
    [NSApp terminate:self];
}

-(void)openLogFile:(id)sender{
    [[NSWorkspace sharedWorkspace]openFile:_msuSettings.logFile
                           withApplication:@"/Applications/Utilities/Console.app"];
}

-(void)aboutMunkiMenu:(id)sender{
    [[NSApplication sharedApplication]orderFrontStandardAboutPanel:self];
}

-(void)defaultsChanged:(id)sender{
    [_menu refreshAllItems:_msuSettings];
}

#pragma mark - Config View
-(void)openConfigView{
    // We use the popupIsActive in the AppDelegate to bridge over to
    // the canBecomeKeyWindow Catagory in order to allow the statusItemView
    // to become a key view.
    
    if(!_configView){
        _configView = [[MUMConfigView alloc]initWithNibName:@"MUMConfigView" bundle:nil];
        [_configView setDelegate:self];
    }
    
    if (_popover == nil) {
        _popover = [[NSPopover alloc] init];
        _popover.behavior = NSPopoverBehaviorTransient;
    }
    
    _popover.contentViewController = _configView;

    if (!_popover.isShown) {
        [[NSApplication sharedApplication] activateIgnoringOtherApps : YES];
        [_popover showRelativeToRect:_menuView.frame
                              ofView:_menuView
                       preferredEdge:NSMinYEdge];
    }
    
    [[NSApp delegate] setPopupIsActive:YES];
    
    // If the computer is managed using MCX there's no use editing
    // the ManagedInsalls.plist, so we won't bother adding this to the menu
    BOOL mcxManaged = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Managed Preferences/ManagedInstalls.plist"];
    
    [_configView.repoURLTF     setEnabled:!mcxManaged];
    [_configView.clientIDTF    setEnabled:!mcxManaged];
    [_configView.logFileTF     setEnabled:!mcxManaged];
    [_configView.manifestURLTF setEnabled:!mcxManaged];
    [_configView.catalogURLTF  setEnabled:!mcxManaged];
    [_configView.packageURLTF  setEnabled:!mcxManaged];
    [_configView.ASUEnabledCB  setEnabled:!mcxManaged];
    [_configView.setButton     setEnabled:!mcxManaged];
    [_configView.managedByMCX  setHidden: !mcxManaged];
    
    _configView.repoURLTF.stringValue     = _msuSettings.softwareRepoURL;
    _configView.clientIDTF.stringValue    = _msuSettings.clientIdentifier;
    _configView.logFileTF.stringValue     = _msuSettings.logFile;
    _configView.manifestURLTF.stringValue = _msuSettings.manifestURL;
    _configView.catalogURLTF.stringValue  = _msuSettings.catalogURL;
    _configView.packageURLTF.stringValue  = _msuSettings.packageURL;
    _configView.ASUEnabledCB.state        = _msuSettings.installASU;
}

-(void)closeConfigView{
    if (_popover != nil && _popover.isShown) {
        [_popover close];
    }
    
    [[NSApp delegate] setPopupIsActive:NO];

    _configView = nil;
    _popover = nil;
}

-(void)configureMunki{
    NSData *authorization = [MUMAuthorizer authorizeHelper];
    assert(authorization != nil);
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithCapacity:7];
    
    if(_configView.repoURLTF.isNotBlank){
        [dict setObject:_configView.repoURLTF.stringValue
                 forKey:kMUMSoftwareRepoURL];
    }
    if(_configView.clientIDTF.isNotBlank){
        [dict setObject:_configView.clientIDTF.stringValue
                 forKey:kMUMClientIdentifier];
    }
    if(_configView.logFileTF.isNotBlank){
        [dict setObject:_configView.logFileTF.stringValue
                 forKey:kMUMLogFile];
    }
    if(_configView.manifestURLTF.isNotBlank){
        [dict setObject:_configView.manifestURLTF.stringValue
                 forKey:kMUMManifestURL];
    }
    if(_configView.catalogURLTF.isNotBlank){
        [dict setObject:_configView.catalogURLTF.stringValue
                 forKey:kMUMCatalogURL];
    }
    if(_configView.packageURLTF.isNotBlank){
        [dict setObject:_configView.packageURLTF.stringValue
                 forKey:kMUMPackageURL];
    }
    
    [dict setObject:[NSNumber numberWithBool:_configView.ASUEnabledCB.state ]
             forKey:kMUMInstallAppleSoftwareUpdates];
    
    [self closeConfigView];
    [self msuRunStarted:@"Updating Configuration..."];
    
    MUMHelperConnection *helper = [MUMHelperConnection new];
    [helper connectToHelper];
    
    [[helper.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        [_menu refreshAllItems:_msuSettings];
        [self msuRunEnded];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [NSApp presentError:error];
        }];
    }] configureMunki:dict authorization:authorization withReply:^(MUMSettings* settings,NSError *error) {
        [self msuRunEnded];
        if(error){
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [NSApp presentError:error];
            }];
        }
        if(settings){
            _msuSettings = settings;
            [_menu refreshAllItems:settings];
        }else{
            [_menu refreshAllItems:_msuSettings];
        }
    }];
}

#pragma mark - Helper Agent (NSXPC)
-(void)getSettingsFromHelper:(NSNotification*)sender{
    // This gets the MSU details from the helper app.  We use a helper app
    // here to handle the situation where the ManagedInstall.plist is
    // in the root's ~/Library/Preferences/ folder.  Since the helper app
    // runs as root it can read the values and pass it back to us.

    // if the helper app is currently running an update
    // any info here will be obsolete so just skip it...    
    if(!_selfInitiatedRun){
        MUMHelperConnection *helper = [MUMHelperConnection new];
        [helper connectToHelper];
        [[helper.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [NSApp presentError:error];
            }];
        }] getPreferenceDictionary:^(MUMSettings *settings, NSError *error) {
            if(error){
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [NSApp presentError:error];
                }];
            }else{
                _msuSettings = settings;
                if(!_setupDone)
                    [self setupMenu];
                else
                    [_menu refreshAllItems:_msuSettings];
            }
           [[helper.connection remoteObjectProxy]quitHelper];
        }];
    }
}


-(void)uninstallHelper:(MUMMenu *)menu{
    NSData *authorization = [MUMAuthorizer authorizeHelper];
    assert(authorization != nil);
    
    // Uninstall the Helper app and launchD files, then unload the launchd job.
    // The Helper App removes the files then we call a selector on the App delegate
    // To do the SMJob Unblessing
    MUMHelperConnection *helper = [MUMHelperConnection new];
    [helper connectToHelper];
    [[helper.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [NSApp presentError:error];
        }];
    }] uninstall:[[NSBundle mainBundle] bundleURL] authorization:authorization withReply:^(NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(error){
                NSLog(@"error from helper: %@", error.localizedDescription);
            }else{
                [[NSApp delegate] performSelector:@selector(setupDidEndWithUninstallRequest) withObject:nil];
            }
        }];
    }];
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
        notification.informativeText = @"All managed software updates have been completed";
        [notification setHasActionButton:YES];
        notification.actionButtonTitle = @"Done";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

-(void)msuNeedsRunNotify:(NSNotification*)sender{
    DPrint(@"%@",sender.name);
    if(_notificationsEnabled && !_selfInitiatedRun){
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Avaliable Software Updates";
        notification.informativeText = @"There are software updates that need installed.";
        notification.soundName = nil;
        [notification setHasActionButton:YES];
        notification.actionButtonTitle = @"Install";
        notification.otherButtonTitle = @"Dismiss";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

-(void)optionalItemChangedNotification:(BOOL)installed titile:(NSString*)title success:(BOOL)success{
    if(_notificationsEnabled){
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        
        NSString* status;
        if(success)
            status = [NSString stringWithFormat:@"%@",installed ? @"Successfully installed":@"Sucessfully removed"];
        else
            status = [NSString stringWithFormat:@"%@",installed ? @"There were problems installing":@"There were problems removing"];

        [notification setHasActionButton:NO];
        notification.title = [NSString stringWithFormat:@"Finished managed %@", installed ? @"install":@"removal"];
        notification.informativeText = [NSString stringWithFormat:@"%@ %@",status,title];
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

#pragma mark - Observing/Observers
-(void)addAllObservers{
    NSDistributedNotificationCenter *nsdnc = [NSDistributedNotificationCenter defaultCenter];
    if([MUMManagedSoftwareUpdate majorVerson] == 2){
        // For Munki2
        DPrint(@"Observing For Munki2");
        [nsdnc addObserver:self selector:@selector(getSettingsFromHelper:) name:MSUUpdateEnded object:nil];
        [nsdnc addObserver:self selector:@selector(getSettingsFromHelper:) name:MSUUpdateChanged object:nil];
    }else{
        DPrint(@"Observing For Munki");
        // For Munki
        [nsdnc addObserver:self selector:@selector(getSettingsFromHelper:) name:MSUUpdate object:nil];

        // Custom Munki Build
        [nsdnc addObserver:self selector:@selector(getSettingsFromHelper:) name:MSUUpdateComplete object:nil];
        [nsdnc addObserver:self selector:@selector(msuNeedsRunNotify:) name:MSUUpdateAvaliable object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeConfigView) name:MUMClosePopover object:nil];
}

-(void)removeAllObservers{
    [[NSDistributedNotificationCenter defaultCenter]removeObserver:self];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - Self Run
-(void)msuRunStarted:(NSString*)statusMessage{
    [_menuView startAnimation];
    [_menu refreshing:statusMessage];
    _selfInitiatedRun = YES;
}

-(void)msuRunEnded{
    [_menuView stopAnimation];
    _selfInitiatedRun = NO;
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
