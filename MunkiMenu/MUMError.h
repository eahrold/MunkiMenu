//
//  MUMError.h
//  MunkiMenu
//
//  Created by Eldon on 2/24/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSArray+firstObject.h"

typedef NS_ENUM(NSInteger, MUMErrorCodes){
    kMUMErrorSuccess = 0,
    kMUMErrorCouldNotAuthorized = 1000,
    kMUMErrorCouldNotInstallHelper,
    kMUMErrorMunkiNotInstalled,
    kMUMErrorUninstallRequest,
    kMUMErrorManagedSoftwareUpdateBadExitStatus,
    kMUMErrorManagedSoftwareUpdateInstanceIsRunning,
    kMUMErrorCouldNotRetrieveManifest,
};


@interface MUMError : NSObject

#ifdef __MUNKI_MENU_APP__
+(void)presentErrorWithCode:(MUMErrorCodes)code delegate:(id)sender didPresentSelector:(SEL)selector;
#endif

+(BOOL)errorWithCode:(MUMErrorCodes)code error:(NSError**)error;
+(NSError*)errorWithCode:(MUMErrorCodes)code;

@end
