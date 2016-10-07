//
//  ViewController.m
//  RuntimeDemo
//
//  Created by Tangtang on 2016/10/4.
//  Copyright © 2016年 Tangtang. All rights reserved.
//

#import "ViewController.h"
#import "ClassAndObject.h"
#import "MethodObject.h"
#import "RuntimeObject.h"
#import "RuntimeObject+associated.h"
#import <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //类与对象
    [self runtime_classAndObject];
    
    //方法
    [self runtime_method];
    [self runtime_messageForward];
    
    //self and super
    [self runtime_selfAndSuper];
    
    //RuntimeObject
    [self runtime_runtimeObject];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ClassAndObject
- (void)runtime_classAndObject {
    NSLog(@"----------------------ClassAndObject-------------------------");
    
    ClassAndObject *cla1 = [[ClassAndObject alloc] init];
    [cla1 showAddress];
    
    [cla1 showRelation];
    
    [cla1 showDifferenceWithClassCluster];
}

#pragma mark - MethodObject
- (void)runtime_method {
    NSLog(@"----------------------MethodObject-------------------------");
    
    MethodObject *methodObj = [[MethodObject alloc] init];
    
    [methodObj showHelloMethodSEL];
    
    ClassAndObject *cla1 = [[ClassAndObject alloc] init];
    
    [cla1 showHelloMethodSEL];
}

- (void)runtime_messageForward {
    MethodObject *methodObj = [[MethodObject alloc] init];
    
    //消息转发
    [methodObj performSelector:@selector(method)];
}

#pragma mark - SelfAndSuper
- (void)runtime_selfAndSuper {
    NSLog(@"----------------------SelfAndSuper-------------------------");
    
    NSLog(@"%@", [self class]);
    NSLog(@"%@", [super class]);
}

#pragma mark - RuntimeObject
- (void)runtime_runtimeObject {
    NSLog(@"----------------------RuntimeObject-------------------------");
    
    RuntimeObject *run = [[RuntimeObject alloc] init];
    
    [run showProperty];
    
    [run showMethod];
    
    [run methodExchange1];
    
    [run setAssociatedObject:@"runtime_runtimeObject_associated"];
    
    NSLog(@"%@", run.associatedObject);
}


@end
