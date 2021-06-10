//
//  AshRetainCheckerModel.m
//  FlexTest
//
//  Created by crimsonho on 2021/3/26.
//

#import "AshRetainCheckerModel.h"
#import "AshBlockRetainSupport.h"
#import <malloc/malloc.h>

static NSString *appImageName;

BOOL canCheckObject(id object) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class aClass = NSClassFromString(@"AppDelegate");
        appImageName = [NSString stringWithUTF8String:class_getImageName(aClass)];
    });
    if (object && [object respondsToSelector:@selector(class)]) {
        Class aClass = [object class];
        if (aClass) {
            NSString *imageName = [NSString stringWithUTF8String:class_getImageName(aClass)];
            if ([appImageName isEqualToString:imageName]) {
                return YES;
            } else if ([object isKindOfClass:[NSTimer class]] ||
                       [object isKindOfClass:[NSArray class]] ||
                       [object isKindOfClass:[NSDictionary class]] ||
                       [object isKindOfClass:[NSSet class]] ||
                       [object isKindOfClass:getBaseBlockClass()]) {
                return YES;
            }
        }
    }
    return NO;
}

ObjectType convertObjectType(const char *typeEncoding)
{
  if (typeEncoding == NULL) {
      return ObjectTypeUnknow;
  }

/// 暂不支持结构体
//  if (typeEncoding[0] == '{') {
//      return ObjectTypeStruct;
//  }
    
  if (typeEncoding[0] == '@') {
      if (strncmp(typeEncoding, "@?", 2) == 0) {
          /// block
          /// 暂不支持闭包检查
          return ObjectTypeBlock;
      } else {
          return ObjectTypeObject;
      }
  }

    return ObjectTypeUnknow;
}

@implementation AshRetainCheckerIvarModel

- (instancetype)initWithObject:(id)object ivar:(Ivar)ivar {
    self = [super init];
    if (self) {
        _ivar = ivar;
        _name = [NSString stringWithUTF8String:ivar_getName(ivar)];
        _typeEncoding = ivar_getTypeEncoding(ivar);
        _type = convertObjectType(_typeEncoding);
        _canRetain = ((_type == ObjectTypeObject) || (_type == ObjectTypeBlock));
        if (_canRetain)
        {
            _value = object_getIvar(object, ivar);
            
            if ([_value respondsToSelector:@selector(class)]) {
                _aClass = [_value class];
                _className = NSStringFromClass(_aClass);
            }
        }
        
        ptrdiff_t offset = ivar_getOffset(ivar);
        _index = offset/sizeof(void*);
    }
    return self;
}

@end

@implementation AshRetainCheckerObjectModel

- (instancetype)initWithObject:(id)object {
    self = [super init];
    if (self) {
        if (object && canCheckObject(object)) {
            _object = object;
            _aClass = [object class];
            _className = NSStringFromClass(_aClass);
            _size = malloc_size((__bridge const void *)(object));
            _strongIvars = [self loadStrongIvarWithClass:_aClass];
        }
    }
    return self;
}

- (NSArray*)loadStrongIvarWithClass:(Class)aClass {
    
    if (!aClass ||
        [NSStringFromClass(aClass) isEqualToString:@"NSObject"] ||
        [NSStringFromClass(aClass) isEqualToString:@"NSProxy"]) {
        return @[];
    }
    
    NSMutableArray *array = [NSMutableArray new];
    
    unsigned int count;
    Ivar *list = class_copyIvarList(aClass, &count);
    if (count != 0) {
        Ivar ivar = list[0];
        /// 先计算本类第一个属性是第几个（继承后本类属性可能不是第一个）
        ptrdiff_t offset = ivar_getOffset(ivar);
        NSUInteger currentIndex = offset / (sizeof(void *));
        
        NSMutableIndexSet *ranges = [[NSMutableIndexSet alloc] init];
        const uint8_t *strongLayout = class_getIvarLayout(aClass);
        while (strongLayout != NULL && *strongLayout != '\x00') {
            /// 前面有多少个不是 strong 声明的
            int preWithout = (*strongLayout & 0xf0) >> 4;
            /// 有多少个 strong 声明的
            int length = *strongLayout & 0xf;
            
            /// 先更新当前 index
            currentIndex += preWithout;
            /// 记录声明 strong 的 range
            NSRange range = NSMakeRange(currentIndex, length);
            [ranges addIndexesInRange:range];
            /// 更新当前 index
            currentIndex += length;
            
            ++strongLayout;
        }
        
        /// 是 strong 声明的
        for (int i = 0; i < count; i++) {
            Ivar ivar = list[i];
            AshRetainCheckerIvarModel *ivarModel = [[AshRetainCheckerIvarModel alloc] initWithObject:_object ivar:ivar];
            if (ivarModel.value &&
                ivarModel.canRetain &&
                [ranges containsIndex:ivarModel.index]) {
                [array addObject:ivarModel];
            }
        }
    }
    
    Class superClass = [aClass superclass];
    if (superClass) {
        NSArray *superArray = [self loadStrongIvarWithClass:superClass];
        [array addObjectsFromArray:superArray];
    }
    
    return array.copy;
}

@end
