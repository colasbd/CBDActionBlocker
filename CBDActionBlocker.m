//
//  LVDebounce.m
//  LayerVault
//
//  Created by Kelly Sutton on 7/23/13.
//  Copyright (c) 2013 LayerVault. Licensed under the MIT License.
//

#import "CBDActionBlocker.h"

static NSMutableDictionary *timestamps = nil;

@implementation CBDActionBlocker

+ (void)initialize
{    
    if (self == [CBDActionBlocker class]
        &&
        !timestamps)
    {
        timestamps = [NSMutableDictionary dictionary];
    }
}

+ (void)fireTarget:(id)target selector:(SEL)aSelector  blockFiresDuring:(NSTimeInterval)seconds resetBlocking:(BOOL)resetBlocking
{
    @synchronized(self)
    {
        NSTimeInterval currentTimestamp = [self currentTimestamp];
        
        NSArray *eventKey = @[target, NSStringFromSelector(aSelector)];
        NSNumber *timestamp = [timestamps objectForKey:eventKey];
        
        if (timestamp) {
            
            if ([timestamp doubleValue] < currentTimestamp)
            {
                if (resetBlocking)
                {
                    [self registerTimestamp:currentTimestamp+seconds forKey:eventKey];
                }
            }
            else
            {
                [self fireTarget:target selector:aSelector];
                [self registerTimestamp:currentTimestamp+seconds
                                 forKey:eventKey];
            }
        }

        [self fireTarget:target selector:aSelector];
        [self registerTimestamp:currentTimestamp+seconds forKey:eventKey];
    }
}



+ (void)fireTarget:(id)target selector:(SEL)aSelector
{
    // We suppress the warning
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [target performSelector:aSelector];
#pragma clang diagnostic pop
}


+ (void)registerTimestamp:(NSTimeInterval)timestamp forKey:(id)key
{
    [timestamps setObject:@(timestamp)
                   forKey:key];
}

                
+ (NSTimeInterval)currentTimestamp
{
    return [[NSDate date] timeIntervalSinceReferenceDate];
}

@end
