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
//  STSocketAddress.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/6.
//

#import "STSocketAddress.h"

@interface STSocketAddress ()

@property(nonatomic, strong) NSString *host;
@property(nonatomic, assign) UInt16 port;

@end

@implementation STSocketAddress

- (instancetype)init {
    NSAssert(false, @"DON'T call me");
    NSString *ip = nil;
    return [self initWithHost:ip port:0];
}

/* designated initializer */
- (instancetype)initWithHost:(NSString *)ip port:(UInt16)port {
    if (self = [super init]) {
        self.host = ip;
        self.port = port;
    }
    return self;
}

#pragma mark Object

- (NSUInteger)hash {
    return [_host hash] + _port * 13;
}

- (BOOL)isEqual:(id)object {
    if ([object conformsToProtocol:@protocol(STSocketAddress)]) {
        // compare with wrapper
        if (object == self) {
            return YES;
        }
        // compare with host & port
        id<STSocketAddress> other = (id<STSocketAddress>)object;
        return other.port == _port && [other.host isEqualToString:_host];
    }
    return NO;
}

@end

@implementation STSocketAddress (Creation)

+ (instancetype)addressWithHost:(NSString *)ip port:(UInt16)port {
    STSocketAddress *address = [[STSocketAddress alloc] initWithHost:ip port:port];
    return address;
}

@end
