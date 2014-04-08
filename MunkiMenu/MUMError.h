//
//  MUMError.h
//  MunkiMenu
//
//  Created by Eldon on 2/24/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MUMErrorCodes){
    kMUMErrorSuccess = 0,
    kMUMErrorCouldNotAuthorized = 1000,
    kMUMErrorCouldNotInstallHelper,
    kMUMErrorMunkiNotInstalled,
    kMUMErrorUninstallRequest,
    kMUMErrorManagedSoftwareUpdateBadExitStatus,

};

// bridge managedsoftwareupdate error codes
typedef NS_ENUM(NSInteger, MSUErrorCodes){
    kMSU_EXIT_STATUS_OBJC_MISSING = 100,
    kMSU_EXIT_STATUS_MUNKI_DIRS_FAILURE = 101,
    kMSU_EXIT_STATUS_SERVER_UNAVAILABLE = 150,
    kMSU_EXIT_STATUS_INVALID_PARAMETERS = 200,
    kMSU_EXIT_STATUS_ROOT_REQUIRED = 201,
};

@interface MUMError : NSObject

#ifdef _COCOA_H
+(void)presentErrorWithCode:(MUMErrorCodes)code delegate:(id)sender didPresentSelector:(SEL)selector;
#endif

+(BOOL)errorWithCode:(MUMErrorCodes)code error:(NSError**)error;

@end
