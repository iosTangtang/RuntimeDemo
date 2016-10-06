//
//  ViewController.m
//  RuntimeDemo
//
//  Created by Tangtang on 2016/10/4.
//  Copyright © 2016年 Tangtang. All rights reserved.
//

#import "ViewController.h"
#import "Run.h"
#import <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Run *obj1 = [[Run alloc] init];
    Run *obj2 = [[Run alloc] init];
    
    NSLog(@"-------------------------------obj1---------------------------------------");
    NSLog(@"point                    %p", &obj1);
    NSLog(@"instance                 %p", obj1);
    NSLog(@"class                    %p", object_getClass(obj1));
    NSLog(@"meta class               %p", object_getClass([obj1 class]));
    NSLog(@"root class               %p", object_getClass(object_getClass([obj1 class])));
    NSLog(@"root meta's meta class   %p", object_getClass(object_getClass(object_getClass([obj1 class]))));
    
    NSLog(@"-------------------------------obj2 打印类名-------------------------------");
    
//    NSLog(@"point                    %@", &obj2);
    NSLog(@"instance                 %@", obj2);
    NSLog(@"class                    %@", object_getClass(obj2));
    NSLog(@"meta class               %@", object_getClass([obj2 class]));
    NSLog(@"root class               %@", object_getClass(object_getClass([obj2 class])));
    NSLog(@"root meta's meta class   %@", object_getClass(object_getClass(object_getClass([obj2 class]))));
    
    NSLog(@"-------------------------------类簇---------------------------------------");
    
    //----NSTimer  类簇
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        //
    }];
    NSLog(@"instance                 %@", timer);
    NSLog(@"class                    %@", object_getClass(timer));
    NSLog(@"meta class               %@", object_getClass([timer class]));
    NSLog(@"root class               %@", object_getClass(object_getClass([timer class])));
    NSLog(@"root meta's meta class   %@", object_getClass(object_getClass(object_getClass([timer class]))));
    
    NSLog(@"class method             %@", [timer class]);
    
    NSLog(@"-------------------------------类名---------------------------------------");
    NSLog(@"%s", class_getName([timer class]));
    NSLog(@"%@", class_getSuperclass([timer class]));
    
//    [obj1 performSelector:@selector(method)];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
