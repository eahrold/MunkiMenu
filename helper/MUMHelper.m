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
-(void)getPreferenceDictionary:(void (^)(NSDictionary *, NSError *))reply{
    NSError* error;
    // Convert What we want back in the main app to NSDictionary
    // Entries
    NSDictionary* dict = @{kSoftwareRepoURL:[self stringFromCFPref:kSoftwareRepoURL],
                           kManifestURL:[self stringFromCFPref:kManifestURL],
                           kCatalogURL:[self stringFromCFPref:kCatalogURL],
                           kPackageURL:[self stringFromCFPref:kPackageURL],
                           kManagedInstallDir:[self stringFromCFPref:kManagedInstallDir],
                           kInstallAppleSoftwareUpdates:[self stringFromCFPref:kInstallAppleSoftwareUpdates],
                           kLogFile:[self stringFromCFPref:kLogFile],
                           kClientIdentifier:[self stringFromCFPref:kClientIdentifier]
                           };
    if(!dict)error = [NSError errorWithDomain:kHelperName
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey:@"Therer were problems getting the preferences for Managed Software Update."}];
    reply(dict,error);
}

-(void)getMSUSettings:(NSString*)msuDir withReply:(void (^)(NSArray *))reply{
    if(!msuDir)return;
    NSMutableArray* array = [NSMutableArray new];
    NSString *manifest = [NSString stringWithFormat:@"%@/manifests/client_manifest.plist",msuDir];
    array[kManifestFile] = [NSDictionary dictionaryWithContentsOfFile:manifest];
    
    NSString *inventory = [NSString stringWithFormat:@"%@/ApplicationInventory.plist",msuDir];
    array[kInventoryFile] = [NSDictionary dictionaryWithContentsOfFile:inventory];
    
    NSString *reports = [NSString stringWithFormat:@"%@/ManagedInstallReport.plist",msuDir];
    array[kReportsFile] = [NSDictionary dictionaryWithContentsOfFile:reports];
    
    NSString *ssinfo = [NSString stringWithFormat:@"%@/manifests/SelfServeManifest",msuDir];
    array[kSelfServiceFile] = [NSDictionary dictionaryWithContentsOfFile:ssinfo];
    
    reply(array);
}

-(void)configureMunki:(NSDictionary*)settings authorization:(NSData*)authData withReply:(void (^)(NSDictionary *,NSError*))reply{
    NSError* error;
    
    error = [self checkAuthorization:authData command:_cmd];
    if(error != nil){
        reply(nil,error);
        return;
    }
    error = nil;

    for(id key in settings) {
        id value = [settings objectForKey:key];
        [self writeToCFPref:value key:key];
    }
    
    [self getPreferenceDictionary:^(NSDictionary *dict, NSError *rerror) {
        // launch managed software update cli in order to trigger a refresh
        // of Managed / Optional installs files
        
        NSTask* task = [NSTask new];
        [task setLaunchPath:@"/usr/local/munki/managedsoftwareupdate"];
        [task setArguments:@[@"--checkonly"]];
        [task launch];
        
        reply(dict,rerror);
        return;
    }];
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
