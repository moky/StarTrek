//
//  NIOSocketChannel.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import "NIOSocketChannel.h"

@implementation NIOAbstractSelectableChannel

@end

@implementation NIOSocketChannel

- (BOOL)isBound {
    NSAssert(false, @"override me!");
    return NO;
}

- (BOOL)isConnected {
    NSAssert(false, @"override me!");
    return NO;
}

- (nullable id<NIONetworkChannel>)bindLocalAddress:(id<NIOSocketAddress>)local {
    NSAssert(false, @"override me!");
    return nil;
}

- (nullable id<NIONetworkChannel>)connectRemoteAddress:(id<NIOSocketAddress>)remote {
    NSAssert(false, @"override me!");
    return nil;
}

// Override
- (NSInteger)readWithBuffer:(NIOByteBuffer *)dst {
    NSAssert(false, @"override me!");
    return 0;
}

// Override
- (NSInteger)writeWithBuffer:(NIOByteBuffer *)src {
    NSAssert(false, @"override me!");
    return 0;
}

// Override
- (id<NIOSocketAddress>)localAddress {
    NSAssert(false, @"override me!");
    return nil;
}

@end
