//
//  MUMConfigView.h
//  MunkiMenu
//
//  Created by Eldon on 12/10/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MUMMenuView : NSView
-(instancetype)initWithStatusItem:(NSStatusItem*)statusItem andMenu:(NSMenu*)menu;
-(void)setActive:(BOOL)active;
-(void)animate;
-(void)stopAnimation;
@end
