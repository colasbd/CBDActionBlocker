//
//  CBDActionBlocker
//
//  Created by Colas Bardavid on 21/oct/2015.
//  Copyright (c) 2015 Colas Bardavid. Licensed under the MIT License.
//

#import "CBDActionBlocker.h"



static NSMutableDictionary *retainedTargetAndArgumentsForSecondMethod = nil;

static NSMutableDictionary *timersForSecondMethod = nil;
static NSMutableDictionary *timersForThirdMethod = nil;

static NSMutableDictionary *timestampsForFirstMethod = nil;
static NSMutableDictionary *timestampsForSecondMethod = nil;
static NSMutableDictionary *timestampsForThirdMethod = nil;

static NSLock *lockForFirstMethod = nil;
static NSLock *lockForSecondMethod = nil;
static NSLock *lockForThirdMethod = nil;

static NSTimeInterval const kEpsilon = 0.0001f;


@implementation CBDActionBlocker


/**************************************/
#pragma mark - Create global data at initialize
/**************************************/


+ (void)initialize
{
    if (self == [CBDActionBlocker class])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
                      {
                          retainedTargetAndArgumentsForSecondMethod = [NSMutableDictionary dictionary];
                          
                          timersForThirdMethod = [NSMutableDictionary dictionary];
                          timestampsForSecondMethod = [NSMutableDictionary dictionary];
                          
                          timestampsForFirstMethod = [NSMutableDictionary dictionary];
                          timestampsForSecondMethod = [NSMutableDictionary dictionary];
                          timestampsForThirdMethod = [NSMutableDictionary dictionary];
                          
                          lockForFirstMethod = [[NSLock alloc] init];
                          lockForSecondMethod = [[NSLock alloc] init];
                          lockForThirdMethod = [[NSLock alloc] init];
                      });
    }
}




#pragma mark -
#pragma mark ________________________________________________________________
#pragma mark   ■■■■■■■■■■■■■■ FIRST BLOCKING FEATURE ■■■■■■■■■■■■■■
#pragma mark ________________________________________________________________



/**************************************/
#pragma mark - Main method
/**************************************/


+ (void)fireTarget:(id)target selector:(SEL)aSelector blockFiresDuring:(NSTimeInterval)seconds
{
    /*
     *******
     BARRIER
     *******
     */
    if (!target
        ||
        !aSelector
        ||
        seconds<0)
    {
        return;
    }
    
    
    
    /*
     *******
     CORE
     *******
     */
    
    /*
     Lock
     */
    [lockForFirstMethod lock];
    
    
    /*
     Core
     */
    NSTimeInterval currentTimestamp = [self currentTimestamp];
    
    NSArray *eventKey = [self eventKeyForTarget:target
                                       selector:aSelector
                                   blockingFlag:nil];

    NSNumber *timestamp;
    
    @synchronized(timestampsForFirstMethod)
    {
        timestamp = [timestampsForFirstMethod objectForKey:eventKey];
    }
    
    // the action has already been called
    if (timestamp)
    {
        if (currentTimestamp < [timestamp doubleValue])
        {
            // we do nothing
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
    
    
    
    /*
     Unlock
     */
    [lockForFirstMethod unlock];
}


+ (void)fireEffectivelyTarget:(id)target
                     selector:(SEL)aSelector
             blockFiresDuring:(NSTimeInterval)seconds
       withReferenceTimestamp:(NSTimeInterval)currentTimestamp
                      withKey:(id)eventKey
{
    [target performSelectorOnMainThread:aSelector
                             withObject:nil
                          waitUntilDone:NO];

    // jojo check this
//    [self fireTarget:target selector:aSelector arguments:nil delay:0 withKey:eventKey];
    
    [self registerTimestamp:currentTimestamp+seconds
                     forKey:eventKey
               inDictionary:timestampsForFirstMethod];
    
}

















#pragma mark -
#pragma mark ________________________________________________________________
#pragma mark   ■■■■■■■■■■■■■■ SECOND BLOCKING FEATURE ■■■■■■■■■■■■■■
#pragma mark ________________________________________________________________


/**************************************/
#pragma mark - Main method
/**************************************/

+ (void)waitAndBlockThenFireTarget:(id)target
                          selector:(SEL)aSelector
                         arguments:(NSArray *)arguments
                             delay:(NSTimeInterval)seconds
                  withBlockingFlag:(NSString *)blockingFlag
{
    /*
     *******
     BARRIER
     *******
     */
    if (!target
        ||
        !aSelector
        ||
        seconds<0)
    {
        return;
    }
    
    
    
    
    
    /*
     Lock
     */
    [lockForSecondMethod lock];
    
    
    /*
     Core
     */
    NSTimeInterval currentTimestamp = [self currentTimestamp];
    
    NSArray *eventKey = [self eventKeyForTarget:target
                                       selector:aSelector
                                   blockingFlag:blockingFlag];
    
    
    NSNumber *timestamp;
    @synchronized(timestampsForSecondMethod)
    {
        timestamp = [timestampsForSecondMethod objectForKey:eventKey];
    }
    
    // the action has already been called
    if (timestamp)
    {
        if (currentTimestamp > [timestamp doubleValue])
        {
            [self waitAndBlockThenFireEffectivelyTarget:target
                                               selector:aSelector
                                               arguments:arguments
                                       withBlockingFlag:blockingFlag
                                                  delay:seconds
                                 withReferenceTimestamp:currentTimestamp
                                                withKey:eventKey];
        }
        else
        {
            // We do nothing, meaning: we block
        }
    }
    
    
    // the action has never been called
    else
    {
        [self waitAndBlockThenFireEffectivelyTarget:target
                                           selector:aSelector
                                           arguments:arguments
                                   withBlockingFlag:blockingFlag
                                              delay:seconds
                             withReferenceTimestamp:currentTimestamp
                                            withKey:eventKey];
    }
    
    
    
    /*
     Unlock
     */
    [lockForSecondMethod unlock];
}


+ (void)waitAndBlockThenFireEffectivelyTarget:(id)target
                                     selector:(SEL)aSelector
                                    arguments:(NSArray *)arguments
                             withBlockingFlag:(NSString *)blockingFlag
                                        delay:(NSTimeInterval)seconds
                       withReferenceTimestamp:(NSTimeInterval)currentTimestamp
                                      withKey:(id)eventKey
{
    // jojo see and delete
//    [self fireTarget:target selector:aSelector arguments:arguments delay:seconds withKey:eventKey];
    
    [self registerTimestamp:currentTimestamp+seconds
                     forKey:eventKey
               inDictionary:timestampsForSecondMethod];
    
    NSDictionary *userInfo = [self userInfoDictionaryWithTarget:target
                                                       selector:aSelector
                                                      arguments:arguments
                                               withBlockingFlag:blockingFlag];
    
    NSTimer *newTimer = [NSTimer scheduledTimerWithTimeInterval:currentTimestamp+seconds
                                                         target:self
                                                       selector:@selector(performSecondMethod:)
                                                       userInfo:userInfo
                                                        repeats:NO];
    

    // jojo see and remove
//    /*
//     We remove the key once done
//     */
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
//                                 (int64_t)(currentTimestamp+seconds * NSEC_PER_SEC)),
//                   dispatch_get_main_queue(), ^{
//                       @synchronized(timestampsForSecondMethod)
//                       {
//                           timestampsForSecondMethod[eventKey] = nil;
//                       }
//                   });
}



+ (void)performSecondMethod:(NSTimer *)timer
{
    /*
     We get the infos
     */
    NSDictionary *userInfo = [timer userInfo];
    
    id target = userInfo[@"target"];
    SEL selector = [userInfo[@"selector"] pointerValue];
    NSArray *arguments = userInfo[@"arguments"];
    
    
    
    /*
     We invalidate the timer
     */
    [timer invalidate];
    
    
    
    /*
     We release the timer
     */
    NSArray *eventKey = @[target, NSStringFromSelector(selector)];
    @synchronized(timersForThirdMethod)
    {
        timersForThirdMethod[eventKey] = nil;
    }
    
    
    /*
     Core
     */
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self performInvocationForTarget:target
                                           withSelector:selector
                                           andArguments:arguments];
                   });
}


#pragma mark -
#pragma mark ________________________________________________________________
#pragma mark   ■■■■■■■■■■■■■■ THIRD BLOCKING FEATURE ■■■■■■■■■■■■■■
#pragma mark ________________________________________________________________



+ (void)fireAndCancelPreviousCallsWithTarget:(id)target
                                    selector:(SEL)aSelector
                                   arguments:(NSArray *)arguments
                                   withDelay:(NSTimeInterval)delayInSeconds
{
    /*
     *******
     BARRIER
     *******
     */
    if (!target
        ||
        !aSelector
        ||
        delayInSeconds<0)
    {
        return;
    }
    
    
    
    
    
    /*
     Lock
     */
    [lockForThirdMethod lock];
    
    

    
    /*
     Core
     */
    NSTimeInterval currentTimestamp = [self currentTimestamp];
    
    NSArray *eventKey = @[target, NSStringFromSelector(aSelector)];
    
    
    NSNumber *timestamp;
    @synchronized(timestampsForThirdMethod)
    {
        timestamp = [timestampsForThirdMethod objectForKey:eventKey];
    }
    
    // the action has already been called
    if (timestamp)
    {
        if (currentTimestamp > [timestamp doubleValue])
        {
            [self fireAndCancelPreviousCallsEffectivelyWithTarget:target
                                                         selector:aSelector
                                                        arguments:arguments
                                                        withDelay:delayInSeconds
                                           withReferenceTimestamp:currentTimestamp];
        }
        else
        {
            // We cancel the previous call
            
            @synchronized(timersForThirdMethod)
            {
                NSTimer *timer = timersForThirdMethod[eventKey];
                [timer invalidate];
            }
            
            [self fireAndCancelPreviousCallsEffectivelyWithTarget:target
                                                         selector:aSelector
                                                        arguments:arguments
                                                        withDelay:delayInSeconds
                                           withReferenceTimestamp:currentTimestamp];
        }
    }
    
    
    // the action has never been called
    else
    {
       [self fireAndCancelPreviousCallsEffectivelyWithTarget:target
                                                    selector:aSelector
                                                   arguments:arguments
                                                   withDelay:delayInSeconds
                                      withReferenceTimestamp:currentTimestamp];
    }
    
    
    
    
    /*
     Unlock
     */
    [lockForThirdMethod unlock];
}




+ (void)fireAndCancelPreviousCallsEffectivelyWithTarget:(id)target
                                               selector:(SEL)aSelector
                                              arguments:(NSArray *)arguments
                                              withDelay:(NSTimeInterval)delayInSeconds
                                 withReferenceTimestamp:(NSTimeInterval)currentTimestamp
{
    NSArray *eventKey = @[target, NSStringFromSelector(aSelector)];
    
    /*
     We register the timestamp
     */
    [self registerTimestamp:currentTimestamp+delayInSeconds
                     forKey:eventKey
               inDictionary:timestampsForThirdMethod];
    
    
    /*
     Core
     */
    NSDictionary *userInfo = [self userInfoDictionaryWithTarget:target
                                                       selector:aSelector
                                                      arguments:arguments];

    NSTimer *newTimer;
    newTimer = [NSTimer scheduledTimerWithTimeInterval:delayInSeconds
                                                target:self
                                              selector:@selector(performThirdMethod:)
                                              userInfo:userInfo
                                               repeats:NO];
    
    @synchronized(timersForThirdMethod)
    {
        timersForThirdMethod[eventKey] = newTimer;
    }
}



+ (void)performThirdMethod:(NSTimer *)timer
{
    /*
     We get the infos
     */
    NSDictionary *userInfo = [timer userInfo];
    
    id target = userInfo[@"target"];
    SEL selector = [userInfo[@"selector"] pointerValue];
    NSArray *arguments = userInfo[@"arguments"];
    
    
    
    /*
     We invalidate the timer
     */
    [timer invalidate];

    
    
    /*
     We release the timer
     */
    NSArray *eventKey = @[target, NSStringFromSelector(selector)];
    @synchronized(timersForThirdMethod)
    {
        timersForThirdMethod[eventKey] = nil;
    }
    
    
    /*
     Core
     */
    dispatch_async(dispatch_get_main_queue(),
                   ^{                       
                       [self performInvocationForTarget:target
                                           withSelector:selector
                                           andArguments:arguments];
                   });
}




#pragma mark -
#pragma mark ________________________________________________________________
#pragma mark   ■■■■■■■■■■■■■■ AUX METHODS ■■■■■■■■■■■■■■
#pragma mark ________________________________________________________________



//+ (void)fireTarget:(id)target
//          selector:(SEL)aSelector
//         arguments:(NSArray *)arguments
//             delay:(NSTimeInterval)delay
//           withKey:(id)eventKey
//{
//    // We suppress the warning
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//    
//    /*
//     We retain the arguments
//     */
//    if (eventKey)
//    {
//        if (arguments)
//        {
//            retainedTargetAndArgumentsForSecondMethod[eventKey] = @[target, arguments];
//        }
//        else
//        {
//            retainedTargetAndArgumentsForSecondMethod[eventKey] = target;
//        }
//    }
//    
//    
//    if (delay < kEpsilon)
//    {
//        dispatch_async(dispatch_get_main_queue(),
//                       ^{
//                           [[self class] performInvocationForTarget:target
//                                                       withSelector:aSelector
//                                                       andArguments:arguments];
//                           
//                           /*
//                            We release the arguments
//                            */
//                            if (eventKey)
//                            {
//                                retainedTargetAndArgumentsForSecondMethod[eventKey] = nil;
//                            }
//                       });
//    }
//    else
//    {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(),
//                       ^{
//                           [self fireTarget:target
//                                   selector:aSelector
//                                  arguments:arguments
//                                      delay:0
//                                    withKey:nil];
//                       });
//    }
//
//#pragma clang diagnostic pop
//    
//}





/**************************************/
#pragma mark - Managing timers
/**************************************/


+ (void)registerTimestamp:(NSTimeInterval)timestamp
                   forKey:(id)key
             inDictionary:(NSMutableDictionary *)dictionary
{
    @synchronized(dictionary)
    {
        [dictionary setObject:@(timestamp)
                       forKey:key];
    }
}


+ (NSTimeInterval)currentTimestamp
{
    return [[NSDate date] timeIntervalSinceReferenceDate];
}







/**************************************/
#pragma mark - Managing timers
/**************************************/


+ (NSDictionary *)userInfoDictionaryWithTarget:(id)target
                                      selector:(SEL)aSelector
                                     arguments:(NSArray *)arguments
                              withBlockingFlag:(NSString *)blockingFlag
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    /*
     First entries
     */
    [userInfo addEntriesFromDictionary:@{@"target" : target,
                                         @"selector" : [NSValue valueWithPointer:aSelector]}];
    
    /*
     Optional entries
     */
    if (arguments)
    {
        [userInfo setObject:arguments
                     forKey:@"arguments"];
    }
    
    if (blockingFlag)
    {
        [userInfo setObject:blockingFlag
                     forKey:@"blockingFlag"];
    }
    
    return userInfo;
}




+ (void)fireTimer:(NSTimer *)timer
    andRemoveFrom:(NSMutableDictionary *)dictionaryOfTimers
{
    /*
     We get the infos
     */
    NSDictionary *userInfo = [timer userInfo];
    
    id target = userInfo[@"target"];
    SEL selector = [userInfo[@"selector"] pointerValue];
    NSArray *arguments = userInfo[@"arguments"];
    NSString *blockingFlag = userInfo[@"blockingFlag"];
    
    
    
    /*
     We invalidate the timer
     */
    [timer invalidate];
    
    
    
    /*
     We release the timer
     */
    NSArray *eventKey = [self eventKeyForTarget:target
                                       selector:selector
                                   blockingFlag:blockingFlag];
  
    @synchronized(dictionaryOfTimers)
    {
        dictionaryOfTimers[eventKey] = nil;
    }
    
    
    /*
     Core
     */
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self performInvocationForTarget:target
                                           withSelector:selector
                                           andArguments:arguments];
                   });
}




+ (id)eventKeyForTarget:(id)target
               selector:(SEL)selector
           blockingFlag:(NSString *)blockingFlag
{
    NSArray *eventKey;
    
    if (!blockingFlag)
    {
        eventKey = @[target, NSStringFromSelector(selector)];
    }
    else
    {
        eventKey = @[target, NSStringFromSelector(selector), blockingFlag];
    }
    
    return eventKey;
}








#pragma mark -
#pragma mark ________________________________________________________________
#pragma mark   ■■■■■■■■■■■■■■ INVOCATION ■■■■■■■■■■■■■■
#pragma mark ________________________________________________________________


/*
 From
 https://github.com/seivan/SHInvocation
 */

+ (NSInvocation *)invocationForTarget:(id)theTarget
                         withSelector:(SEL)theSelector
                         andArguments:(NSArray *)theArguments
{
    NSInvocation *result;
    
    if (!theSelector
        ||
        !theTarget)
    {
       // do nothing
    }
    else
    {
        NSMethodSignature *signature = [theTarget methodSignatureForSelector:theSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:theTarget];
        [invocation setSelector:theSelector];
        [theArguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             idx += 2;
             [invocation setArgument:&obj atIndex:idx];
         }];

        result = invocation;
    }
    
    
    return result;
}



+ (void)performInvocationForTarget:(id)theTarget
                     withSelector:(SEL)theSelector
                     andArguments:(NSArray *)theArguments
{
    NSInvocation *invocation = [self invocationForTarget:theTarget
                                            withSelector:theSelector
                                            andArguments:theArguments];
    
    [invocation invoke];
}



@end
