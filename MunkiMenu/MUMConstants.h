//
//  MUMConstants.h
//  MunkiMenu
//
//  Created by Eldon on 2/24/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#ifndef MunkiMenu_MUMConstants_h
#define MunkiMenu_MUMConstants_h

//static NSString * const kMUMHelperName = @"com.googlecode.MunkiMenu.helper";

// Strings from ManagedInstalls.plist
static NSString * const kMUMSoftwareRepoURL             = @"SoftwareRepoURL";
static NSString * const kMUMManifestURL                 = @"ManifestURL";
static NSString * const kMUMCatalogURL                  = @"CatalogURL";
static NSString * const kMUMPackageURL                  = @"PackageURL";
static NSString * const kMUMManagedInstallDir           = @"ManagedInstallDir";
static NSString * const kMUMLogFile                     = @"LogFile";
static NSString * const kMUMClientIdentifier            = @"ClientIdentifier";
static NSString * const kMUMInstallAppleSoftwareUpdates                  = @"InstallAppleSoftwareUpdates";

// Strings from ManagedInstallReport.plist
static NSString * const kMUMManagedInstalls             = @"managed_installs_list";
static NSString * const kMUMManagedUpdates              = @"managed_updates_list";
static NSString * const kMUMManagedUninstalls           = @"managed_uninstalls_list";
static NSString * const kMUMInstalledItems              = @"InstalledItems";
static NSString * const kMUMItemsToInstall              = @"ItemsToInstall";
static NSString * const kMUMItemsToRemove               = @"ItemsToRemove";
static NSString * const kMUMMSUWarnings                 = @"Warnings";

// Strings from InstallInfo.plist
static NSString * const kMUMProcessedInstalls           = @"processed_installs";
static NSString * const kMUMOptionalInstalls            = @"optional_installs";

// Strings for MunkiMenu defaults
static NSString * const kMUMShowManagedInstalls         = @"ShowMangedInstalls";
static NSString * const kMUMShowOptionalInstalls        = @"ShowOptionalInstalls";
static NSString * const kMUMShowManagedUpdates          = @"ShowManagedUpdates";
static NSString * const kMUMShowItemsToInsatll          = @"ShowItemsToInstall";
static NSString * const kMUMShowItemsToRemove           = @"ShowItemsToRemove";
static NSString * const kMUMNotificationsEnabled        = @"NotificationsEnabled";

// NSDistributed Notification Center Strings broadcast from managedsoftwareupdate
static NSString * const MSUUpdateComplete    = @"com.googlecode.munki.ManagedSoftwareUpdate.complete";
static NSString * const MSUUpdate            = @"com.googlecode.munki.ManagedSoftwareUpdate.update";
static NSString * const MSUUpdateAvaliable   = @"com.googlecode.munki.ManagedSoftwareUpdate.avaliableupdates";
static NSString * const MUMFinishedLaunching = @"com.google.code.munkimenu.didfinishlaunching";


#endif
