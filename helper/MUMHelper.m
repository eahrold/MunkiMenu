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

-(void)changeRepoURL:(NSString*)newURL withReply:(void (^)(NSError *))reply{
    NSError* error;
    CFPreferencesSetAppValue((__bridge CFStringRef)(@"SoftwareRepoURL"), (__bridge CFStringRef)(newURL), (__bridge CFStringRef)(MSUAppPreferences));
    
    BOOL status = CFPreferencesAppSynchronize((__bridge CFStringRef)(MSUAppPreferences));
    
    if(!status){
        error = [NSError errorWithDomain:HeperDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"error setting repo url"}];
    }
    
    reply(error);
}

-(void)changeClientManifest:(NSString*)newManifest withReply:(void (^)(NSError *))reply{
    NSError* error;
    CFPreferencesSetAppValue((__bridge CFStringRef)(@"ClientIdentifier"), (__bridge CFStringRef)(newManifest), (__bridge CFStringRef)(MSUAppPreferences));
    
    BOOL status = CFPreferencesAppSynchronize((__bridge CFStringRef)(MSUAppPreferences));

    if(!status){
        error = [NSError errorWithDomain:HeperDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"error setting client manifest"}];
    }
    
    reply(error);
}

-(void)quitHelper{
    // this will cause the run-loop to exit;
    // you should call it via NSXPCConnection during the applicationShouldTerminate routine
    self.helperToolShouldQuit = YES;
}

-(void)uninstall:(void (^)(NSError *))reply{
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
