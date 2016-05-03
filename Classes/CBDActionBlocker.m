//
//  CBDActionBlocker
//
//  Created by Colas Bardavid on 21/oct/2015.
//  Copyright (c) 2015 Colas Bardavid. Licensed under the MIT License.
//

#import "CBDActionBlocker.h"





@interface CBDActionBlocker ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *timersForSecondMethod;
@property (nonatomic, strong, readwrite) NSMutableDictionary *timersForThirdMethod;

@property (nonatomic, strong, readwrite) NSMutableDictionary *timestampsForFirstMethod;
@property (nonatomic, strong, readwrite) NSMutableDictionary *timestampsForSecondMethod;
@property (nonatomic, strong, readwrite) NSMutableDictionary *timestampsForThirdMethod;

@property (nonatomic, strong, readwrite) NSLock *lockForFirstMethod;
@property (nonatomic, strong, readwrite) NSLock *lockForSecondMethod;
@property (nonatomic, strong, readwrite) NSLock *lockForThirdMethod;

@end






@implementation CBDActionBlocker


/**************************************/
#pragma mark - Create global data at initialize
/**************************************/


+ (instancetype)actionBlocker
{
    static id _sharedInstance = nil ;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken,
                  ^{
                      _sharedInstance = [[self alloc] init];
                  });
    
    return _sharedInstance;
}



- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _timersForThirdMethod = [NSMutableDictionary dictionary];
        _timestampsForSecondMethod = [NSMutableDictionary dictionary];
        
        _timestampsForFirstMethod = [NSMutableDictionary dictionary];
        _timestampsForSecondMethod = [NSMutableDictionary dictionary];
        _timestampsForThirdMethod = [NSMutableDictionary dictionary];
        
        _lockForFirstMethod = [[NSLock alloc] init];
        _lockForSecondMethod = [[NSLock alloc] init];
        _lockForThirdMethod = [[NSLock alloc] init];
    }
    
    return self;
}



#pragma mark -
#pragma mark ________________________________________________________________
#pragma mark   ■■■■■■■■■■■■■■ FIRST BLOCKING FEATURE ■■■■■■■■■■■■■■
#pragma mark ________________________________________________________________



/**************************************/
#pragma mark - Main method
/**************************************/

+ (void)ifNotBlockedFireNow:(SEL)selector
                   onTarget:(id)target
              blockingDelay:(NSTimeInterval)blockingDelay;
{
    [[self actionBlocker] fireTarget:target
                            selector:selector
                    blockFiresDuring:blockingDelay];
}


- (void)fireTarget:(id)target
          selector:(SEL)aSelector
  blockFiresDuring:(NSTimeInterval)seconds
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
    [self.lockForFirstMethod lock];
    
    
    /*
     Core
     */
    NSTimeInterval currentTimestamp = [[self class] currentTimestamp];
    
    NSArray *eventKey = [[self class] eventKeyForTarget:target
                                               selector:aSelector
                                  identifierForBlocking:nil];
    
    NSNumber *timestamp;
    
    @synchronized(self.timestampsForFirstMethod)
    {
        timestamp = [self.timestampsForFirstMethod objectForKey:eventKey];
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
    [self.lockForFirstMethod unlock];
}


- (void)fireEffectivelyTarget:(id)target
                     selector:(SEL)aSelector
             blockFiresDuring:(NSTimeInterval)seconds
       withReferenceTimestamp:(NSTimeInterval)currentTimestamp
                      withKey:(id)eventKey
{
    [target performSelectorOnMainThread:aSelector
                             withObject:nil
                          waitUntilDone:NO];
    
    [[self class] registerTimestamp:currentTimestamp+seconds
                             forKey:eventKey
                       inDictionary:self.timestampsForFirstMethod];
}

















#pragma mark -
#pragma mark ________________________________________________________________
#pragma mark   ■■■■■■■■■■■■■■ SECOND BLOCKING FEATURE ■■■■■■■■■■■■■■
#pragma mark ________________________________________________________________


/**************************************/
#pragma mark - Main method
/**************************************/

+ (void)ifNotBlockedFireAfterDelay:(SEL)selector
                          onTarget:(id)target
                         arguments:(nullable NSArray *)arguments
                     blockingDelay:(NSTimeInterval)blockingDelay
             identifierForBlocking:(nullable NSString *)identifierForBlocking
{
    [[self actionBlocker] ifNotBlockedFireAfterDelay:selector
                                            onTarget:target
                                           arguments:arguments
                                       blockingDelay:blockingDelay
                               identifierForBlocking:identifierForBlocking];
}


- (void)ifNotBlockedFireAfterDelay:(SEL)selector
                          onTarget:(id)target
                         arguments:(nullable NSArray *)arguments
                     blockingDelay:(NSTimeInterval)blockingDelay
             identifierForBlocking:(nullable NSString *)identifierForBlocking
{
    /*
     *******
     BARRIER
     *******
     */
    if (!target
        ||
        !selector
        ||
        blockingDelay<0)
    {
        return;
    }
    
    
    
    
    
    /*
     Lock
     */
    [self.lockForSecondMethod lock];
    
    
    /*
     Core
     */
    NSTimeInterval currentTimestamp = [[self class] currentTimestamp];
    
    NSArray *eventKey = [[self class] eventKeyForTarget:target
                                               selector:selector
                                  identifierForBlocking:identifierForBlocking];
    
    
    NSNumber *timestamp;
    @synchronized(self.timestampsForSecondMethod)
    {
        timestamp = [self.timestampsForSecondMethod objectForKey:eventKey];
    }
    
    // the action has already been called
    if (timestamp)
    {
        if (currentTimestamp > [timestamp doubleValue])
        {
            [self ifNotBlockedFireAfterDelay:selector
                                    onTarget:target
                                   arguments:arguments
                               blockingDelay:blockingDelay
                       identifierForBlocking:identifierForBlocking
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
        [self ifNotBlockedFireAfterDelay:selector
                                onTarget:target
                               arguments:arguments
                           blockingDelay:blockingDelay
                   identifierForBlocking:identifierForBlocking
                  withReferenceTimestamp:currentTimestamp
                                 withKey:eventKey];
    }
    
    
    
    /*
     Unlock
     */
    [self.lockForSecondMethod unlock];
}


- (void)ifNotBlockedFireAfterDelay:(SEL)selector
                          onTarget:(id)target
                         arguments:(nullable NSArray *)arguments
                     blockingDelay:(NSTimeInterval)blockingDelay
             identifierForBlocking:(nullable NSString *)identifierForBlocking
            withReferenceTimestamp:(NSTimeInterval)currentTimestamp
                           withKey:(id)eventKey
{
    [[self class] registerTimestamp:currentTimestamp+blockingDelay
                             forKey:eventKey
                       inDictionary:self.timestampsForSecondMethod];
    
    NSDictionary *userInfo = [[self class] userInfoDictionaryWithTarget:target
                                                               selector:selector
                                                              arguments:arguments
                                              withIdentifierForBlocking:identifierForBlocking];
    
    NSTimeInterval delayForTimer = currentTimestamp + blockingDelay - [[self class] currentTimestamp];
    NSTimer *newTimer = [NSTimer scheduledTimerWithTimeInterval:delayForTimer
                                                         target:self
                                                       selector:@selector(performSecondMethod:)
                                                       userInfo:userInfo
                                                        repeats:NO];
    self.timersForSecondMethod[eventKey] = newTimer;
}



- (void)performSecondMethod:(NSTimer *)timer
{
    [[self class] fireTimer:timer
              andRemoveFrom:self.timersForSecondMethod];
}











#pragma mark -
#pragma mark ________________________________________________________________
#pragma mark   ■■■■■■■■■■■■■■ THIRD BLOCKING FEATURE ■■■■■■■■■■■■■■
#pragma mark ________________________________________________________________



+ (void)cancelPreviousCallsAndFireAfterDelay:(SEL)selector
                                    onTarget:(id)target
                                   arguments:(NSArray *)arguments
                                   withDelay:(NSTimeInterval)delayInSeconds
                               resetTheDelay:(BOOL)resetTheDelay
{
    [[self actionBlocker] cancelPreviousCallsAndFireAfterDelay:selector
                                                      onTarget:target
                                                     arguments:arguments
                                                     withDelay:delayInSeconds
                                                 resetTheDelay:resetTheDelay];
}


- (void)cancelPreviousCallsAndFireAfterDelay:(SEL)selector
                                    onTarget:(id)target
                                   arguments:(NSArray *)arguments
                                   withDelay:(NSTimeInterval)delayInSeconds
                               resetTheDelay:(BOOL)resetTheDelay
{
    /*
     *******
     BARRIER
     *******
     */
    if (!target
        ||
        !selector
        ||
        delayInSeconds<0)
    {
        return;
    }
    
    
    
    
    
    /*
     Lock
     */
    [self.lockForThirdMethod lock];
    
    
    
    
    /*
     Core
     */
    NSTimeInterval currentTimestamp = [[self class] currentTimestamp];
    
    NSArray *eventKey = @[target, NSStringFromSelector(selector)];
    
    
    NSNumber *timestamp;
    @synchronized(self.timestampsForThirdMethod)
    {
        timestamp = [self.timestampsForThirdMethod objectForKey:eventKey];
    }
    
    // the action has already been called
    if (timestamp)
    {
        if (currentTimestamp > [timestamp doubleValue])
        {
            [self cancelPreviousCallsAndFireAfterDelay:selector
                                              onTarget:target
                                             arguments:arguments
                                             withDelay:delayInSeconds
                                withReferenceTimestamp:currentTimestamp];
        }
        else
        {
            // We cancel the previous call
            
            NSTimeInterval newDelay = delayInSeconds;
            
            @synchronized(self.timersForThirdMethod)
            {
                NSTimer *timer = self.timersForThirdMethod[eventKey];
                if (resetTheDelay)
                {
                    newDelay = delayInSeconds - timer.fireDate.timeIntervalSinceNow;
                    newDelay = newDelay<0?0:newDelay;
                }
                
                [timer invalidate];
            }
            
            
            [self cancelPreviousCallsAndFireAfterDelay:selector
                                              onTarget:target
                                             arguments:arguments
                                             withDelay:newDelay
                                withReferenceTimestamp:currentTimestamp];
        }
    }
    
    
    // the action has never been called
    else
    {
        [self cancelPreviousCallsAndFireAfterDelay:selector
                                          onTarget:target
                                         arguments:arguments
                                         withDelay:delayInSeconds
                            withReferenceTimestamp:currentTimestamp];
    }
    
    
    
    
    /*
     Unlock
     */
    [self.lockForThirdMethod unlock];
}



- (void)cancelPreviousCallsAndFireAfterDelay:(SEL)selector
                                    onTarget:(id)target
                                   arguments:(NSArray *)arguments
                                   withDelay:(NSTimeInterval)delayInSeconds
                      withReferenceTimestamp:(NSTimeInterval)currentTimestamp
{
    NSArray *eventKey = @[target, NSStringFromSelector(selector)];
    
    /*
     We register the timestamp
     */
    [[self class] registerTimestamp:currentTimestamp+delayInSeconds
                             forKey:eventKey
                       inDictionary:self.timestampsForThirdMethod];
    
    
    /*
     Core
     */
    NSDictionary *userInfo = [[self class] userInfoDictionaryWithTarget:target
                                                               selector:selector
                                                              arguments:arguments
                                              withIdentifierForBlocking:nil];
    
    NSTimer *newTimer;
    newTimer = [NSTimer scheduledTimerWithTimeInterval:delayInSeconds
                                                target:self
                                              selector:@selector(performThirdMethod:)
                                              userInfo:userInfo
                                               repeats:NO];
    
    @synchronized(self.timersForThirdMethod)
    {
        self.timersForThirdMethod[eventKey] = newTimer;
    }
}



- (void)performThirdMethod:(NSTimer *)timer
{
    [[self class] fireTimer:timer
              andRemoveFrom:self.timersForThirdMethod];
}





#pragma mark -
#pragma mark ________________________________________________________________
#pragma mark   ■■■■■■■■■■■■■■ PERFORM ALL PENDING ACTIONS ■■■■■■■■■■■■■■
#pragma mark ________________________________________________________________


+ (void)performAllPendingActions
{
    [[self actionBlocker] performAllPendingActions];
}


- (void)performAllPendingActions
{
    /*
     For the thid method
     */
    for (NSTimer *timer in self.timersForSecondMethod)
    {
        [self performSecondMethod:timer];
    }
    
    /*
     For the thid method
     */
    for (NSTimer *timer in self.timersForThirdMethod)
    {
        [self performThirdMethod:timer];
    }
}







#pragma mark -
#pragma mark ________________________________________________________________
#pragma mark   ■■■■■■■■■■■■■■ AUX METHODS ■■■■■■■■■■■■■■
#pragma mark ________________________________________________________________


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
                     withIdentifierForBlocking:(NSString *)identifierForBlocking
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
    
    if (identifierForBlocking)
    {
        [userInfo setObject:identifierForBlocking
                     forKey:@"identifierForBlocking"];
    }
    
    return userInfo;
}




+ (void)fireTimer:(NSTimer *)timer
    andRemoveFrom:(NSMutableDictionary *)dictionaryOfTimers
{
    @synchronized(timer)
    {
        if ([timer isValid])
        {
            /*
             We get the infos
             */
            NSDictionary *userInfo = [timer userInfo];
            
            id target = userInfo[@"target"];
            SEL selector = [userInfo[@"selector"] pointerValue];
            NSArray *arguments = userInfo[@"arguments"];
            NSString *identifierForBlocking = userInfo[@"identifierForBlocking"];
            
            
            
            /*
             We invalidate the timer
             */
            [timer invalidate];
            
            
            
            /*
             We release the timer
             */
            NSArray *eventKey = [self eventKeyForTarget:target
                                               selector:selector
                                  identifierForBlocking:identifierForBlocking];
            
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
    }
}




+ (id)eventKeyForTarget:(id)target
               selector:(SEL)selector
  identifierForBlocking:(NSString *)identifierForBlocking
{
    NSArray *eventKey;
    
    if (!identifierForBlocking)
    {
        eventKey = @[target, NSStringFromSelector(selector)];
    }
    else
    {
        eventKey = @[target, NSStringFromSelector(selector), identifierForBlocking];
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
