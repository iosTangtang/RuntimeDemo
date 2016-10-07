//
//  RuntimeObject.h
//  RuntimeDemo
//
//  Created by Tangtang on 2016/10/7.
//  Copyright © 2016年 Tangtang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RuntimeObject : NSObject

@property (nonatomic, copy)     NSString    *name;
@property (nonatomic, assign)   NSInteger   count;

- (void)showProperty;
- (void)showMethod;
- (void)methodExchange1;
- (void)methodExchange2;

@end
