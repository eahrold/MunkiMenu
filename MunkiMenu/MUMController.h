//
//  MUMController.h
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MUMMenu.h"

@interface MUMController : NSObject <MUMMenuDelegate,NSUserNotificationCenterDelegate>{
    NSStatusItem* statusItem;
}

//Status Menu
@property (strong) IBOutlet MUMMenu* menu;

//Config Sheet
@property (assign) IBOutlet NSWindow* configSheet;
@property (assign) IBOutlet NSTextField* repoURLTF;
@property (assign) IBOutlet NSTextField* clientIDTF;
@property (assign) IBOutlet NSTextField* logFileTF;
@property (assign) IBOutlet NSTextField* manifestURLTF;
@property (assign) IBOutlet NSTextField* catalogURLTF;
@property (assign) IBOutlet NSTextField* packageURLTF;

@property (assign) IBOutlet NSButton* ASUEnabledCB;

-(IBAction)configureMunki:(id)sender;  //set button pressed

@end
