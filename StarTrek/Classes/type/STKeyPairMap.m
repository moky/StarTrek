// license: https://mit-license.org
//
//  StarTrek : Interstellar Transport
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
//  STKeyPairMap.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import <ObjectKey/ObjectKey.h>

#import "STKeyPairMap.h"

@implementation STKeyPairMap

- (NSSet<id> *)allValues {
    NSAssert(false, @"override me!");
    return nil;
}

- (nullable id)objectForRemote:(nullable id)remote local:(nullable id)local {
    NSAssert(false, @"override me!");
    return nil;
}

@end

@implementation STKeyPairMap (Mutable)

- (void)setObject:(id)value forRemote:(nullable id)remote local:(nullable id)local {
    NSAssert(false, @"override me!");
}

- (nullable id)removeObject:(nullable id)value
                  forRemote:(nullable id)remote local:(nullable id)local {
    NSAssert(false, @"override me!");
    return nil;
}

@end

#pragma mark -

typedef OKAbstractMap<id, OKAbstractMap<id, id> *> WeakKeyTable;

@interface STWeakKeyPairMap ()

@property(nonatomic, strong) id defaultKey;

// because the remote address will always different to local address, so
// we shared the same map for all directions here:
//    mapping: (remote, local) => Connection
//    mapping: (remote, null) => Connection
//    mapping: (local, null) => Connection
@property(nonatomic, strong) WeakKeyTable *map;

@end

@implementation STWeakKeyPairMap

- (instancetype)init {
    NSAssert(false, @"DON'T call me!");
    id address = nil;
    return [self initWithDefaultValue:address];
}

/* designated initializer */
- (instancetype)initWithDefaultValue:(id)any {
    if (self = [super init]) {
        self.defaultKey = any;
        self.map = [OKWeakHashMap map];
    }
    return self;
}

// Override
- (nullable id)objectForRemote:(nullable id)remote local:(nullable id)local {
    id key1, key2;
    if (!remote) {
        NSAssert(local, @"local & remote addresses should not empty at the same time");
        key1 = local;
        key2 = nil;
    } else {
        key1 = remote;
        key2 = local;
    }
    OKAbstractMap<id, id> *table = [_map objectForKey:key1];
    if (!table) {
        return nil;
    }
    __block id value;
    if (key2) {
        // mapping: (remote, local) => Connection
        value = [table objectForKey:key2];
        if (value) {
            return value;
        }
        // take any Connection connected to remote
        return [table objectForKey:_defaultKey];
    }
    // mapping: (remote, null) => Connection
    // mapping: (local, null) => Connection
    value = [table objectForKey:_defaultKey];
    if (value) {
        // take the value with empty key2
        return value;
    }
    // take any Connection connected to remote / bound to local
    [table enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj) {
            value = obj;
            *stop = YES;
        }
    }];
    return value;
}

// Override
- (void)setObject:(id)value forRemote:(nullable id)remote local:(nullable id)local {
    // create indexes with key pair (remote, local)
    id key1, key2;
    if (!remote) {
        NSAssert(local, @"local & remote addresses should not empty at the same time");
        key1 = local;
        key2 = _defaultKey;
    } else if (!local) {
        key1 = remote;
        key2 = _defaultKey;
    } else {
        key1 = remote;
        key2 = local;
    }
    OKAbstractMap<id, id> *table = [_map objectForKey:key1];
    if (table) {
        if (value) {
            [table setObject:value forKey:key2];
        } else {
            [table removeObjectForKey:key2];
        }
    } else if (value) {
        table = [[OKWeakHashMap alloc] init];
        [table setObject:value forKey:key2];
        [_map setObject:table forKey:key1];
    }
}

// Override
- (nullable id)removeObject:(nullable id)value
                  forRemote:(nullable id)remote local:(nullable id)local {
    // remove indexes with key pair (remote, local)
    id key1, key2;
    if (!remote) {
        NSAssert(local, @"local & remote addresses should not empty at the same time");
        key1 = local;
        key2 = _defaultKey;
    } else if (!local) {
        key1 = remote;
        key2 = _defaultKey;
    } else {
        key1 = remote;
        key2 = local;
    }
    OKAbstractMap<id, id> *table = [_map objectForKey:key1];
    if (!table) {
        return nil;
    }
    value = [table objectForKey:key2];
    if (value) {
        [table removeObjectForKey:key2];
    }
    return value;
}

@end
