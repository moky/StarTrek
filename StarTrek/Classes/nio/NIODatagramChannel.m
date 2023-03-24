//
//  NIODatagramChannel.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import "NIODatagramChannel.h"

@implementation NIODatagramChannel

- (BOOL)isBound {
    NSAssert(false, @"override me!");
    return NO;
}

- (BOOL)isConnected {
    NSAssert(false, @"override me!");
    return NO;
}

- (nullable id<NIONetworkChannel>)bindLocalAddress:(id<NIOSocketAddress>)local throws:(NIOException **)error {
    NSAssert(false, @"override me!");
    return nil;
}

- (nullable id<NIONetworkChannel>)connectRemoteAddress:(id<NIOSocketAddress>)remote throws:(NIOException **)error {
    NSAssert(false, @"override me!");
    return nil;
}

- (nullable id<NIOByteChannel>)disconnect {
    NSAssert(false, @"override me!");
    return nil;
}

// Override
- (NSInteger)readWithBuffer:(NIOByteBuffer *)dst throws:(NIOException **)error {
    NSAssert(false, @"override me!");
    return 0;
}

// Override
- (NSInteger)writeWithBuffer:(NIOByteBuffer *)src throws:(NIOException **)error {
    NSAssert(false, @"override me!");
    return 0;
}

// Override
- (id<NIOSocketAddress>)localAddress {
    NSAssert(false, @"override me!");
    return nil;
}

@end
