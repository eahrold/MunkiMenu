//
//  MUMConfigViewController.h
//  MunkiMenu
//
//  Created by Eldon on 12/10/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MUMViewControllerDelegate <NSObject>
-(void)closeConfigView;
-(void)configureMunki;
-(BOOL)popoverIsShown;
@end

@interface MUMConfigView : NSViewController

@property id<MUMViewControllerDelegate>delegate;
@property (assign) IBOutlet NSTextField* repoURLTF;
@property (assign) IBOutlet NSTextField* clientIDTF;
@property (assign) IBOutlet NSTextField* logFileTF;
@property (assign) IBOutlet NSTextField* manifestURLTF;
@property (assign) IBOutlet NSTextField* catalogURLTF;
@property (assign) IBOutlet NSTextField* packageURLTF;
@property (assign) IBOutlet NSTextField* managedByMCX;

@property (assign) IBOutlet NSButton* ASUEnabledCB;
@property (assign) IBOutlet NSButton* setButton;

@end
