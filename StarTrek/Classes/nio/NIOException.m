//
//  NIOException.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import "NIOException.h"

@implementation NIOException

- (instancetype)init {
    NSString *name = [NSString stringWithFormat:@"%@", [self class]];
    return [self initWithReason:name];
}

- (instancetype)initWithReason:(nullable NSString *)text {
    return [super initWithName:NSNetServicesErrorDomain reason:text userInfo:nil];
}

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

- (instancetype)init {
    return [super initWithDomain:NSNetServicesErrorDomain code:-1 userInfo:nil];
}

- (instancetype)initWithException:(NIOException *)e {
    NSDictionary *info = @{
        NSUnderlyingErrorKey: e
    };
    if (self = [self initWithDomain:NSNetServicesErrorDomain code:-2 userInfo:info]) {
        self.exception = e;
    }
    return self;
}

@end
