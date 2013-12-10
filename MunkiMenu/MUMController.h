//
//  MUMController.h
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MUMMenu.h"
#import "MUMConfigView.h"

@interface MUMController : NSObject <MUMMenuDelegate,NSUserNotificationCenterDelegate,MUMViewControllerDelegate>{
    NSStatusItem* statusItem;
}

//Status Menu
@property (strong) IBOutlet MUMMenu* menu;

@end
