//
//  NSTextField+fieldIsBlank.m
//  ODUserMaker
//
//  Created by Eldon on 11/18/13.
//  Copyright (c) 2013 Eldon Ahrold. All rights reserved.
//

#import "NSString(TextField)+isNotBlank.h"

@implementation NSTextField (isNotBlank)

-(BOOL)isNotBlank{
    if([self.stringValue isEqualToString:@""]||
       !self.stringValue){
           return NO;
       }
    return YES;
}

-(BOOL)isBlank{
    if([self.stringValue isEqualToString:@""]||
       !self.stringValue){
        return YES;
    }
    return NO;
}
@end

@implementation NSString (isNotBlank)

-(BOOL)isNotBlank{
    if([self isEqualToString:@""]||
       !self){
        return NO;
    }
    return YES;
}

-(BOOL)isBlank{
    if([self isEqualToString:@""]||
       !self){
        return YES;
    }
    return NO;
}
@end