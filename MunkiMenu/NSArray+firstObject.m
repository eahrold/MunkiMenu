//
//  NSArray+firstObject.m
//  MunkiMenu
//
//  Created by Eldon on 4/10/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import "NSArray+firstObject.h"

@implementation NSArray (firstObject)

- (id)firstObject
{
    if ([self count] > 0)
    {
        return [self objectAtIndex:0];
    }
    return nil;
}
@end
