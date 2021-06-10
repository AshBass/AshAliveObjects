//
//  AshBlockRetainChecker.m
//  AshRetainChecker
//
//  Created by crimsonho on 2021/6/10.
//

#if __has_feature(objc_arc)
#error This file must be compiled with MRR. Use -fno-objc-arc flag.
#endif

#import "AshBlockRetainChecker.h"
#import "AshBlockRetainModel.h"
#import "AshBlockRetainSupport.h"
#import <objc/runtime.h>

static NSIndexSet *getBlockStrongLayout(void *block) {
  struct AshBlockStruct *blockStruct = block;

  if ((blockStruct->flags & BLOCK_HAS_CTOR)
      || !(blockStruct->flags & BLOCK_HAS_COPY_DISPOSE)) {
    return nil;
  }

  void (*dispose_helper)(void *src) = blockStruct->descriptor->dispose_helper;
  const size_t ptrSize = sizeof(void *);

  const size_t elements = (blockStruct->descriptor->size + ptrSize - 1) / ptrSize;

  void *obj[elements];
  void *detectors[elements];

  for (size_t i = 0; i < elements; ++i) {
      AshBlockRetainModel *detector = [AshBlockRetainModel new];
      obj[i] = detectors[i] = detector;
  }

  @autoreleasepool {
    dispose_helper(obj);
  }
    
  NSMutableIndexSet *layout = [NSMutableIndexSet indexSet];

  for (size_t i = 0; i < elements; ++i) {
      AshBlockRetainModel *detector = (AshBlockRetainModel *)(detectors[i]);
      if (detector.isStrong) {
          [layout addIndex:i];
      }
      
      [detector trueRelease];
  }

  return layout;
}

NSArray *AshGetBlockStrongReferences(void *block) {
  if (!AshObjectIsBlock(block)) {
      return nil;
  }
  
  NSMutableArray *results = [NSMutableArray new];

  void **blockReference = block;
  NSIndexSet *strongLayout = getBlockStrongLayout(block);
  [strongLayout enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    void **reference = &blockReference[idx];

    if (reference && (*reference)) {
      id object = (id)(*reference);

      if (object) {
        [results addObject:object];
      }
    }
  }];

  return [results autorelease];
}

BOOL AshObjectIsBlock(void *object) {
  Class blockClass = getBaseBlockClass();
  
  Class candidate = object_getClass((__bridge id)object);
  return [candidate isSubclassOfClass:blockClass];
}

