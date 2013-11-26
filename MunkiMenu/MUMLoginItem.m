//
//  MUMLoginItem.m
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMLoginItem.h"

@implementation MUMLoginItem

+(BOOL)installLoginItem:(BOOL)state{
    BOOL status = YES;
    NSError* error;
    NSString * appPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef loginItem = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    if(state){
        //Adding Login Item
        if (loginItems) {
            LSSharedFileListItemRef ourLoginItem = LSSharedFileListInsertItemURL(loginItems,
                                                                                 kLSSharedFileListItemLast,
                                                                                 NULL, NULL,
                                                                                 loginItem,
                                                                                 NULL, NULL);
            if (ourLoginItem) {
                CFRelease(ourLoginItem);
            } else {
                error = [NSError errorWithDomain:@"Login Item" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Could Not add ourselves to login items"}];
                status = NO;
            }
            CFRelease(loginItems);
        } else {
            error = [NSError errorWithDomain:@"Login Item" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Could Not get list of login items"}];
            status = NO;
        }
        if(error)[NSApp presentError:error];
        
    }else{
        //Removing Login Item
        if (loginItem){
            UInt32 seedValue;
            //Retrieve the list of Login Items and cast them to
            // a NSArray so that it will be easier to iterate.
            NSArray  *loginItemsArray = CFBridgingRelease(LSSharedFileListCopySnapshot(loginItems, &seedValue));
            for( id i in loginItemsArray){
                LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)i;
                //Resolve the item with URL
                if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &loginItem, NULL) == noErr) {
                    NSString * urlPath = [(__bridge NSURL*)loginItem path];
                    if ([urlPath compare:appPath] == NSOrderedSame){
                        LSSharedFileListItemRemove(loginItems,itemRef);
                    }
                }
            }
        }
        CFRelease(loginItems);
    }
    return status;
}

@end
