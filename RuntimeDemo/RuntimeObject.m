//
//  RuntimeObject.m
//  RuntimeDemo
//
//  Created by Tangtang on 2016/10/7.
//  Copyright © 2016年 Tangtang. All rights reserved.
//

#import "RuntimeObject.h"
#import <objc/runtime.h>

@implementation RuntimeObject

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(methodExchange1);
        SEL swizzledSelector = @selector(methodExchange2);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)showProperty {
    NSLog(@">>>>>>RuntimeObject showProperty<<<<<<");
    
    unsigned int outCount = 0;
    objc_property_t *propertyList = class_copyPropertyList([self class], &outCount);
    for (int i = 0; i < outCount; i ++) {
        objc_property_t property = propertyList[i];
        const char *propertyName = property_getName(property);
        NSLog(@"property            %s", propertyName);
    }
    
    free(propertyList);
}

- (void)showMethod {
    NSLog(@">>>>>>RuntimeObject showMethod<<<<<<");
    
    unsigned int outCount = 0;
    Method *methods = class_copyMethodList([self class], &outCount);
    for (int i = 0; i < outCount; i++) {
        Method method = methods[i];
        NSString *methosName = NSStringFromSelector(method_getName(method));
        NSLog(@"method            %@", methosName);
    }
    
    free(methods);
}

- (void)methodExchange1 {
    NSLog(@"change method %s", __FUNCTION__);
}

- (void)methodExchange2 {
    NSLog(@">>>>>>RuntimeObject MethodExchange<<<<<<");
    
    NSLog(@"%s", __FUNCTION__);
    
    [self methodExchange2];
}

@end
