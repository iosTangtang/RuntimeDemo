//
//  MethodObject.m
//  RuntimeDemo
//
//  Created by Tangtang on 2016/10/7.
//  Copyright © 2016年 Tangtang. All rights reserved.
//

#import "MethodObject.h"
#import "ClassAndObject.h"
#import <objc/runtime.h>

@interface MethodHelper : NSObject

- (void)method;

@end

@implementation MethodHelper

- (void)method {
    NSLog(@"%s", __FUNCTION__);
}

@end

@interface MethodObject () {
    MethodHelper *_helper;
}

@end

@implementation MethodObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        _helper = [[MethodHelper alloc] init];
    }
    return self;
}

- (void)hello:(NSString *)string {
    NSLog(@">>>>>>MethodObject hello<<<<<<");
}

- (void)showHelloMethodSEL {
    NSLog(@">>>>>>MethodObject showHelloMethodSEL<<<<<<");
    SEL sel = @selector(hello:);
    NSLog(@"sel             %p", sel);
}

void functionMethod(void) {
    NSLog(@"%s", __FUNCTION__);
}

#pragma mark - 动态方法解析
//实例方法
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    NSLog(@"%s", __FUNCTION__);
    
//    NSString *selSelector = NSStringFromSelector(sel);
//    
//    if ([selSelector isEqualToString:@"method"]) {
//        class_addMethod([self class], @selector(method), (IMP)functionMethod, "@:");
//    }
    
    return [super resolveInstanceMethod:sel];
}

#pragma mark - 备用接收者
- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSLog(@"%s", __FUNCTION__);
    
//    NSString *selSelector = NSStringFromSelector(aSelector);
//    
//    if ([selSelector isEqualToString:@"method"]) {
//        return _helper;
//    }
    
    return [super forwardingTargetForSelector:aSelector];
}

#pragma mark - 完整消息转发
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSLog(@"%s", __FUNCTION__);
    
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    
    if (!signature) {
        if ([MethodHelper instancesRespondToSelector:aSelector]) {
            signature = [MethodHelper instanceMethodSignatureForSelector:aSelector];
        }
    }
    
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation{
    NSLog(@"%s", __FUNCTION__);
    
    if ([MethodHelper instancesRespondToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:_helper];
    }
}

@end
