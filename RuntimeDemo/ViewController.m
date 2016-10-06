//
//  ViewController.m
//  RuntimeDemo
//
//  Created by Tangtang on 2016/10/4.
//  Copyright © 2016年 Tangtang. All rights reserved.
//

#import "ViewController.h"
#import "Run.h"
#import "ClassAndObject.h"
#import <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //类与对象
    [self classAndObject];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ClassAndObject
- (void)classAndObject {
    NSLog(@"----------------------ClassAndObject-------------------------");
    
    ClassAndObject *cla1 = [[ClassAndObject alloc] init];
    [cla1 showAddress];
    
    [cla1 showRelation];
    
    [cla1 showDifferenceWithClassCluster];
}


@end
