//
//  LVDebounce.h
//  LayerVault
//
//  Created by Kelly Sutton on 7/23/13.
//  Copyright (c) 2013 LayerVault. Licensed under the MIT License.
//

#import <Foundation/Foundation.h>

@interface CBDActionBlocker : NSObject

/**
 This methods fires the selector unless it is blocked.
 If the method is blocked, depending on the value of `resetBlocking`,
 we reset the blocker to 0 or not.
 */
+ (void)fireTarget:(id)target selector:(SEL)aSelector blockFiresDuring:(NSTimeInterval)seconds resetBlocking:(BOOL)resetBlocking;

@end