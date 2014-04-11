//
//  MUMSettings.h
//  MunkiMenu
//
//  Created by Eldon on 2/24/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Secure Objects
/**
 *  NSSecure Object for passing the Plist data from the Main app to the helper app and back.
 */
@interface MUMSettings : NSObject <NSSecureCoding>
@property (copy) NSString *softwareRepoURL;
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
@property (copy) NSArray  *installedItems;
@property (copy) NSArray  *itemsToInstall;
@property (copy) NSArray  *itemsToRemove;
@property (copy) NSArray  *msuWarnings;
@property (copy) NSArray  *optionalInstalls;
@property        BOOL      installASU;

@end
