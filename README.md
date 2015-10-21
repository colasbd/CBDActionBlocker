LVDebounce
==========

An Objective-C library for blocking actions depending on when they were previously launched.

## Installation

Put this in your Podfile and smoke it:

```ruby
pod 'CBDActionBlocker'
```


## One method

This pod has only one method:

```Objective-C
+ (void)fireTarget:(id)target selector:(SEL)aSelector blockFiresDuring:(NSTimeInterval)seconds resetBlocking:(BOOL)resetBlocking;
```

## Usage

It's a pretty simple frameword, inspired by [`LVDebounce`](https://github.com/layervault/LVDebounce).

Here's a trite example:

```Objective-C
#import "CBDActionBlocker.h"

- (void)helloWorld {
    NSLog(@"Hello, World!"); // Will only run once
}

- (void)applicationDidFinishLaunching {
  for (int i = 0; i < 10; i++) {
      [CBDActionBlocker fireTarget:self selector:@selector(helloWorld) blockFiresDuring:1.0 resetBlocking:NO];
  }
}
```

## The `resetBlocking` option

The `resetBlocking` option does the following:

If an `action` has been fired at time `100` with a `10`s blocking,
and if at time `105`, the `action` is asked to be fired with a `10`s blocking:
    - with `resetBlocking:YES`, it will not be fired and be blocked until `115`
    - with `resetBlocking:NO`, it will not be fired but will still be blocked until `110`


That's all there is to it.
