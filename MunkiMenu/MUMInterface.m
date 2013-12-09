//
//  MSUSettings.m
//  MunkiMenu
//
//  Created by Eldon on 12/7/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMInterface.h"

@implementation MSUSettings

- (id)initWithCoder:(NSCoder*)aDecoder {
    NSSet* SAND = [NSSet setWithObjects:[NSArray class],[NSDictionary class],[NSString class],[NSNumber class], nil];
    //NSSet* SAD  = [NSSet setWithObjects:[NSArray class],[NSDictionary class],[NSString class],nil];
    //NSSet* ANS  = [NSSet setWithObjects:[NSArray class],[NSString class],[NSNumber class],nil];
    NSSet* AS   = [NSSet setWithObjects:[NSArray class],[NSString class],nil];
    
    self = [super init];
     if (self) {
         _softwareRepoURL   = [aDecoder decodeObjectOfClass:[NSString class] forKey:kSoftwareRepoURL];
         _manifestURL       = [aDecoder decodeObjectOfClass:[NSString class] forKey:kManifestURL];
         _catalogURL        = [aDecoder decodeObjectOfClass:[NSString class] forKey:kCatalogURL];
         _packageURL        = [aDecoder decodeObjectOfClass:[NSString class] forKey:kPackageURL];
         _managedInstallDir = [aDecoder decodeObjectOfClass:[NSString class] forKey:kManagedInstallDir];
         _logFile           = [aDecoder decodeObjectOfClass:[NSString class] forKey:kLogFile];
         _clientIdentifier  = [aDecoder decodeObjectOfClass:[NSString class] forKey:kClientIdentifier];
         _managedInstalls   = [aDecoder decodeObjectOfClasses:AS forKey:kManagedInstalls];
         _managedUpdates   = [aDecoder decodeObjectOfClasses:AS forKey:kManagedUpdates];
         _managedUninstalls   = [aDecoder decodeObjectOfClasses:AS forKey:kManagedUninstalls];
         _processedInstalls = [aDecoder decodeObjectOfClasses:AS forKey:kProcessedInstalls];
         _optionalInstalls  = [aDecoder decodeObjectOfClasses:SAND forKey:kOptionalInstalls];
         _installedItems    = [aDecoder decodeObjectOfClasses:AS forKey:kInstalledItems];
         _itemsToInstall    = [aDecoder decodeObjectOfClasses:AS forKey:kItemsToInstall];
         _itemsToRemove     = [aDecoder decodeObjectOfClasses:AS forKey:kItemsToRemove];
         _msuWarnings       = [aDecoder decodeObjectOfClasses:SAND forKey:kMSUWarnings];
         _installASU        = [aDecoder decodeBoolForKey:kInstallASU];
     }
    return self;
}

+ (BOOL)supportsSecureCoding { return YES; }

- (void)encodeWithCoder:(NSCoder*)aEncoder {
    [aEncoder encodeObject:_softwareRepoURL forKey:kSoftwareRepoURL];
    [aEncoder encodeObject:_manifestURL forKey:kManifestURL];
    [aEncoder encodeObject:_catalogURL forKey:kCatalogURL];
    [aEncoder encodeObject:_packageURL forKey:kPackageURL];
    [aEncoder encodeObject:_managedInstallDir forKey:kManagedInstallDir];
    [aEncoder encodeObject:_logFile forKey:kLogFile];
    [aEncoder encodeObject:_clientIdentifier forKey:kClientIdentifier];
    [aEncoder encodeObject:_managedInstalls forKey:kManagedInstalls];
    [aEncoder encodeObject:_managedUpdates forKey:kManagedUpdates];
    [aEncoder encodeObject:_managedUninstalls forKey:kManagedUninstalls];
    [aEncoder encodeObject:_processedInstalls forKey:kProcessedInstalls];
    [aEncoder encodeObject:_optionalInstalls forKey:kOptionalInstalls];
    [aEncoder encodeObject:_installedItems forKey:kInstalledItems];
    [aEncoder encodeObject:_itemsToInstall forKey:kItemsToInstall];
    [aEncoder encodeObject:_itemsToRemove forKey:kItemsToRemove];
    [aEncoder encodeObject:_msuWarnings forKey:kMSUWarnings];
    [aEncoder encodeBool:_installASU forKey:kInstallASU];
}

@end
