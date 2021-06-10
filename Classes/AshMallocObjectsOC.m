//
//  AshMallocObjectsOC.m
//  FlexTest
//
//  Created by crimsonho on 2021/3/25.
//

#import "AshMallocObjectsOC.h"
#import <mach/mach.h>
#import <sys/proc.h>
#import <mach/vm_statistics.h>
#import <unistd.h>
#import <malloc/malloc.h>
#import <mach-o/dyld.h>
#import <objc/objc.h>
#import <objc/runtime.h>

@implementation AshMallocObjectsOC

extern int proc_regionfilename(int pid, uint64_t address, void * buffer, uint32_t buffersize);

+ (void)allMallocZone {
    kern_return_t krc = KERN_SUCCESS;
    vm_address_t address = 0;
    vm_size_t size = 0;
    uint32_t depth = 1;
    pid_t pid = getpid();
    char buf[PATH_MAX];
    while (1) {
        struct vm_region_submap_info_64 info;
        mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;
        krc = vm_region_recurse_64(mach_task_self(), &address, &size, &depth, (vm_region_info_64_t)&info, &count);
        if (krc == KERN_INVALID_ADDRESS){
            break;
        }
        if (info.is_submap){
            depth++;
        } else {
            proc_regionfilename(pid, address, buf, sizeof(buf));
            printf("Found VM Region: %08x to %08x (depth=%d) name:%s\n", (uint32_t)address, (uint32_t)(address+size), depth, buf);
            address += size;
        }
    }
}

BOOL pointerIsReadable(const void *inPtr) {
    kern_return_t error = KERN_SUCCESS;

    vm_size_t vmsize;
#if __arm64e__
    vm_address_t address = (vm_address_t)ptrauth_strip(inPtr, ptrauth_key_function_pointer);
#else
    vm_address_t address = (vm_address_t)inPtr;
#endif
    vm_region_basic_info_data_t info;
    mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
    memory_object_name_t object;

    error = vm_region_64(
        mach_task_self(),
        &address,
        &vmsize,
        VM_REGION_BASIC_INFO,
        (vm_region_info_t)&info,
        &info_count,
        &object
    );

    if (error != KERN_SUCCESS) {
        return NO;
    } else if (!(BOOL)(info.protection & VM_PROT_READ)) {
        return NO;
    }

    vm_offset_t readMem = 0;
    mach_msg_type_number_t size = 0;
#if __arm64e__
    address = (vm_address_t)ptrauth_strip(inPtr, ptrauth_key_function_pointer);
#else
    address = (vm_address_t)inPtr;
#endif
    error = vm_read(mach_task_self(), address, sizeof(uintptr_t), &readMem, &size);
    if (error != KERN_SUCCESS) {
        return NO;
    }

    return YES;
}

typedef void (^introspection_enumeration_block)(__unsafe_unretained id object, __unsafe_unretained Class actualClass);

static void vm_range_recorder(task_t task, void *context, unsigned type, vm_range_t *ranges, unsigned rangeCount) {
    if (!context) {
        return;
    }
    
    for (unsigned int i = 0; i < rangeCount; i++) {
        vm_range_t range = ranges[i];
        struct objc_object *tryObject = (struct objc_object*)range.address;
        Class tryClass = NULL;
#ifdef __arm64__
        // See http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html
        extern uint64_t objc_debug_isa_class_mask WEAK_IMPORT_ATTRIBUTE;
        tryClass = (__bridge Class)((void *)((uint64_t)tryObject->isa & objc_debug_isa_class_mask));
#else
        tryClass = tryObject->isa;
#endif
        (*(introspection_enumeration_block __unsafe_unretained *)context)((__bridge id)tryObject, tryClass);
    }
}

static CFMutableSetRef libSet;

+ (NSArray*)appAliveObjectsOC {
    
    if (malloc_size(libSet) <= 0) {
        NSArray *withClassName = @[
            @"AppDelegate"
        ];
        libSet = CFSetCreateMutable(NULL, withClassName.count, NULL);
        for (NSString *className in withClassName) {
            Class aClass = NSClassFromString(className);
            CFSetSetValue(libSet, class_getImageName(aClass));
        }
    }
    
    unsigned int outCount = 0;
    Class *classList = objc_copyClassList(&outCount);
    CFMutableSetRef classSet = CFSetCreateMutable(NULL, outCount, NULL);
    for (unsigned int i = 0; i < outCount; ++i) {
        CFSetSetValue(classSet, (__bridge const void *)classList[i]);
    }
    free(classList);
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    vm_address_t *zones = NULL;
    unsigned int zoneCount = 0;
    kern_return_t result = malloc_get_all_zones(TASK_NULL, 0, &zones, &zoneCount);
    
    if (result == KERN_SUCCESS) {
        for (unsigned int i = 0; i < zoneCount; i++) {
            malloc_zone_t *zone = (malloc_zone_t *)zones[i];
            malloc_introspection_t *introspection = zone->introspect;
            
//            printf("Found zone name:%s\n", zone->zone_name);
            if(strstr(zone->zone_name, "WebKit") != NULL) {
                continue;
            }
            
            if (!introspection) {
                continue;
            }

            void (*lock_zone)(malloc_zone_t *zone)   = introspection->force_lock;
            void (*unlock_zone)(malloc_zone_t *zone) = introspection->force_unlock;

            introspection_enumeration_block callback = ^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
                unlock_zone(zone);
                if (object != array &&
                    object != (__bridge id)(classSet) &&
                    malloc_size((__bridge const void *)(object)) > 0 &&
                    CFSetContainsValue(libSet, class_getImageName(actualClass)) &&
                    CFSetContainsValue(classSet, (__bridge const void *)actualClass)) {
                    [array addObject:object];
                }
                lock_zone(zone);
            };
            
            BOOL lockZoneValid = pointerIsReadable(lock_zone);
            BOOL unlockZoneValid =  pointerIsReadable(unlock_zone);

            if (introspection->enumerator && lockZoneValid && unlockZoneValid) {
                lock_zone(zone);
                introspection->enumerator(TASK_NULL, (void *)&callback, MALLOC_PTR_IN_USE_RANGE_TYPE, (vm_address_t)zone, 0, &vm_range_recorder);
                unlock_zone(zone);
            }
        }
    }
    
    CFRelease(classSet);
    
    return array.copy;
}

@end
