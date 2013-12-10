//
//  MUMConfigViewController.m
//  MunkiMenu
//
//  Created by Eldon on 12/10/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "MUMConfigViewController.h"

@interface MUMConfigViewController ()

@end

@implementation MUMConfigViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _popupActive = YES;
    }
    return self;
}

-(IBAction)closePopover:(id)sender{
    [_delegate closePopover];
}

@end
