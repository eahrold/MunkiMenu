//
//  MUMInterface.h
//  MunkiMenu
//
//  Created by Eldon on 11/29/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* const kHelperName = @"com.googlecode.MunkiMenu.helper";

// Keys from the ManagedInstalls.plist file
static NSString* const kSoftwareRepoURL             = @"SoftwareRepoURL";
static NSString* const kManifestURL                 = @"ManifestURL";
static NSString* const kCatalogURL                  = @"CatalogURL";
static NSString* const kPackageURL                  = @"PackageURL";
static NSString* const kManagedInstallDir           = @"ManagedInstallDir";
static NSString* const kLogFile                     = @"LogFile";
static NSString* const kClientIdentifier            = @"ClientIdentifier";
static NSString* const kInstallAppleSoftwareUpdates = @"InstallAppleSoftwareUpdates";


enum MUMFileAtArrayIndex {
    kManifestFile = 0,
    kInventoryFile = 1,
    kReportsFile = 2,
    kSelfServiceFile = 3,
};

@protocol HelperAgent
@required
-(void)getPreferenceDictionary:(void (^)(NSDictionary *, NSError *))reply;
-(void)getMSUSettings:(NSString*)msuDir withReply:(void (^)(NSArray *))reply;
-(void)installGlobalLoginItem:(NSURL*)loginItem withReply:(void (^)(NSError*))reply;
-(void)quitHelper;

-(void)configureMunki:(NSDictionary*)settings authorization:(NSData *)authData withReply:(void (^)(NSDictionary *,NSError*))reply;
-(void)uninstall:(NSURL*)mainAppURL authorization:(NSData *)authData withReply:(void (^)(NSError*))reply;
@end
