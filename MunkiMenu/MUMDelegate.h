//
//  AppDelegate.h
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString* const MUMFinishedLaunching;

@interface MUMDelegate : NSObject <NSApplicationDelegate>
-(void)setupDidEndWithUninstallRequest;
@end
