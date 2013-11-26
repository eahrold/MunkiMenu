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

-(void)addInfoToMenu{
    NSString* url = [delegate managedSoftwareUpdateURL:self];
    NSString* manifest = [delegate manifestName:self];

    NSMenuItem* info = [[NSMenuItem alloc]initWithTitle:@"Settings"
                                                 action:NULL
                                          keyEquivalent:@""];
    
    NSMenu* details = [[NSMenu alloc]init];
    
    if(url){
        NSMenuItem* menu_url;
        menu_url = [[NSMenuItem alloc]initWithTitle:url
                                         action:@selector(dud:)
                                  keyEquivalent:@""];
        [menu_url setTarget:self];
        [details addItem:menu_url];
    }
    
    if(manifest){
        NSMenuItem* menu_manifest;
        menu_manifest = [[NSMenuItem alloc]initWithTitle:[NSString stringWithFormat:@"Using Manifest: %@",manifest]
                                         action:@selector(dud:)
                                  keyEquivalent:@""];
        
        [menu_manifest setTarget:self];
        [details addItem:menu_manifest];
    }

    [info setSubmenu:details];
    
    [self insertItem:info atIndex:[self numberOfItems]-1];
        
}
-(void)addUpdateServerURLToMenu{
    NSString* url = [delegate managedSoftwareUpdateURL:self];
    if(url){
        NSMenuItem* mums;
        mums = [[NSMenuItem alloc]initWithTitle:url
                                         action:@selector(dud:)
                                 keyEquivalent:@""];
        [mums setTarget:self];
        [self insertItem:mums atIndex:[self numberOfItems]-2];
    }
}

-(void)addManifestNameToMenu{
    NSString* manifest = [delegate manifestName:self];
    if(manifest){
        NSMenuItem* mums;
        mums = [[NSMenuItem alloc]initWithTitle:[NSString stringWithFormat:@"Using Manifest: %@",manifest]
                                         action:@selector(dud:)
                                  keyEquivalent:@""];
        
        [mums setTarget:self];
        [self insertItem:mums atIndex:[self numberOfItems]-2];
    }
}

-(void)addManagedInstallListToMenu{
    NSArray* managedInstals = [delegate installedItems:self];
    if(!managedInstals)return;
    
    NSMenuItem* mums = [[NSMenuItem alloc]initWithTitle:@"Managed Installs"
                                                 action:NULL
                                          keyEquivalent:@""];
    
    
    NSMenu* details = [[NSMenu alloc]init];
    for (NSString* item in managedInstals){
        NSMenuItem* install = [[NSMenuItem alloc]initWithTitle:item action:NULL keyEquivalent:@""];
        
        [details addItem:install];
        
    }
    
    [self setSubmenu:details forItem:mums];
    [self insertItem:mums atIndex:[self numberOfItems]-2];
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
    [self insertItem:mums atIndex:[self numberOfItems]-2];
}

-(void)dud:(id)sender{
}
@end
