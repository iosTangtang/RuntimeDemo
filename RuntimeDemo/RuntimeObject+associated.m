//
//  RuntimeObject+associated.m
//  RuntimeDemo
//
//  Created by Tangtang on 2016/10/7.
//  Copyright © 2016年 Tangtang. All rights reserved.
//

#import "RuntimeObject+associated.h"
#import <objc/runtime.h>

@implementation RuntimeObject (associated)
@dynamic associatedObject;

- (void)setAssociatedObject:(id)associatedObject {
    NSLog(@">>>>>>RuntimeObject+associated associatedObject<<<<<<");
    
    objc_setAssociatedObject(self, @selector(associatedObject), associatedObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)associatedObject {
    return objc_getAssociatedObject(self, @selector(associatedObject));
}

@end
