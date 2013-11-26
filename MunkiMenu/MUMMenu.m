//
//  MUMMenu.m
//  MunkiMenu
//
//  Created by Eldon on 11/26/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMMenu.h"
@class MUMController;

@implementation MUMMenu
@synthesize delegate;

-(void)addUpdateServerURLToMenu{
    NSString* url = [delegate managedSoftwareUpdateURL:self];
    if(url){
        NSMenuItem* mums;
        mums = [[NSMenuItem alloc]initWithTitle:url
                                        action:NULL
                                 keyEquivalent:@""];

        [self insertItem:mums atIndex:2];
    }
    
}

-(void)addManifestNameToMenu{
    NSString* manifest = [delegate manifestName:self];
    if(manifest){
        NSMenuItem* mums;
        mums = [[NSMenuItem alloc]initWithTitle:[NSString stringWithFormat:@"Using Manifest: %@",manifest]
                                         action:NULL
                                  keyEquivalent:@""];
        
    }
}

-(void)addOptionalInstallListToMenu{
    NSArray* optionalInstals = [delegate optionalInstalls:self];
    if(!optionalInstals)return;

    NSMenuItem* mums = [[NSMenuItem alloc]initWithTitle:@"Optional Installs"
                                                 action:NULL
                                          keyEquivalent:@""];

    
    NSMenu* details = [[NSMenu alloc]init];
    for (NSDictionary* dict in optionalInstals){
        NSMenuItem* install = [[NSMenuItem alloc]initWithTitle:dict[@"name"] action:NULL keyEquivalent:@""];
        
        if([[dict objectForKey:@"installed"] isEqual:[NSNumber numberWithBool:YES]]){
            [install setState:YES];
        }else{
            [install setTarget:delegate];
            [install setAction:@selector(runManagedSoftwareUpdate:)];
        }
        
        [details addItem:install];
        
    }
    
    [self setSubmenu:details forItem:mums];
    [self insertItem:mums atIndex:2];

}

@end
