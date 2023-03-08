//
//  NIOSelectableChannel.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import "NIOSelectableChannel.h"

@implementation NIOAbstractInterruptibleChannel

- (BOOL)isOpen {
    NSAssert(false, @"override me!");
    return NO;
}

- (void)close {
    NSAssert(false, @"override me!");
}

@end

@implementation NIOSelectableChannel

- (nullable NIOSelectableChannel *)configureBlocking:(BOOL)blocking {
    NSAssert(false, @"override me!");
    return nil;
}

- (BOOL)isBlocking {
    NSAssert(false, @"override me!");
    return NO;
}

@end
