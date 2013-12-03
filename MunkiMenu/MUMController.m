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
#import "SMJobBlesser.h"
#import "MUMDelegate.h"

static NSString* const MSUUpdate = @"com.googlecode.munki.ManagedSoftwareUpdate.complete";
static NSString* const MSUUpdateComplete = @"com.googlecode.munki.ManagedSoftwareUpdate.update";
static NSString* const MSUUpdateAvaliable = @"com.googlecode.munki.ManagedSoftwareUpdate.avaliableupdates";

@implementation MUMController{
    NSDictionary *msuPrefs;
    NSDictionary *msuClientManifest;
    NSDictionary *msuSelfService;
    NSDictionary *msuReport;
    NSDictionary *msuInventory;
    AuthorizationRef _authRef;
    BOOL setupDone;
}
@synthesize menu;

-(void)awakeFromNib{
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    [menu setDelegate:self];
    [self addAllObservers];
    
    statusItem = [[NSStatusBar systemStatusBar]statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setImage:[NSImage imageNamed:@"Managed Software Update18x18"]];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:menu];    
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


-(IBAction)quitNow:(id)sender{
    [NSApp terminate:self];
}

-(void)aboutMunkiMenu:(id)sender{
    [[NSApplication sharedApplication]orderFrontStandardAboutPanel:self];
}

#pragma mark - NSXPC
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
                 }
             }
         }];
         [helperXPCConnection invalidate];
     }];
}

-(void)uninstallHelper:(MUMMenu *)menu{
    //Uninstall the Helper app and launchD files, then unload the launchd job.
    NSXPCConnection *helperXPCConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperName options:NSXPCConnectionPrivileged];
    
    helperXPCConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    [helperXPCConnection resume];
    
    [[helperXPCConnection remoteObjectProxy] uninstall:^(NSError * error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        if(error){
            NSLog(@"error: %@", error.localizedDescription);
        }else{
            [JobBlesser removeHelperWithLabel:kHelperName];
                [NSApp presentError:[NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Helper Tool and associated files have been removed.  You can safely remove MunkiMenu from the Applications folder.  We will now quit"}] modalForWindow:NULL delegate:[NSApp delegate]
                 didPresentSelector:@selector(setupDidEndWithTerminalError:) contextInfo:nil];
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
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Updates Complete!";
    notification.informativeText = [NSString stringWithFormat:@"All managed software updates have been completed"];
    [notification setHasActionButton:YES];
    notification.actionButtonTitle = @"Thanks";
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

-(void)msuNeedsRunNotify{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Avaliable Software Updates";
    notification.informativeText = [NSString stringWithFormat:@"There are software updates that need installed."];
    notification.soundName = NSUserNotificationDefaultSoundName;
    [notification setHasActionButton:YES];
    notification.actionButtonTitle = @"Install";
    notification.otherButtonTitle = @"Dismiss";
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
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
    NSString* msuDir = msuPrefs[@"ManagedInstallDir"];
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

-(BOOL)authorizeHelper{
    NSLog(@"Authorizing");
    AuthorizationRef authRef = NULL;
	AuthorizationItem authItem		= { kAuthorizationRuleAuthenticateAsAdmin, 0, NULL, 0 };
	AuthorizationRights authRights	= { 1, &authItem };
    AuthorizationEnvironment environment = {0, NULL};
    
    AuthorizationFlags authFlags =  kAuthorizationFlagDefaults              |
                                    kAuthorizationFlagInteractionAllowed    |
                                    kAuthorizationFlagPreAuthorize          |
                                    kAuthorizationFlagExtendRights;
        
    OSStatus status = AuthorizationCreate(&authRights, &environment, authFlags, &authRef);
    if (status != errAuthorizationSuccess){
        NSLog(@"Not Authorized");
        return NO;
    }
    return YES;
}

#pragma mark - Menu Delegate
-(NSString*)repoURL:(MUMMenu*)menu{
    return msuPrefs[@"SoftwareRepoURL"];
}

-(NSString*)manifestURL:(MUMMenu *)menu{
    return msuPrefs[@"ManifestURL"];
}

-(NSString *)catalogURL:(MUMMenu *)menu{
    return msuPrefs[@"CatalogURL"];
}

-(NSString*)packageURL:(MUMMenu*)menu{
    return msuPrefs[@"PackageURL"];
}

-(NSString *)clientIdentifier:(MUMMenu *)menu{
    return msuPrefs[@"ClientIdentifier"];
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
    // We need to check the ManagedInstall's info against the self service
    //  to determing what's installed
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
