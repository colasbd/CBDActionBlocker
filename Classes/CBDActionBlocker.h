//
//  CBDActionBlocker
//
//  Created by Colas Bardavid on 21/oct/2015.
//  Copyright (c) 2015 Colas Bardavid. Licensed under the MIT License.
//

#import <Foundation/Foundation.h>

@interface CBDActionBlocker : NSObject

/**
 This method fires the selector (now) 
 unless this method was previsously called (with the same `target` and `selector`)
 with a delay "still active"
 */
+ (void)ifNotBlockedFireNow:(SEL)selector
                   onTarget:(id)target
              blockingDelay:(NSTimeInterval)blockingDelay;

// OLD API
//+ (void)fireTarget:(id)target
//          selector:(SEL)aSelector
//  blockFiresDuring:(NSTimeInterval)seconds;



/**
 This method fires the selector after the given time interval
 and block any call that would be done during this interval.
 
 The selector can have arguments.
 
 The blocking does not depend on the argument: if the same `(target, aSelector)`
 is called with different arguments, the blocking will still happen.
 
 To prevent this, you can condition the blocking to the equality of the `blockingFlag`.
 That means that same `(target, aSelector)` will be blocked if they are
 called with the same blockingFlag.
 
 This methods achieves "debouncing with arguments".
 */

+ (void)ifNotBlockedFireAfterDelay:(SEL)selector
                          onTarget:(id)target
                         arguments:(nullable NSArray *)arguments
                     blockingDelay:(NSTimeInterval)blockingDelay
             identifierForBlocking:(nullable NSString *)identifierForBlocking;


// OLD API
//+ (void)waitAndBlockThenFireTarget:(id)target
//                          selector:(SEL)aSelector
//                         arguments:(NSArray *)arguments
//                             delay:(NSTimeInterval)delayInSeconds
//                  withBlockingFlag:(NSString *)blockingFlag;





/**
 This method removes the previous action that was scheduled by a new one.
 The comparison of the actions is made only depending on `target` and `aSelector`.
 During the given delay, the next calls to this method will again remove the previous calls.
 
 So, the argument used with `target` and `aSelector` will be the last one given.
 
 If `resetingTheDelay` is set to YES, the `delayInSeconds` will be started again.
 
 If not, the previous delay will be used.
 */

+ (void)cancelPreviousCallsAndFireAfterDelay:(SEL)selector
                                    onTarget:(id)target
                                   arguments:(nullable NSArray *)arguments
                                   withDelay:(NSTimeInterval)delayInSeconds
                               resetTheDelay:(BOOL)resetTheDelay;

// OLD API
//+ (void)fireAndCancelPreviousCallsWithTarget:(id)target
//                                    selector:(SEL)aSelector
//                                   arguments:(NSArray *)arguments
//                                   withDelay:(NSTimeInterval)delayInSeconds
//                               resetTheDelay:(BOOL)resetingTheDelay;




#pragma mark - Perform all pending actions

+ (void)performAllPendingActions;



@end