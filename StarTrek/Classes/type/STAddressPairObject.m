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
//  STAddressPairObject.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import "STAddressPairObject.h"

static inline BOOL address_equal(id<NIOSocketAddress> addr1, id<NIOSocketAddress> addr2) {
    return (addr1 == addr2) || (addr1 && [addr1 isEqual:addr2]);
}

@interface STAddressPairObject ()

@property(nonatomic, strong, nullable) id<NIOSocketAddress> remoteAddress;
@property(nonatomic, strong, nullable) id<NIOSocketAddress> localAddress;

@end

@implementation STAddressPairObject

- (instancetype)init {
    NSAssert(false, @"don't call me!");
    return [self initWithRemoteAddress:nil andLocalAddress:nil];
}

/* designated initializer */
- (instancetype)initWithRemoteAddress:(id<NIOSocketAddress>)remote
                      andLocalAddress:(id<NIOSocketAddress>)local {
    if (self = [super init]) {
        self.remoteAddress = remote;
        self.localAddress = local;
    }
    return self;
}

// Override
- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ remote=\"%@\" local=\"%@\" />", [self class], [self remoteAddress], [self localAddress]];
}

#pragma mark Object

- (NSUInteger)hash {
    // name's hashCode is multiplied by an arbitrary prime number (13)
    // in order to make sure there is a difference in the hashCode between
    // these two parameters:
    //  name: a  value: aa
    //  name: aa value: a
    return [_remoteAddress hash] * 13 + [_localAddress hash];
}

- (BOOL)isEqual:(id)object {
    if (!object) {
        return !_remoteAddress && !_localAddress;
    }
    if ([object isKindOfClass:[STAddressPairObject class]]) {
        // compare with wrapper
        if (object == self) {
            return YES;
        }
        // compare with remote & local addresses
        STAddressPairObject *other = (STAddressPairObject *)object;
        return address_equal(other.remoteAddress, _remoteAddress)
            && address_equal(other.localAddress, _localAddress);
    }
    return NO;
}

@end

@implementation STAddressPairObject (Creation)

+ (instancetype)objectWithRemoteAddress:(id<NIOSocketAddress>)remote
                        andLocalAddress:(id<NIOSocketAddress>)local {
    STAddressPairObject *object;
    object = [[STAddressPairObject alloc] initWithRemoteAddress:remote
                                                andLocalAddress:local];
    return object;
}

@end
