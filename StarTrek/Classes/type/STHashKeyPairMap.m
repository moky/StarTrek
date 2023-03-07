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
//  STHashKeyPairMap.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import "STHashKeyPairMap.h"

@interface STHashKeyPairMap ()

@property(nonatomic, strong) NSMutableSet<id> *cachedValues;

@end

@implementation STHashKeyPairMap

// Override
- (NSSet<id> *)allValues {
    NSMutableSet *mSet = [[NSMutableSet alloc] init];
    [_cachedValues enumerateObjectsWithOptions:NSEnumerationConcurrent
                                    usingBlock:^(id obj, BOOL *stop) {
        [mSet addObject:obj];
    }];
    return mSet;
}

// Override
- (void)setObject:(id)value
        forRemote:(nullable id)remote
         andLocal:(nullable id)local {
    if (value) {
        // the caller may create different values with same pair (remote, local)
        // so here we should try to remove it first to make sure it's clean
        [_cachedValues removeObject:value];
        // cache it
        [_cachedValues addObject:value];
    }
    // create indexes
    [super setObject:value forRemote:remote andLocal:local];
}

// Override
- (nullable id)removeObject:(nullable id)value
                  forRemote:(nullable id)remote
                   andLocal:(nullable id)local {
    // remove indexes
    id old = [super removeObject:value forRemote:remote andLocal:local];
    if (old) {
        [_cachedValues removeObject:old];
    }
    // clear cached value
    if (value && value != old) {
        [_cachedValues removeObject:value];
    }
    return old ? old : value;
}

@end
