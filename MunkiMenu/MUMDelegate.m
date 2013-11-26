//
//  AppDelegate.m
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMDelegate.h"
#import "MUMLoginItem.h"
@implementation MUMDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [MUMLoginItem installLoginItem:YES];
}

@end
