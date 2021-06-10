//
//  AshBlockRetainSupport.h
//  AshRetainChecker
//
//  Created by crimsonho on 2021/6/10.
//

#import <Foundation/Foundation.h>

enum {
  BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
  BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
  BLOCK_IS_GLOBAL =         (1 << 28),
  BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
  BLOCK_HAS_SIGNATURE =     (1 << 30),
};

struct AshBlockDescriptor {
  unsigned long int reserved;                // NULL
  unsigned long int size;
  // optional helper functions
  void (*copy_helper)(void *dst, void *src); // IFF (1<<25)
  void (*dispose_helper)(void *src);         // IFF (1<<25)
  const char *signature;                     // IFF (1<<30)
};

struct AshBlockStruct {
  void *isa;
  int flags;
  int reserved;
  void (*invoke)(void *, ...);
  struct AshBlockDescriptor *descriptor;
};


Class getBaseBlockClass(void);
