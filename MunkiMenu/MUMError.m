//
//  MUMError.m
//  MunkiMenu
//
//  Created by Eldon on 2/24/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import "MUMError.h"

static NSString * errorMsgFromCode(NSInteger code){
    NSString * msg;
    switch (code) {
        case kMUMErrorCouldNotAuthorized: msg = @"Your are not authorized to perform this action.";
            break;
        case kMUMErrorCouldNotInstallHelper: msg = @"The necessary helper tool could not be installed.  We will now quit.";
            break;
        case kMUMErrorMunkiNotInstalled: msg = @"Munki installation not found.  Please install and try again";
            break;
        case kMUMErrorUninstallRequest: msg = @"Helper Tool and associated files have been removed.  You can safely remove MunkiMenu from the Applications folder.  We will now quit";
            break;
        case kMUMErrorCouldNotRetrieveManifest: msg = @"Could not retrieve managed install manifest, please check the settings and try again";
            break;
        case kMUMErrorManagedSoftwareUpdateBadExitStatus: msg = @"There was a problem running Managed Software update, please check your settings and try again, see the log for more info";
            break;
        case kMUMErrorManagedSoftwareUpdateInstanceIsRunning: msg = @"An instance of Managed Software Update is already running, you can try again after that completes";
            break;
        default:msg = @"unknown problem occurred";
            break;
    }
    return msg;
}


@implementation MUMError
#ifdef _APPKITDEFINES_H
+(void)presentErrorWithCode:(MUMErrorCodes)code delegate:(id)sender didPresentSelector:(SEL)selector
{
    NSError* error;
    [[self class]errorWithCode:code error:&error];
    [NSApp presentError:error
         modalForWindow:NULL
               delegate:sender
     didPresentSelector:selector
            contextInfo:NULL];
}
#endif

+(BOOL)errorWithCode:(MUMErrorCodes)code error:(NSError *__autoreleasing *)error{
    NSError *err = [self errorWithCode:code];
    if(error)*error = err;
    else NSLog(@"Error: %@",err.localizedDescription);
    return code == kMUMErrorSuccess ? YES:NO;
}

+(NSError*)errorWithCode:(MUMErrorCodes)code{
    if(code == kMUMErrorSuccess)return nil;
    NSString * msg = errorMsgFromCode(code);
    NSError  * error = [NSError errorWithDomain:@"com.googlecode.MunkiMenu"
                                       code:code
                                   userInfo:@{NSLocalizedDescriptionKey:msg}];
    return error;
}

@end
