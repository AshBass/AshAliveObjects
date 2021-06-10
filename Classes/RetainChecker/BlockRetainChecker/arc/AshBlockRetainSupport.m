//
//  AshBlockRetainSupport.m
//  AshRetainChecker
//
//  Created by crimsonho on 2021/6/10.
//

#import "AshBlockRetainSupport.h"
#import <objc/runtime.h>

static Class ashBlockClass;

Class getBaseBlockClass(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void (^testBlock)(void) = [^{} copy];
        ashBlockClass = [testBlock class];
        while(class_getSuperclass(ashBlockClass) && class_getSuperclass(ashBlockClass) != [NSObject class]) {
            ashBlockClass = class_getSuperclass(ashBlockClass);
        }
    });
    return ashBlockClass;
}
