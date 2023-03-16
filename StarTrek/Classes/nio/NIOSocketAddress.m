//
//  NIOSocketAddress.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import "NIOSocketAddress.h"

@interface NIOInetSocketAddress ()

@property(nonatomic, strong) NSString *desc;

@property(nonatomic, strong) NSString *host;
@property(nonatomic, assign) UInt16 port;

@end

@implementation NIOInetSocketAddress

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
        self.desc = [NSString stringWithFormat:@"('%@', %u)", _host, _port];
    }
    return self;
}

#pragma mark Object

- (NSString *)description {
    return _desc;
}

- (NSString *)debugDescription {
    return _desc;
}

- (NSUInteger)hash {
    return [_host hash] + _port * 13;
}

- (BOOL)isEqual:(id)object {
    if ([object conformsToProtocol:@protocol(NIOSocketAddress)]) {
        // compare with wrapper
        if (object == self) {
            return YES;
        }
        // compare with host & port
        id<NIOSocketAddress> other = (id<NIOSocketAddress>)object;
        return other.port == _port && [other.host isEqualToString:_host];
    } else if ([object isKindOfClass:[NSString class]]) {
        return [_desc isEqual:object];
    }
    return NO;
}

@end

@implementation NIOInetSocketAddress (Creation)

+ (instancetype)addressWithHost:(NSString *)ip port:(UInt16)port {
    NIOInetSocketAddress *address;
    address = [[NIOInetSocketAddress alloc] initWithHost:ip port:port];
    return address;
}

@end
