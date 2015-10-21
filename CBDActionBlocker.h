//
//  CBDActionBlocker
//
//  Created by Colas Bardavid on 21/oct/2015.
//  Copyright (c) 2015 Colas Bardavid. Licensed under the MIT License.
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