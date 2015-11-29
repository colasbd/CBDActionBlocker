//
//  CBDActionBlocker
//
//  Created by Colas Bardavid on 21/oct/2015.
//  Copyright (c) 2015 Colas Bardavid. Licensed under the MIT License.
//

#import "CBDActionBlocker.h"

static NSMutableDictionary *timestamps = nil;

@implementation CBDActionBlocker


/**************************************/
#pragma mark - Create global data at initialize
/**************************************/


+ (void)initialize
{
    if (self == [CBDActionBlocker class])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            timestamps = [NSMutableDictionary dictionary];
            
        });
    }
}




/**************************************/
#pragma mark - Main method
/**************************************/



+ (void)fireTarget:(id)target selector:(SEL)aSelector blockFiresDuring:(NSTimeInterval)seconds resetBlocking:(BOOL)resetBlocking
{
    @synchronized(self)
    {
        NSTimeInterval currentTimestamp = [self currentTimestamp];
        
        NSArray *eventKey = @[target, NSStringFromSelector(aSelector)];
        NSNumber *timestamp = [timestamps objectForKey:eventKey];
        
        // the action has already been called
        if (timestamp) {
            if (currentTimestamp < [timestamp doubleValue])
            {
                // we do nothing
                // unless...
                if (resetBlocking)
                {
                    [self fireEffectivelyTarget:target
                                       selector:aSelector
                               blockFiresDuring:seconds
                         withReferenceTimestamp:currentTimestamp
                                        withKey:eventKey];
                }
            }
            
            
            // the 'blocking time' has been passed over
            else
            {
                [self fireEffectivelyTarget:target
                                   selector:aSelector
                           blockFiresDuring:seconds
                     withReferenceTimestamp:currentTimestamp
                                    withKey:eventKey];
            }
        }
        
        
        // the action has never been called
        else
        {
            [self fireEffectivelyTarget:target
                               selector:aSelector
                       blockFiresDuring:seconds
                 withReferenceTimestamp:currentTimestamp
                                withKey:eventKey];
        }
    }
}


+ (void)fireEffectivelyTarget:(id)target
                     selector:(SEL)aSelector
             blockFiresDuring:(NSTimeInterval)seconds
       withReferenceTimestamp:(NSTimeInterval)currentTimestamp
                      withKey:(id)eventKey
{
    [self fireTarget:target selector:aSelector];
    [self registerTimestamp:currentTimestamp+seconds forKey:eventKey];
}






/**************************************/
#pragma mark - Aux methods
/**************************************/


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
