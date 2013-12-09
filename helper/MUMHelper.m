//
//  MUMHelper.m
//  MunkiMenu
//
//  Created by Eldon on 11/28/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMHelper.h"
#import "Authorizer.h"

static NSString* const MSUAppPreferences = @"ManagedInstalls";

@implementation MUMHelper

#pragma mark - ManagedInstall.plist Methods
-(void)getPreferenceDictionary:(void (^)(MSUSettings *, NSError *))reply{
    NSError* error;
    MSUSettings* settings = [MSUSettings new];
    
    settings.managedInstallDir = [self stringFromCFPref:kManagedInstallDir];

    NSString *reports = [NSString stringWithFormat:@"%@/ManagedInstallReport.plist",settings.managedInstallDir];
    NSDictionary *msuReport = [NSDictionary dictionaryWithContentsOfFile:reports];
    
    NSString *info = [NSString stringWithFormat:@"%@/InstallInfo.plist",settings.managedInstallDir];
    NSDictionary *msuInstallInfo = [NSDictionary dictionaryWithContentsOfFile:info];
  
    // Set up a dictionary of with BOOL values for the Optional Install items
    NSMutableArray* msuOptionalInstalls = [NSMutableArray new];
    for(NSDictionary* dict in msuInstallInfo[kOptionalInstalls]){
        [msuOptionalInstalls addObject:@{@"item":dict[@"name"],@"installed":dict[@"installed"]}];
    }
    
    // Pull out the name of the item to install from the dictionary
    NSMutableSet *itemsToInstall = [NSMutableSet new];
    for(NSDictionary* dict in msuReport[kItemsToInstall]){
        [itemsToInstall addObject:dict[@"name"]];
    }
    
    // Pull out the name of the item to remove from the dictionary
    NSMutableSet *itemsToRemove  = [NSMutableSet new];
    for(NSDictionary* dict in msuReport[kItemsToRemove]){
        [itemsToRemove addObject:dict[@"name"]];
    }
   
    settings.softwareRepoURL    = [self stringFromCFPref:kSoftwareRepoURL];
    settings.manifestURL        = [self stringFromCFPref:kManifestURL];
    settings.catalogURL         = [self stringFromCFPref:kCatalogURL];
    settings.packageURL         = [self stringFromCFPref:kPackageURL];
    settings.logFile            = [self stringFromCFPref:kLogFile];
    settings.clientIdentifier   = [self stringFromCFPref:kClientIdentifier];
    
    settings.managedInstalls    = msuReport[kManagedInstalls];
    settings.managedUpdates     = msuReport[kManagedUpdates];
    settings.managedUninstalls  = msuReport[kManagedUninstalls];
    
    settings.installedItems     = msuReport[kInstalledItems];
    settings.msuWarnings        = msuReport[kMSUWarnings];
    settings.processedInstalls  = msuInstallInfo[kProcessedInstalls];

    settings.optionalInstalls   = msuOptionalInstalls;

    settings.itemsToInstall     = [itemsToInstall allObjects];
    settings.itemsToRemove      = [itemsToRemove allObjects];
    
    
    settings.installASU         = [[self stringFromCFPref:kInstallASU]boolValue];


    if(!settings)error = [NSError errorWithDomain:kHelperName
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey:@"Therer were problems getting the preferences for Managed Software Update."}];
    reply(settings,error);
}

-(void)configureMunki:(MSUSettings*)settings authorization:(NSData*)authData withReply:(void (^)(NSError*))reply{
    NSError* error;
    
    error = [self checkAuthorization:authData command:_cmd];
    if(error != nil){
        reply(error);
        return;
    }
    
    [self writeToCFPref:settings.softwareRepoURL key:kSoftwareRepoURL];
    [self writeToCFPref:settings.packageURL key:kPackageURL];
    [self writeToCFPref:settings.manifestURL key:kManifestURL];
    [self writeToCFPref:settings.catalogURL key:kCatalogURL];
    [self writeToCFPref:settings.logFile key:kLogFile];
    [self writeToCFPref:settings.clientIdentifier key:kClientIdentifier];
    
    NSTask* task = [NSTask new];
    [task setLaunchPath:@"/usr/local/munki/managedsoftwareupdate"];
    
    // use --munkipkgsonly here for to help speed things up...
    [task setArguments:@[@"--checkonly",@"--munkipkgsonly"]];
    [task launch];

    reply(error);
}

#pragma mark - Clean Up
-(void)uninstall:(NSURL*)mainAppURL authorization:(NSData*)authData withReply:(void (^)(NSError*))reply{
    NSError* error;
    NSError* returnError;
    
    error = [self checkAuthorization:authData command:_cmd];
    if(error == nil){
        
        NSString *launchD = [NSString stringWithFormat:@"/Library/LaunchDaemons/%@.plist",kHelperName];
        NSString *helperTool = [NSString stringWithFormat:@"/Library/PrivilegedHelperTools/%@",kHelperName];

        [[NSFileManager defaultManager] removeItemAtPath:launchD error:&error];
        if (error.code != NSFileNoSuchFileError) {
            NSLog(@"%@", error);
            returnError = error;
            error = nil;
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:helperTool error:&error];
        if (error.code != NSFileNoSuchFileError) {
            NSLog(@"%@", error);
            returnError = error;
            error = nil;
        }
        [self removeGlobalLoginItem:mainAppURL];
    }else{
        returnError = error;
    }
    
    reply(returnError);
}

-(void)quitHelper{
    // this will cause the run-loop to exit;
    // you should call it via NSXPCConnection during the applicationShouldTerminate routine
    self.helperToolShouldQuit = YES;
}

#pragma mark - CFPrefs
-(NSString*)stringFromCFPref:(NSString*)key{
    NSString* string = CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)(key), (__bridge CFStringRef)(MSUAppPreferences)));
    if(string){
        return string;
    }else{
        return @"";
    }
}

-(NSError*)writeToCFPref:(NSString*)value key:(NSString*)key{
    NSError* error;
    BOOL rc = NO;
    if(value && key){
        CFPreferencesSetValue((__bridge CFStringRef)(key),
                              (__bridge CFPropertyListRef)(value),
                              (__bridge CFStringRef)(MSUAppPreferences),
                              kCFPreferencesAnyUser,
                              kCFPreferencesCurrentHost);
        
        rc = CFPreferencesSynchronize((__bridge CFStringRef)(MSUAppPreferences),kCFPreferencesAnyUser,
                                 kCFPreferencesCurrentHost);
    }
    
    if(!rc){
        NSString* msg;
        if(!key){
            msg = @"The key was not specified";
        }else{
            msg = [NSString stringWithFormat:@"Couldn't write the %@ key to specified domain",key];
        }
        error = [NSError errorWithDomain:kHelperName code:1 userInfo:@{NSLocalizedDescriptionKey:msg}];
    }
    return error;
}

#pragma mark - Global Login Items
-(void)installGlobalLoginItem:(NSURL*)loginItem withReply:(void (^)(NSError*))reply{
    NSError* error;
    AuthorizationRef auth = NULL;
    LSSharedFileListRef globalLoginItems = LSSharedFileListCreate(NULL, kLSSharedFileListGlobalLoginItems, NULL);
    LSSharedFileListSetAuthorization(globalLoginItems, auth);
    
    if([self checkIfAlreadyActive:loginItem]){
        CFRelease(globalLoginItems);
        reply(error);
        return;
    }
    
    if (globalLoginItems) {
        LSSharedFileListItemRef ourLoginItem = LSSharedFileListInsertItemURL(globalLoginItems,
                                                                             kLSSharedFileListItemLast,
                                                                             NULL, NULL,
                                                                             (__bridge CFURLRef)loginItem,
                                                                             NULL, NULL);
        if (ourLoginItem) {
            CFRelease(ourLoginItem);
        } else {
            error = [NSError errorWithDomain:kHelperName code:1 userInfo:@{NSLocalizedDescriptionKey:@"Could not insert ourselves as a global login item"}];
        }
        CFRelease(globalLoginItems);
    } else {
        error = [NSError errorWithDomain:kHelperName code:1 userInfo:@{NSLocalizedDescriptionKey:@"Could not get the global login items"}];
    }
    
    reply(error);
}

-(void)removeGlobalLoginItem:(NSURL*)app{
    CFURLRef loginItem = (__bridge CFURLRef)app;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListGlobalLoginItems, NULL);
    
    if (loginItem){
        UInt32 seedValue;
        //Retrieve the list of Login Items and cast them to
        // a NSArray so that it will be easier to iterate.
        NSArray  *loginItemsArray = CFBridgingRelease(LSSharedFileListCopySnapshot(loginItems, &seedValue));
        for( id i in loginItemsArray){
            LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)i;
            //Resolve the item with URL
            if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &loginItem, NULL) == noErr) {
                NSString * urlPath = app.path;
                if ([urlPath compare:app.path] == NSOrderedSame){
                    CFRelease(loginItem);
                    LSSharedFileListItemRemove(loginItems,itemRef);
                }
            }
        }
    }
    CFRelease(loginItems);
}

-(BOOL)checkIfAlreadyActive:(NSURL*)app{
    CFURLRef loginItemCheck = (__bridge CFURLRef)app;
    LSSharedFileListRef loginItemsCheck = LSSharedFileListCreate(NULL, kLSSharedFileListGlobalLoginItems, NULL);
    
    if (loginItemCheck){
        UInt32 seedValue;
        //Retrieve the list of Login Items and cast them to
        // a NSArray so that it will be easier to iterate.
        NSArray  *loginItemsArray = CFBridgingRelease(LSSharedFileListCopySnapshot(loginItemsCheck, &seedValue));
        for( id i in loginItemsArray){
            LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)i;
            //Resolve the item with URL
            if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &loginItemCheck, NULL) == noErr) {
                NSString * urlPath = [(__bridge NSURL*)loginItemCheck path];
                if ([urlPath compare:app.path] == NSOrderedSame){
                    CFRelease(loginItemCheck);
                    return YES;
                }
            }
        }
    }
    CFRelease(loginItemsCheck);
    return NO;
}

#pragma mark - Authorization
- (NSError *)checkAuthorization:(NSData *)authData command:(SEL)command
// Check that the client denoted by authData is allowed to run the specified command.
// authData is expected to be an NSData with an AuthorizationExternalForm embedded inside.
{
#pragma unused(authData)
    NSError *                   error;
    OSStatus                    err;
    OSStatus                    junk;
    AuthorizationRef            authRef;
    
    assert(command != nil);
    
    authRef = NULL;
    
    // First check that authData looks reasonable.
    
    error = nil;
    if ( (authData == nil) || ([authData length] != sizeof(AuthorizationExternalForm)) ) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:paramErr userInfo:nil];
    }
    
    // Create an authorization ref from that the external form data contained within.
    
    if (error == nil) {
        err = AuthorizationCreateFromExternalForm([authData bytes], &authRef);
        
        // Authorize the right associated with the command.
        
        if (err == errAuthorizationSuccess) {
            AuthorizationItem   oneRight = { NULL, 0, NULL, 0 };
            AuthorizationRights rights   = { 1, &oneRight };
            
            oneRight.name = [[Authorizer authorizationRightForCommand:command] UTF8String];
            assert(oneRight.name != NULL);
            
            err = AuthorizationCopyRights(
                                          authRef,
                                          &rights,
                                          NULL,
                                          kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed,
                                          NULL
                                          );
        }
        if (err != errAuthorizationSuccess) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:@{NSLocalizedDescriptionKey:@"You are not authorized to perform this action."}];
        }
    }
    
    if (authRef != NULL) {
        junk = AuthorizationFree(authRef, 0);
        assert(junk == errAuthorizationSuccess);
    }
    
    return error;
}

#pragma mark - NSXPC Delegate
//----------------------------------------
// Helper Singleton
//----------------------------------------
+ (MUMHelper *)sharedAgent {
    static dispatch_once_t onceToken;
    static MUMHelper *sharedAgent;
    dispatch_once(&onceToken, ^{
        sharedAgent = [MUMHelper new];
    });
    return sharedAgent;
}

//----------------------------------------
// Set up the one method of NSXPClistener
//----------------------------------------
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    newConnection.exportedObject = self;
    
    self.xpcConnection = newConnection;
    
    [newConnection resume];
    return YES;
}


@end
