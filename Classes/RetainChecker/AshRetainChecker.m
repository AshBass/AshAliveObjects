//
//  AshRetainChecker.m
//  FlexTest
//
//  Created by crimsonho on 2021/3/26.
//

#import "AshRetainChecker.h"
#import "AshBlockRetainChecker.h"
#import "AshBlockRetainSupport.h"

typedef BOOL(^AshRetainIvarSelectBlock)(id object);

typedef struct {
  long _unknown;
  id target;
  SEL selector;
  NSDictionary *userInfo;
} AshNSCFTimerInfoStruct;

@interface AshRetainChecker ()

@end

@implementation AshRetainChecker

- (NSArray*)findRetainWithObjectModel:(AshRetainCheckerObjectModel*)objectModel className:(NSString*)className
{
    return [self findRetainWithObjectModel:objectModel selectBlock:^BOOL(id object) {
        if ([object respondsToSelector:@selector(class)] &&
            [NSStringFromClass([object class]) isEqualToString:className]) {
            return YES;
        }
        return NO;
    }];
}

- (NSArray*)findRetainWithObjectModel:(AshRetainCheckerObjectModel*)objectModel selectBlock:(AshRetainIvarSelectBlock)block
{
    return [self findRetainWithObjectModel:objectModel selectBlock:block prePath:nil preFindObjects:nil results:nil];
}

- (NSArray*)findRetainWithObjectModel:(AshRetainCheckerObjectModel*)objectModel selectBlock:(AshRetainIvarSelectBlock)block prePath:(NSString*)prePath preFindObjects:(NSSet*)preFindSet results:(NSArray*)results
{
    if (!block) {
        return nil;
    }
    if (!objectModel.object) {
        return nil;
    }
    if ([preFindSet containsObject:objectModel.object]) {
        /// 成环（虽说可能走不到这里）
        return nil;
    }
    NSMutableSet *set = [[NSMutableSet alloc] initWithSet:preFindSet];
    [set addObject:objectModel.object];
    NSString *aPath = prePath ? [NSString stringWithString:prePath] : objectModel.className;
    NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:results];
    
    NSArray *strongIvars = objectModel.strongIvars.copy;
    for (AshRetainCheckerIvarModel *ivar in strongIvars) {
        if ([set containsObject:ivar.value]) {
            continue;
        }
        if (ivar.canRetain) {
            [self parseObjectValue:ivar.value ivarName:ivar.name resultArray:resultArray selectBlock:block aPath:aPath set:set results:results];
        }
    }
    return resultArray;
}

- (void)parseObjectValue:(id)value ivarName:(NSString*)ivarName resultArray:(NSMutableArray*)resultArray selectBlock:(AshRetainIvarSelectBlock)block aPath:(NSString*)aPath set:(NSSet*)set results:(NSArray*)results {
    
    Class aClass = [value class];
    NSString *ivarClassName = NSStringFromClass(aClass);
    
    if ([value isKindOfClass:[NSArray class]] ||
        [value isKindOfClass:[NSDictionary class]] ||
        [value isKindOfClass:[NSSet class]]) {
        id<NSFastEnumeration> fe;
        if ([value isKindOfClass:[NSArray class]]) {
            fe = value;
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *valueDictionary = value;
            fe = valueDictionary.allValues;
        } else if ([value isKindOfClass:[NSSet class]]) {
            NSSet *valueSet = value;
            fe = valueSet.allObjects;
        }
        for (id object in fe) {
            NSString *path = [NSString stringWithFormat:@"%@.%@(%@)", aPath, ivarName, ivarClassName];
            [self parseObjectValue:object ivarName:@"" resultArray:resultArray selectBlock:block aPath:path set:set results:results];
        }
    } else if ([value isKindOfClass:[NSTimer class]]) {
        NSTimer *timer = value;
        CFRunLoopTimerContext context;
        CFRunLoopTimerGetContext((CFRunLoopTimerRef)timer, &context);
        if (context.info && context.retain) {
            AshNSCFTimerInfoStruct infoStruct = *(AshNSCFTimerInfoStruct *)(context.info);
          if (block(infoStruct.target)) {
              NSString *path = [NSString stringWithFormat:@"%@.%@(%@).target", aPath, ivarName, ivarClassName];
              [self parseObjectValue:infoStruct.target ivarName:@"" resultArray:resultArray selectBlock:block aPath:path set:set results:results];
          }
          if (infoStruct.userInfo) {
              NSString *path = [NSString stringWithFormat:@"%@.%@(%@).userInfo", aPath, ivarName, ivarClassName];
              [self parseObjectValue:infoStruct.userInfo ivarName:@"" resultArray:resultArray selectBlock:block aPath:path set:set results:results];
          }
        }
    } else if (AshObjectIsBlock((__bridge void * _Nullable)(value))) {
        NSArray *blockRetainArray = AshGetBlockStrongReferences((__bridge void * _Nonnull)(value));
        for (id object in blockRetainArray) {
            NSString *path = [NSString stringWithFormat:@"%@.%@(%@)", aPath, ivarName, ivarClassName];
            [self parseObjectValue:object ivarName:@"" resultArray:resultArray selectBlock:block aPath:path set:set results:results];
        }
    } else {
        NSString *path = [NSString stringWithFormat:@"%@.%@(%@)", aPath, ivarName, NSStringFromClass([value class])];
        if (block(value)) {
            [resultArray addObject:path];
        } else {
            AshRetainCheckerObjectModel *model = [[AshRetainCheckerObjectModel alloc] initWithObject:value];
            NSArray *nextResultArray = [self findRetainWithObjectModel:model selectBlock:block prePath:path preFindObjects:set results:results];
            [resultArray addObjectsFromArray:nextResultArray];
        }
    }
}
@end
