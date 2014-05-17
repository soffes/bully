//
//  NSTimer+BLYWeakTimerAdditions.m
//  Bully
//
//  Created by Richard Heard on 17/05/2014.
//  Copyright (c) 2014 Richard Heard. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:

//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSTimer+BLYWeakTimerAdditions.h"

@interface BLYWeakValue : NSObject {
    id __weak _weakValue;
}

+ (instancetype)weakValueWithObject:(id)object;
- (instancetype)initWithObject:(id)object;
@property (weak, readonly) id weakValue;

@end

@implementation NSTimer (BLYWeakTimerAdditions)

+ (NSTimer *)bly_scheduledTimerWithTimeInterval:(NSTimeInterval)ti weakTarget:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo {
    id weakTarget = [BLYWeakValue weakValueWithObject:target];
    return [NSTimer scheduledTimerWithTimeInterval:ti target:weakTarget selector:aSelector userInfo:userInfo repeats:yesOrNo];
}

@end


@implementation BLYWeakValue
@synthesize weakValue=_weakValue;

+ (instancetype)weakValueWithObject:(id)object{
    return [[self alloc] initWithObject:object];
}

- (instancetype)initWithObject:(id)object{
    self = [super init];
    if (self){
        _weakValue = object;
    }
    return self;
}

- (id)weakValue{
    return _weakValue;
}

- (BOOL)isEqual:(BLYWeakValue *)object {
    if (![object isKindOfClass:[BLYWeakValue class]]) return NO;
    return object.weakValue == self.weakValue;
}

- (NSString*)description{
    return [NSString stringWithFormat:@"<%@: %p, weakValue: %@>", NSStringFromClass(self.class), self, _weakValue];
}

// allow forwarding (for use by timers etc.)
- (id)forwardingTargetForSelector:(SEL)aSelector{
    id value = _weakValue;
    return value ? : [super forwardingTargetForSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    id target = _weakValue;
    
    if (!target){
        //make one up, (this forces a call to forwardInvocation) it's never actually used by forwardInvocation, however this allows us to ignore/raise for the erroneous call.
        return [NSMethodSignature signatureWithObjCTypes:[[NSString stringWithFormat:@"%s%s%s", @encode(void), @encode(id), @encode(SEL)] UTF8String]];
    }
    
    //query the target, if it succeeds, return it, default forwarding flow
    NSMethodSignature *targetSignature = [target methodSignatureForSelector:aSelector];
    if (targetSignature) return targetSignature;
    
    //default behaviour
    return [super methodSignatureForSelector:aSelector];
    
}

- (void)forwardInvocation:(NSInvocation *)anInvocation{
    id target = _weakValue;
    
    if (target){
        [anInvocation invokeWithTarget:target];
    }
    
    /* no-op */
}

@end
