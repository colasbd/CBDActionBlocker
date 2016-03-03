//
//  CBDActionBlocker
//
//  Created by Colas Bardavid on 21/oct/2015.
//  Copyright (c) 2015 Colas Bardavid. Licensed under the MIT License.
//

#import <Foundation/Foundation.h>

@interface CBDActionBlocker : NSObject

/**
 This method fires the selector unless it is blocked.
 */
+ (void)fireTarget:(id)target
          selector:(SEL)aSelector
  blockFiresDuring:(NSTimeInterval)seconds;



/**
 This method fires the selector after the given time interval
 and block any call that would be done during this interval.
 
 The selector can have arguments.
 
 The blocking does not depend on the argument: if the same `(target, aSelector)`
 is called with different arguments, the blocking will still happen.
 
 To prevent this, you can condition the blocking to the equality of the `blockingFlag`.
 That means that same `(target, aSelector)` will be blocked if they are
 called with the same blockingFlag.
 
 *----*
 
 So, this debouncing with arguments.
 */
+ (void)waitAndBlockThenFireTarget:(id)target
                          selector:(SEL)aSelector
                         arguments:(NSArray *)arguments
                             delay:(NSTimeInterval)delayInSeconds
                  withBlockingFlag:(NSString *)blockingFlag;







+ (void)fireAndCancelPreviousCallsWithTarget:(id)target
                                    selector:(SEL)aSelector
                                   arguments:(NSArray *)arguments
                                   withDelay:(NSTimeInterval)delayInSeconds
                               resetTheDelay:(BOOL)resetingTheDelay;




#pragma mark - Perform all pending actions

+ (void)performAllPendingActions;



@end