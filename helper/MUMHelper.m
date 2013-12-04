//
//  MUMHelper.m
//  MunkiMenu
//
//  Created by Eldon on 11/28/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMHelper.h"

static NSString* const MSUAppPreferences = @"ManagedInstalls";
static NSString* const HeperDomain = @"com.googlecode.MunkiMenu.helper";


@implementation MUMHelper

-(void)getPreferenceDictionary:(void (^)(NSDictionary *, NSError *))reply{
    NSError* error;
    // Convert What we want back in the main app to NSDictionary
    // Entries
    NSDictionary* dict = @{@"SoftwareRepoURL":[self stringFromCFPref:@"SoftwareRepoURL"],
                           @"ManifestURL":[self stringFromCFPref:@"ManifestURL"],
                           @"CatalogURL":[self stringFromCFPref:@"CatalogURL"],
                           @"PackageURL":[self stringFromCFPref:@"PackageURL"],
                           @"ManagedInstallDir":[self stringFromCFPref:@"ManagedInstallDir"],
                           @"InstallAppleSoftwareUpdates":[self stringFromCFPref:@"InstallAppleSoftwareUpdates"],
                           @"LogFile":[self stringFromCFPref:@"LogFile"],
                           @"ClientIdentifier":[self stringFromCFPref:@"ClientIdentifier"]
                           };
    
    reply(dict,error);
}

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
            error = [NSError errorWithDomain:HeperDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"Could not insert ourselves as a global login item"}];
        }
        CFRelease(globalLoginItems);
    } else {
        error = [NSError errorWithDomain:HeperDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"Could not get the global login items"}];
    }
    reply(error);
}

-(void)quitHelper{
    // this will cause the run-loop to exit;
    // you should call it via NSXPCConnection during the applicationShouldTerminate routine
    self.helperToolShouldQuit = YES;
}

-(void)uninstall:(NSURL*)mainAppURL withReply:(void (^)(NSError*))reply{
    NSError* error;
    NSError* retunError;
    
    NSString *launchD = [NSString stringWithFormat:@"/Library/LaunchDaemons/%@.plist",kHelperName];
    NSString *helperTool = [NSString stringWithFormat:@"/Library/PrivilegedHelperTools/%@",kHelperName];

    [[NSFileManager defaultManager] removeItemAtPath:launchD error:&error];
    if (error.code != NSFileNoSuchFileError) {
        NSLog(@"%@", error);
        retunError = error;
        error = nil;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:helperTool error:&error];
    if (error.code != NSFileNoSuchFileError) {
        NSLog(@"%@", error);
        retunError = error;
        error = nil;
    }
    [self removeGlobalLoginItem:mainAppURL];
    reply(retunError);
}

-(NSString*)stringFromCFPref:(NSString*)pref{
    NSString* string = CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)(pref), (__bridge CFStringRef)(MSUAppPreferences)));
    if(string){
        return string;
    }else{
        return @"";
    }
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
