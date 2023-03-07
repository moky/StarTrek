// license: https://mit-license.org
//
//  ObjectKey : Object & Key kits
//
//                               Written in 2023 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2023 Albert Moky
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// =============================================================================
//
//  OKWeakMap.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/6.
//

#import "OKWeakMap.h"

@interface WeakMap : OKWeakMap

@property(nonatomic, retain) NSMapTable *table;

@end

@implementation WeakMap

/* designated initializer */
- (instancetype)init {
    if (self = [super init]) {
        _table = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory
                                           valueOptions:NSMapTableWeakMemory
                                               capacity:8];
    }
    return self;
}

/* designated initializer */
- (instancetype)initWithCapacity:(NSUInteger)numItems {
    if (self = [super init]) {
        _table = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory
                                           valueOptions:NSMapTableWeakMemory
                                               capacity:numItems];
    }
    return self;
}

- (NSUInteger)count {
    return [_table count];
}

- (nullable id)objectForKey:(id)aKey {
    return [_table objectForKey:aKey];
}

@end

@implementation WeakMap (NSExtendedDictionary)

- (NSArray<id> *)allKeys {
    return NSAllMapTableKeys(_table);
}

- (NSArray<id> *)allValues {
    return NSAllMapTableValues(_table);
}

- (NSArray<id> *)allKeysForObject:(id)anObject {
    NSMutableArray *mArray = [[NSMutableArray alloc] init];
    NSEnumerator *enumerator = [_table keyEnumerator];
    id key, object;
    while (key = [enumerator nextObject]) {
        //key = [key retain];
        if (key) {
            object = [_table objectForKey:key];
            if ([object isEqual:anObject]) {
                [mArray addObject:key];
            }
            //[key release];
        }
    }
    return mArray;  // [mArray autorelease];
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id, id, BOOL *))block {
    NSEnumerator *enumerator = [_table keyEnumerator];
    id key, object;
    BOOL stop = NO;
    while (key = [enumerator nextObject]) {
        //key = [key retain];
        if (key) {
            object = [_table objectForKey:key];
            block(key, object, &stop);
            //[key release];
        }
        if (stop) {
            break;
        }
    }
}

- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts
                                usingBlock:(void (^)(id, id, BOOL *))block {
    NSAssert(opts == NSEnumerationConcurrent, @"NSEnumerationConcurrent only");
    [self enumerateKeysAndObjectsUsingBlock:block];
}

@end

@implementation WeakMap (NSMutableDictionary)

- (void)removeObjectForKey:(id)aKey {
    [_table removeObjectForKey:aKey];
}

- (void)setObject:(id)anObject forKey:(id)aKey {
    [_table setObject:anObject forKey:aKey];
}

@end

@implementation WeakMap (NSExtendedMutableDictionary)

- (void)removeAllObjects {
    [_table removeAllObjects];
}

@end

@implementation WeakMap (NSDictionaryCreation)

+ (instancetype)dictionary {
    WeakMap *map = [[WeakMap alloc] init];
    return map;  // [map autorelease];
}

@end

@implementation WeakMap (NSMutableDictionaryCreation)

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
    WeakMap *map = [[WeakMap alloc] initWithCapacity:numItems];
    return map;  // [map autorelease];
}

@end

#pragma mark -

@implementation OKWeakMap

+ (instancetype)alloc {
    if (self == [OKWeakMap class]) {
        return [WeakMap alloc];
    } else {
        return [super alloc];
    }
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (self == [OKWeakMap class]) {
        return [WeakMap allocWithZone:zone];
    } else {
        return [super allocWithZone:zone];
    }
}

/* designated initializer */
- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

/* designated initializer */
- (instancetype)initWithCapacity:(NSUInteger)numItems {
    if (self = [super init]) {
    }
    return self;
}

@end

@implementation OKWeakMap (NSDictionaryCreation)

+ (instancetype)dictionary {
    OKWeakMap *map = [[OKWeakMap alloc] init];
    return map;  // [map autorelease];
}

@end

@implementation OKWeakMap (NSMutableDictionaryCreation)

+ (instancetype)dictionaryWithCapacity:(NSUInteger)numItems {
    OKWeakMap *map = [[OKWeakMap alloc] initWithCapacity:numItems];
    return map; // [map autorelease];
}

@end
