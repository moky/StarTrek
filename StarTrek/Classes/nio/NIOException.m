//
//  NIOException.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import "NIOException.h"

@implementation NIOException

@end

#pragma mark Runtime

@implementation NIORuntimeException

@end

@implementation NIOIllegalArgumentException

@end

@implementation NIOBufferOverflowException

@end

@implementation NIOBufferUnderflowException

@end

@implementation NIOIndexOutOfBoundsException

@end

#pragma mark Socket

@implementation NIOSocketException

@end

@implementation NIOClosedChannelException

@end

#pragma mark -

@implementation NIOError

- (instancetype)initWithException:(NIOException *)e {
    if (self = [super init]) {
        self.exception = e;
    }
    return self;
}

@end
