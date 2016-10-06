//
//  Run.m
//  RuntimeDemo
//
//  Created by Tangtang on 2016/10/4.
//  Copyright © 2016年 Tangtang. All rights reserved.
//

#import "Run.h"

@implementation Run

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    NSLog(@"------resolveInstanceMethod");
    
    return [super resolveInstanceMethod:sel];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSLog(@"----forwardingTargetForSelector");
    
    return [super forwardingTargetForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"----forwardInvocation");
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    
    NSLog(@"------methodSignatureForSelector");
    
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    
    return signature;
}

@end
