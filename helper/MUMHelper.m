//
//  MUMHelper.m
//  MunkiMenu
//
//  Created by Eldon on 11/28/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMHelper.h"
#import "MUMAuthorizer.h"
#import "AHLaunchCtl.h"

static NSString *const MSUAppPreferences = @"ManagedInstalls";
static const NSTimeInterval kHelperCheckInterval = 1.0; // how often to check whether to quit

@interface MUMHelper () <MUMHelperAgent,NSXPCListenerDelegate>
@property (atomic, strong, readwrite) NSXPCListener   *listener;
@property (weak)                      NSXPCConnection *connection;
@property (nonatomic, assign)         BOOL             helperToolShouldQuit;
@end

@implementation MUMHelper

-(id)init{
    self = [super init];
    if(self){
        self->_listener = [[NSXPCListener alloc] initWithMachServiceName:kMUMHelperName];
        self->_listener.delegate = self;
    }
    return self;
}

-(void)run{
    [self.listener resume];
    while (!self.helperToolShouldQuit)
    {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kHelperCheckInterval]];
    }
}

#pragma mark - ManagedInstall.plist Methods

-(void)getPreferenceDictionary:(void (^)(MUMSettings *, NSError *))reply{
    NSError *error;
    MUMSettings *settings = [MUMSettings new];
    
    settings.managedInstallDir = [self stringFromCFPref:kMUMManagedInstallDir];

    NSString *reports = [NSString stringWithFormat:@"%@/ManagedInstallReport.plist",settings.managedInstallDir];
    NSDictionary *msuReport = [NSDictionary dictionaryWithContentsOfFile:reports];
    
    NSString *info = [NSString stringWithFormat:@"%@/InstallInfo.plist",settings.managedInstallDir];
    NSDictionary *msuInstallInfo = [NSDictionary dictionaryWithContentsOfFile:info];
  
    // Set up a dictionary of with BOOL values for the Optional Install items
    NSMutableArray *msuOptionalInstalls = [NSMutableArray new];
    for(NSDictionary *dict in msuInstallInfo[kMUMOptionalInstalls]){
        [msuOptionalInstalls addObject:@{@"item":dict[@"name"],@"installed":dict[@"installed"]}];
    }
    
    // Pull out the name of the item to install from the dictionary
    NSMutableSet *itemsToInstall = [NSMutableSet new];
    for(NSDictionary *dict in msuReport[kMUMItemsToInstall]){
        [itemsToInstall addObject:dict[@"name"]];
    }
    
    // Pull out the name of the item to remove from the dictionary
    NSMutableSet *itemsToRemove  = [NSMutableSet new];
    for(NSDictionary *dict in msuReport[kMUMItemsToRemove]){
        [itemsToRemove addObject:dict[@"name"]];
    }
    
    settings.softwareRepoURL    = [self stringFromCFPref:kMUMSoftwareRepoURL];
    settings.manifestURL        = [self stringFromCFPref:kMUMManifestURL];
    settings.catalogURL         = [self stringFromCFPref:kMUMCatalogURL];
    settings.packageURL         = [self stringFromCFPref:kMUMPackageURL];
    settings.logFile            = [self stringFromCFPref:kMUMLogFile];
    settings.clientIdentifier   = [self stringFromCFPref:kMUMClientIdentifier];
    
    settings.managedInstalls    = msuReport[kMUMManagedInstalls];
    settings.managedUpdates     = msuReport[kMUMManagedUpdates];
    settings.managedUninstalls  = msuReport[kMUMManagedUninstalls];
    
    settings.installedItems     = msuReport[kMUMInstalledItems];
    settings.msuWarnings        = msuReport[kMUMMSUWarnings];
    settings.processedInstalls  = msuInstallInfo[kMUMProcessedInstalls];

    settings.optionalInstalls   = msuOptionalInstalls;

    settings.itemsToInstall     = [itemsToInstall allObjects];
    settings.itemsToRemove      = [itemsToRemove allObjects];
    
    settings.installASU         = [[self stringFromCFPref:kMUMInstallAppleSoftwareUpdates]boolValue];

    if(!settings)error = [NSError errorWithDomain:kMUMHelperName
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey:@"Therer were problems getting the preferences for Managed Software Update."}];
    reply(settings,error);
}

-(void)configureMunki:(NSDictionary*)settings authorization:(NSData*)authData withReply:(void (^)(NSError*))reply{
    NSError *error;
    
    error = [MUMAuthorizer checkAuthorization:authData command:_cmd];
    if(error != nil){
        reply(error);
        return;
    }
    
    [[NSUserDefaults standardUserDefaults]setPersistentDomain:settings forName:MSUAppPreferences];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
    NSTask *task = [NSTask new];
    [task setLaunchPath:@"/usr/local/munki/managedsoftwareupdate"];
    
    // use --munkipkgsonly here for to help speed things up...
    [task setArguments:@[@"--checkonly",@"--munkipkgsonly"]];
    [task launch];
    
    reply(error);
}

#pragma mark - Clean Up
-(void)uninstall:(NSURL*)mainAppURL authorization:(NSData*)authData withReply:(void (^)(NSError*))reply{
    NSError *error;
    
    error = [MUMAuthorizer checkAuthorization:authData command:_cmd];
    reply(error);
    if(error == nil){
        [AHLaunchCtl uninstallHelper:kMUMHelperName error:nil];
    }
}


#pragma mark - CFPrefs
-(NSString*)stringFromCFPref:(NSString*)key{
    NSString *string = CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)(key),
                                                                   (__bridge CFStringRef)(MSUAppPreferences)));
    if(string){
        return string;
    }else{
        return @"";
    }
}

-(void)quitHelper{
    self.helperToolShouldQuit = YES;
}

#pragma mark - NSXPC Delegate
//----------------------------------------
// Set up the one method of NSXPClistener
//----------------------------------------
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    assert(listener == self.listener);

    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MUMHelperAgent)];
    newConnection.exportedObject = self;
    [newConnection resume];

    self.connection = newConnection;
    return YES;
}


@end
