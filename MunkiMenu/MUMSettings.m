//
//  MUMSettings.m
//  MunkiMenu
//
//  Created by Eldon on 2/24/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import "MUMSettings.h"
#import "MUMConstants.h"

@implementation MUMSettings

- (id)initWithCoder:(NSCoder*)aDecoder {
    NSSet* SAND = [NSSet setWithObjects:[NSArray class],[NSDictionary class],[NSString class],[NSNumber class], nil];
    NSSet* AS   = [NSSet setWithObjects:[NSArray class],[NSString class],nil];
    
    self = [super init];
    if (self) {
        _softwareRepoURL   = [aDecoder decodeObjectOfClass:[NSString class] forKey:kMUMSoftwareRepoURL];
        _manifestURL       = [aDecoder decodeObjectOfClass:[NSString class] forKey:kMUMManifestURL];
        _catalogURL        = [aDecoder decodeObjectOfClass:[NSString class] forKey:kMUMCatalogURL];
        _packageURL        = [aDecoder decodeObjectOfClass:[NSString class] forKey:kMUMPackageURL];
        _managedInstallDir = [aDecoder decodeObjectOfClass:[NSString class] forKey:kMUMManagedInstallDir];
        _logFile           = [aDecoder decodeObjectOfClass:[NSString class] forKey:kMUMLogFile];
        _clientIdentifier  = [aDecoder decodeObjectOfClass:[NSString class] forKey:kMUMClientIdentifier];
        _managedInstalls   = [aDecoder decodeObjectOfClasses:AS forKey:kMUMManagedInstalls];
        _managedUpdates    = [aDecoder decodeObjectOfClasses:AS forKey:kMUMManagedUpdates];
        _managedUninstalls = [aDecoder decodeObjectOfClasses:AS forKey:kMUMManagedUninstalls];
        _processedInstalls = [aDecoder decodeObjectOfClasses:AS forKey:kMUMProcessedInstalls];
        _installedItems    = [aDecoder decodeObjectOfClasses:AS forKey:kMUMInstalledItems];
        _itemsToInstall    = [aDecoder decodeObjectOfClasses:AS forKey:kMUMItemsToInstall];
        _itemsToRemove     = [aDecoder decodeObjectOfClasses:AS forKey:kMUMItemsToRemove];
        _msuWarnings       = [aDecoder decodeObjectOfClasses:SAND forKey:kMUMMSUWarnings];
        _optionalInstalls  = [aDecoder decodeObjectOfClasses:SAND forKey:kMUMOptionalInstalls];
        _installASU        = [aDecoder decodeBoolForKey:kMUMInstallAppleSoftwareUpdates];
    }
    return self;
}

+ (BOOL)supportsSecureCoding { return YES; }

- (void)encodeWithCoder:(NSCoder*)aEncoder {
    [aEncoder encodeObject:_softwareRepoURL   forKey:kMUMSoftwareRepoURL];
    [aEncoder encodeObject:_manifestURL       forKey:kMUMManifestURL];
    [aEncoder encodeObject:_catalogURL        forKey:kMUMCatalogURL];
    [aEncoder encodeObject:_packageURL        forKey:kMUMPackageURL];
    [aEncoder encodeObject:_managedInstallDir forKey:kMUMManagedInstallDir];
    [aEncoder encodeObject:_logFile           forKey:kMUMLogFile];
    [aEncoder encodeObject:_clientIdentifier  forKey:kMUMClientIdentifier];
    [aEncoder encodeObject:_managedInstalls   forKey:kMUMManagedInstalls];
    [aEncoder encodeObject:_managedUpdates    forKey:kMUMManagedUpdates];
    [aEncoder encodeObject:_managedUninstalls forKey:kMUMManagedUninstalls];
    [aEncoder encodeObject:_processedInstalls forKey:kMUMProcessedInstalls];
    [aEncoder encodeObject:_optionalInstalls  forKey:kMUMOptionalInstalls];
    [aEncoder encodeObject:_installedItems    forKey:kMUMInstalledItems];
    [aEncoder encodeObject:_itemsToInstall    forKey:kMUMItemsToInstall];
    [aEncoder encodeObject:_itemsToRemove     forKey:kMUMItemsToRemove];
    [aEncoder encodeObject:_msuWarnings       forKey:kMUMMSUWarnings];
    [aEncoder encodeBool:  _installASU        forKey:kMUMInstallAppleSoftwareUpdates];
}

@end