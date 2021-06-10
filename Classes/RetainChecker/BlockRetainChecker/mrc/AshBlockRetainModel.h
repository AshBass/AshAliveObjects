//
//  AshBlockRetainModel.h
//  AshRetainChecker
//
//  Created by crimsonho on 2021/6/10.
//

#import <Foundation/Foundation.h>

struct _block_byref_block;
@interface AshBlockRetainModel : NSObject
{
  // __block fakery
  void *forwarding;
  int flags;   //refcount;
  int size;
  void (*byref_keep)(struct _block_byref_block *dst, struct _block_byref_block *src);
  void (*byref_dispose)(struct _block_byref_block *);
  void *captured[16];
}

@property (nonatomic, assign, getter=isStrong) BOOL strong;

- (oneway void)trueRelease;

- (void *)forwarding;

@end
