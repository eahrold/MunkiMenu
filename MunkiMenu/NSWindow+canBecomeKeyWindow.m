//
//  NSWindow+canBecomeKeyWindow.m
//  MunkiMenu
//
//  Created by Eldon on 12/10/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "NSWindow+canBecomeKeyWindow.h"
#import "MUMController.h"

@implementation NSWindow (canBecomeKeyWindow)

//  http://stackoverflow.com/questions/7214273/nstextfield-on-nspopover
//  Bug. http://openradar.appspot.com/9722231
//This is to fix a bug with 10.7 (and still as of 10.9) where an NSPopover with a text field cannot be edited if its parent window won't become key
//The pragma statements disable the corresponding warning for overriding an already-implemented method

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (BOOL)canBecomeKeyWindow
{
    return YES;
}
#pragma clang diagnostic pop


@end
