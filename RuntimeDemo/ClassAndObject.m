//
//  ClassAndObject.m
//  RuntimeDemo
//
//  Created by Tangtang on 2016/10/6.
//  Copyright © 2016年 Tangtang. All rights reserved.
//

#import "ClassAndObject.h"
#import <objc/runtime.h>

@implementation ClassAndObject

- (void)showAddress {
    
    NSLog(@">>>>>>ClassAndObject showAddressMethod<<<<<<");
    
    NSLog(@"point                           %p", &self);
    NSLog(@"instance                        %p", self);
    NSLog(@"class                           %p", object_getClass(self));
    NSLog(@"meta class                      %p", object_getClass([self class]));
    NSLog(@"root class                      %p", object_getClass(object_getClass([self class])));
    NSLog(@"root meta's meta class          %p", object_getClass(object_getClass(object_getClass([self class]))));
}

- (void)showRelation {
    
    NSLog(@">>>>>>ClassAndObject showRelationMethod<<<<<<");
    
    NSLog(@"instance                        %@", self);
    NSLog(@"class                           %@", object_getClass(self));
    NSLog(@"meta class                      %@", object_getClass([self class]));
    NSLog(@"root class                      %@", object_getClass(object_getClass([self class])));
    NSLog(@"root meta's meta class          %@", object_getClass(object_getClass(object_getClass([self class]))));
}

- (void)showDifferenceWithClassCluster {
    NSLog(@">>>>>>ClassAndObject showDifferenceWithClassClusterMethod<<<<<<");
    
    //----NSTimer  类簇
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        //do nothing
    }];
    NSLog(@"instance                        %@", timer);
    NSLog(@"class                           %@", object_getClass(timer));
    NSLog(@"meta class                      %@", object_getClass([timer class]));
    NSLog(@"root class                      %@", object_getClass(object_getClass([timer class])));
    NSLog(@"root meta's meta class          %@", object_getClass(object_getClass(object_getClass([timer class]))));
    
    NSLog(@"class method                    %@", [timer class]);
    
    NSLog(@">>>>>>ClassAndObject showDifferenceWithClassClusterMethod Test<<<<<<");
    NSLog(@"class_getName Method            %s", class_getName([timer class]));
    NSLog(@"class_getSuperClass Method      %@", class_getSuperclass([timer class]));
}

@end
