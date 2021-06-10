//
//  AshBlockRetainChecker.h
//  AshRetainChecker
//
//  Created by crimsonho on 2021/6/10.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

NSArray *_Nullable AshGetBlockStrongReferences(void *_Nonnull block);

BOOL AshObjectIsBlock(void *_Nullable object);
  
#ifdef __cplusplus
}
#endif

