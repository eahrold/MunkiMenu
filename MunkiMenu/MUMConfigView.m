//
//  MUMConfigViewController.m
//  MunkiMenu
//
//  Created by Eldon on 12/10/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMConfigView.h"

@implementation MUMConfigView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    
    }
    return self;
}

-(IBAction)closeView:(id)sender{
    [_delegate closeConfigView];
}

-(IBAction)configurePressed:(id)sender{
    [_delegate configureMunki];
}

@end
