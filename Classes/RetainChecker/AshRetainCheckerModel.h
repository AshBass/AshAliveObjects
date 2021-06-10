//
//  AshRetainCheckerModel.h
//  FlexTest
//
//  Created by crimsonho on 2021/3/26.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger, ObjectType) {
    ObjectTypeObject,
    ObjectTypeBlock,
    ObjectTypeStruct,
    ObjectTypeUnknow,
};

@interface AshRetainCheckerIvarModel : NSObject

@property (nonatomic, assign, readonly) Ivar ivar;

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) id value;
@property (nonatomic, assign, readonly) const char *typeEncoding;

@property (nonatomic, strong, readonly) Class aClass;
@property (nonatomic, copy, readonly) NSString *className;

@property (nonatomic, assign, readonly) NSUInteger index;

@property (nonatomic, assign, readonly) BOOL canRetain;
@property (nonatomic, assign, readonly) ObjectType type;

- (instancetype)initWithObject:(id)object ivar:(Ivar)ivar;

@end

@interface AshRetainCheckerObjectModel : NSObject

@property (nonatomic, weak, readonly) id object;

@property (nonatomic, readonly) Class aClass;
@property (nonatomic, readonly) NSString *className;
@property (nonatomic, readonly) NSArray<AshRetainCheckerIvarModel*> *strongIvars;

@property (nonatomic, assign, readonly) size_t size;

- (instancetype)initWithObject:(id)object;

@end
