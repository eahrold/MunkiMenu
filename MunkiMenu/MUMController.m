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
#import "Authorizer.h"


static NSString* const MSUUpdateComplete = @"com.googlecode.munki.ManagedSoftwareUpdate.complete";
static NSString* const MSUUpdate= @"com.googlecode.munki.ManagedSoftwareUpdate.update";
static NSString* const MSUUpdateAvaliable = @"com.googlecode.munki.ManagedSoftwareUpdate.avaliableupdates";

@implementation MUMController{
    NSDictionary *msuPrefs;
    NSDictionary *msuClientManifest;
    NSDictionary *msuSelfService;
    NSDictionary *msuReport;
    NSDictionary *msuInventory;
    BOOL notificationsEnabled;
    BOOL setupDone;
}
@synthesize menu,configSheet;

-(void)awakeFromNib{
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    [menu setDelegate:self];
    [self addAllObservers];
    
    statusItem = [[NSStatusBar systemStatusBar]statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setImage:[NSImage imageNamed:@"Managed Software Update18x18"]];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:menu];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if(![defaults boolForKey:@"previouslyRun"]){
        notificationsEnabled = YES;
    }else{
        notificationsEnabled = [defaults boolForKey:@"notificationsEnabled"];
    }
 
   [[menu itemWithTitle:@"Notifications"] setState:notificationsEnabled];
}

-(void)dealloc{
    [self removeAllObservers];
}

#pragma mark - Set Menu Items
-(void)configureMenu{
    [self getMSUSettings];
    [menu addAlternateItemsToMenu];
    [menu addSettingsToMenu];
    [menu addManagedInstallListToMenu];
    [menu addOptionalInstallListToMenu];
    setupDone=YES;
}

-(void)refreshMenu{
    [self getMSUSettings];
    [menu refreshAllItems];
}

#pragma mark - IBActions
-(IBAction)runManagedSoftwareUpdate:(id)sender{
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/Utilities/Managed Software Update.app"];
}

-(IBAction)configureMunki:(id)sender{
    NSData* authorization = [self authorizeHelper];
    assert(authorization != nil);
    
    NSDictionary* newValues = @{kSoftwareRepoURL:_repoURLTF.stringValue,
                                kClientIdentifier:_clientIDTF.stringValue,
                                kLogFile:_logFileTF.stringValue,
                                kManifestURL:_manifestURLTF.stringValue,
                                kCatalogURL:_catalogURLTF.stringValue,
                                kPackageURL:_packageURLTF.stringValue,
                                kInstallAppleSoftwareUpdates:[NSNumber numberWithBool:_ASUEnabledCB.state]};
    
    [self closeConfigSheet:nil];
    
    NSXPCConnection *helperXPCConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName
                                                                                    options:NSXPCConnectionPrivileged];
    
    helperXPCConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [helperXPCConnection resume];
    
    [[helperXPCConnection remoteObjectProxy] configureMunki:newValues authorization:authorization withReply:^(NSDictionary *dict,NSError * error)
     {[[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if(error){
            NSLog(@"%@",[error localizedDescription]);
            [NSApp presentError:error];
        }else{
            msuPrefs = dict;
            [self refreshMenu];
        }
    }];
         [helperXPCConnection invalidate];
         // we don't need to keep the helper app alive so send the quit signal.
         // when needed we'll just launch it later.
         [self quitHelper];
     }];

}

-(IBAction)enableNotifications:(id)sender{
    notificationsEnabled = !notificationsEnabled;
    if(notificationsEnabled){
        [(NSMenuItem*)sender setState:NSOnState];
    }else{
        [(NSMenuItem*)sender setState:NSOffState];
    }
    [[NSUserDefaults standardUserDefaults]setBool:notificationsEnabled forKey:@"notificationsEnabled"];
}

-(void)quitNow:(id)sender{
    [NSApp terminate:self];
}

-(void)openLogFile:(id)sender{
    [[NSWorkspace sharedWorkspace]openFile:msuPrefs[@"LogFile"] withApplication:@"/Applications/Utilities/Console.app"];
}

-(void)aboutMunkiMenu:(id)sender{
    [[NSApplication sharedApplication]orderFrontStandardAboutPanel:self];
}

-(void)openConfigSheet{
    if(!configSheet){
       [NSBundle loadNibNamed:@"ConfigSheet" owner:self];
    }
    
    _repoURLTF.stringValue = msuPrefs[kSoftwareRepoURL];
    _clientIDTF.stringValue = msuPrefs[kClientIdentifier];
    _logFileTF.stringValue = msuPrefs[kLogFile];
    _manifestURLTF.stringValue = msuPrefs[kManifestURL];
    _catalogURLTF.stringValue = msuPrefs[kCatalogURL];
    _packageURLTF.stringValue = msuPrefs[kPackageURL];
    _ASUEnabledCB.state = [msuPrefs[kInstallAppleSoftwareUpdates] boolValue];

    [NSApp beginSheet:configSheet
       modalForWindow:nil
        modalDelegate:self
       didEndSelector:NULL
          contextInfo:NULL];
}

-(IBAction)closeConfigSheet:(id)sender{
    [NSApp endSheet:configSheet];
    [self.configSheet close];
    self.configSheet = nil;
}

#pragma mark - Helper Agent (NSXPC)
-(void)getMSUPlistFromHelper{
    // This gets the MSU details from the helper app.  We use a helper app
    // here to handle the situation where the ManagedInstall.plist is
    // in the root's ~/Library/Preferences/ folder.  Since the helper app
    // runs as root it can read the values and pass it back to us.
    NSXPCConnection *helperXPCConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName
                                                                                    options:NSXPCConnectionPrivileged];
    
    helperXPCConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [helperXPCConnection resume];
    
    [[helperXPCConnection remoteObjectProxy] getPreferenceDictionary:^(NSDictionary * dict, NSError * error)
     {[[NSOperationQueue mainQueue] addOperationWithBlock:^{
             if(error){
                 NSLog(@"%@",[error localizedDescription]);
                 [NSApp presentError:error];
             }else{
                 msuPrefs = dict;
                 if(!setupDone){
                     [self configureMenu];
                     [self installGlobalLogin];
                 }
             }
         }];
         [helperXPCConnection invalidate];
         // we don't need to keep the helper app alive so send the quit signal.
         // when needed we'll just launch it later.
         [self quitHelper];
     }];
}

-(void)uninstallHelper:(MUMMenu *)menu{
    NSData* authorization = [self authorizeHelper];
    assert(authorization != nil);
    
    //Uninstall the Helper app and launchD files, then unload the launchd job.
    NSXPCConnection *helperXPCConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName options:NSXPCConnectionPrivileged];
    helperXPCConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [helperXPCConnection resume];
    [[helperXPCConnection remoteObjectProxy] uninstall:[[NSBundle mainBundle] bundleURL] authorization:authorization withReply:^(NSError *error) {
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

-(void)installGlobalLogin{
    NSXPCConnection *helperXPCConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName options:NSXPCConnectionPrivileged];
    helperXPCConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [helperXPCConnection resume];
    [[helperXPCConnection remoteObjectProxy] installGlobalLoginItem:[[NSBundle mainBundle]bundleURL] withReply:^(NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(error){
                NSLog(@"%@",error.localizedDescription);
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
        notification.soundName = NSUserNotificationDefaultSoundName;
        [notification setHasActionButton:YES];
        notification.actionButtonTitle = @"Install";
        notification.otherButtonTitle = @"Dismiss";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

#pragma mark - Observing/Observers
-(void)addAllObservers{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getMSUPlistFromHelper) name:MUMFinishedLaunching object:NULL];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMenu) name:MSUUpdate object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMenu) name:MSUUpdateComplete object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(msuNeedsRunNotify) name:MSUUpdateAvaliable object:nil];
}

-(void)removeAllObservers{
    [[NSDistributedNotificationCenter defaultCenter]removeObserver:self];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}


#pragma mark - utils
-(void)getMSUSettings{
    NSString* msuDir = msuPrefs[kManagedInstallDir];
    if(!msuDir)return;
    
    NSString *manifest = [NSString stringWithFormat:@"%@/manifests/client_manifest.plist",msuDir];
    msuClientManifest = [NSDictionary dictionaryWithContentsOfFile:manifest];

    NSString *inventory = [NSString stringWithFormat:@"%@/ApplicationInventory.plist",msuDir];
    msuInventory = [NSDictionary dictionaryWithContentsOfFile:inventory];

    NSString *reports = [NSString stringWithFormat:@"%@/ManagedInstallReport.plist",msuDir];
    msuReport = [NSDictionary dictionaryWithContentsOfFile:reports];

    NSString *ssinfo = [NSString stringWithFormat:@"%@/manifests/SelfServeManifest",msuDir];
    msuSelfService = [NSDictionary dictionaryWithContentsOfFile:ssinfo];
}

-(NSData*)authorizeHelper{
    //TODO:  Pass AuthRef to helper external form
    OSStatus                    err;
    AuthorizationExternalForm   extForm;
    AuthorizationRef            authRef;
    NSData*                     authorization;
    // cause all authorized operations to fail.
    
    err = AuthorizationCreate(NULL, NULL, 0, &authRef);
    if (err == errAuthorizationSuccess) {
        err = AuthorizationMakeExternalForm(authRef, &extForm);
    }
    if (err == errAuthorizationSuccess) {
        authorization = [[NSData alloc] initWithBytes:&extForm length:sizeof(extForm)];
    }
    assert(err == errAuthorizationSuccess);
    
    // If we successfully connected to Authorization Services, add definitions for our default
    // rights (unless they're already in the database).
    
    if (authRef) {
        [Authorizer setupAuthorizationRights:authRef];
    }
    return authorization;
}

#pragma mark - Menu Delegate
-(NSString*)repoURL:(MUMMenu*)menu{
    return msuPrefs[kSoftwareRepoURL];
}

-(NSString*)manifestURL:(MUMMenu *)menu{
    return msuPrefs[kManifestURL];
}

-(NSString*)catalogURL:(MUMMenu *)menu{
    return msuPrefs[kCatalogURL];
}

-(NSString*)packageURL:(MUMMenu*)menu{
    return msuPrefs[kPackageURL];
}

-(NSString *)clientIdentifier:(MUMMenu *)menu{
    return msuPrefs[kClientIdentifier];
}

-(NSString*)logFile:(MUMMenu *)menu{
    return msuPrefs[kLogFile];
}

-(NSArray *)avaliableUpdates:(MUMMenu *)menu{
    return msuClientManifest[@"managed_installs"];
}

-(NSArray *)managedInstalls:(MUMMenu *)menu{
    return msuClientManifest[@"managed_installs"];
}

-(NSArray*)processedInstalls:(MUMMenu *)menu{
    return msuClientManifest[@"processed_installs"];
}

-(NSArray*)optionalInstalls:(MUMMenu *)menu{
    // We need to check the client manifest against the SelfService file
    // to determing which of the optional installs are actually installed
    NSMutableArray *array = [NSMutableArray new];
    for(NSString* item in msuClientManifest[@"optional_installs"]){
        if([msuSelfService[@"managed_installs"] containsObject:item]){
            [array addObject:@{@"item":item,@"installed":@YES}];
        }else{
            [array addObject:@{@"item":item,@"installed":@NO}];
        }
    }
    return array;
}

-(NSArray *)installedItems:(MUMMenu *)menu{
    return msuReport[@"InstalledItems"];
}

-(NSArray *)itemsToInstall:(MUMMenu *)menu{
    return msuReport[@"ItemsToInstall"];
}

-(NSArray *)itemsToRemove:(MUMMenu *)menu{
    return msuReport[@"ItemsToRemove"];
}

-(NSArray *)warnings:(MUMMenu *)menu{
    return msuReport[@"Warnings"];
}


@end
