//
//  MUMInterface.h
//  MunkiMenu
//
//  Created by Eldon on 11/29/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MUMInterface.h"

@class MSUSettings;

static NSString* const kHelperName = @"com.googlecode.MunkiMenu.helper";

// Strings from ManagedInstalls.plist
static NSString* const kSoftwareRepoURL             = @"SoftwareRepoURL";
static NSString* const kManifestURL                 = @"ManifestURL";
static NSString* const kCatalogURL                  = @"CatalogURL";
static NSString* const kPackageURL                  = @"PackageURL";
static NSString* const kManagedInstallDir           = @"ManagedInstallDir";
static NSString* const kLogFile                     = @"LogFile";
static NSString* const kClientIdentifier            = @"ClientIdentifier";
static NSString* const kInstallASU                  = @"InstallAppleSoftwareUpdates";

// Strings from ManagedInstallReport.plist
static NSString* const kManagedInstalls             = @"managed_installs_list";
static NSString* const kManagedUpdates              = @"managed_updates_list";
static NSString* const kManagedUninstalls           = @"managed_uninstalls_list";
static NSString* const kInstalledItems              = @"InstalledItems";
static NSString* const kItemsToInstall              = @"ItemsToInstall";
static NSString* const kItemsToRemove               = @"ItemsToRemove";
static NSString* const kMSUWarnings                 = @"Warnings";

// Strings from InstallInfo.plist
static NSString* const kProcessedInstalls           = @"processed_installs";
static NSString* const kOptionalInstalls            = @"optional_installs";

// Strings for MunkiMenu defaults
static NSString* const kShowManagedInstalls         = @"ShowMangedInstalls";
static NSString* const kShowOptionalInstalls        = @"ShowOptionalInstalls";
static NSString* const kShowManagedUpdates          = @"ShowManagedUpdates";
static NSString* const kShowItemsToInsatll          = @"ShowItemsToInstall";
static NSString* const kShowItemsToRemove           = @"ShowItemsToRemove";
static NSString* const kNotificationsEnabled        = @"NotificationsEnabled";

// NSDistributed Notification Center Strings broadcast from managedsoftwareupdate
static NSString* const MSUUpdateComplete = @"com.googlecode.munki.ManagedSoftwareUpdate.complete";
static NSString* const MSUUpdate= @"com.googlecode.munki.ManagedSoftwareUpdate.update";
static NSString* const MSUUpdateAvaliable = @"com.googlecode.munki.ManagedSoftwareUpdate.avaliableupdates";
static NSString* const MUMFinishedLaunching = @"com.google.code.munkimenu.didfinishlaunching";

@protocol HelperAgent
@required
-(void)getPreferenceDictionary:(void (^)(MSUSettings *, NSError *))reply;
-(void)installGlobalLoginItem:(NSURL*)loginItem withReply:(void (^)(NSError*))reply;
-(void)quitHelper;

-(void)configureMunki:(MSUSettings*)settings authorization:(NSData *)authData withReply:(void (^)(NSError*))reply;
-(void)uninstall:(NSURL*)mainAppURL authorization:(NSData *)authData withReply:(void (^)(NSError*))reply;
@end


#pragma mark - Secure Objects
@interface MSUSettings : NSObject <NSSecureCoding>
@property (copy) NSString* softwareRepoURL;
@property (copy) NSString *manifestURL;
@property (copy) NSString *catalogURL;
@property (copy) NSString *packageURL;
@property (copy) NSString *managedInstallDir;
@property (copy) NSString *logFile;
@property (copy) NSString *clientIdentifier;
@property (copy) NSArray  *managedInstalls;
@property (copy) NSArray  *managedUpdates;
@property (copy) NSArray  *managedUninstalls;
@property (copy) NSArray  *processedInstalls;
@property (copy) NSArray  *optionalInstalls;
@property (copy) NSArray  *installedItems;
@property (copy) NSArray  *itemsToInstall;
@property (copy) NSArray  *itemsToRemove;
@property (copy) NSArray  *msuWarnings;
@property BOOL installASU;


@end
