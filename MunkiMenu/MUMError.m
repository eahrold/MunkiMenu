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
        default:msg = @"unknown problem occurred";
            break;
    }
    return msg;
}


@implementation MUMError
+(void)presentErrorWithCode:(MUMErrorCodes)code delegate:(id)sender didPresentSelector:(SEL)selector
{
#ifdef _COCOA_H
    NSError* error;
    [[self class]errorWithCode:code error:&error];
    [NSApp presentError:error
         modalForWindow:NULL
               delegate:sender
     didPresentSelector:selector
            contextInfo:NULL];
#endif
}

+(BOOL)errorWithCode:(MUMErrorCodes)code error:(NSError *__autoreleasing *)error{
    BOOL rc = code > kMUMErrorSuccess ? NO:YES;
    NSString * msg = errorMsgFromCode(code);
    NSError *err = [NSError errorWithDomain:@"com.googlecode.MunkiMenu"
                                       code:code
                                   userInfo:@{NSLocalizedDescriptionKey:msg}];
    if(error)
        *error = err;
    else
        NSLog(@"Error: %@",msg);
    
    return rc;
}


@end
