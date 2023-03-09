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
//  STKeyPairMap.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STKeyPairMap<__covariant KeyType, __covariant ObjectType> : NSObject

/**
 *  Get all mapped values
 *
 * @return values
 */
@property (readonly, copy) NSSet<ObjectType> *allValues;

/**
 *  Get value by key pair (remote, local)
 *
 * @param remote - remote address
 * @param local  - local address
 * @return mapped value
 */
- (nullable ObjectType)objectForRemote:(nullable KeyType)remote local:(nullable KeyType)local;

@end

@interface STKeyPairMap<KeyType, ObjectType> (Mutable)

/**
 *  Set value by key pair (remote, local)
 *
 * @param remote - remote address
 * @param local  - local address
 * @param value  - mapping value
 */
- (void)setObject:(ObjectType)value forRemote:(nullable KeyType)remote local:(nullable KeyType)local;

/**
 *  Remove mapping by key pair (remote, local)
 *
 * @param remote - remote address
 * @param local  - local address
 * @param value  - mapped value (Optional)
 * @return removed value
 */
- (nullable ObjectType)removeObject:(nullable ObjectType)value forRemote:(nullable KeyType)remote local:(nullable KeyType)local;

@end

#pragma mark -

@interface STWeakKeyPairMap<__covariant KeyType, __covariant ObjectType> : STKeyPairMap<KeyType, ObjectType>

- (instancetype)initWithDefaultValue:(KeyType)any NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
