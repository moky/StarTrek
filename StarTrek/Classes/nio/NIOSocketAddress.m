//
//  NIOSocketAddress.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import "NIOSocketAddress.h"

@interface NIOSocketAddress ()

@property(nonatomic, strong) NSString *host;
@property(nonatomic, assign) UInt16 port;

@end

@implementation NIOSocketAddress

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
    if ([object conformsToProtocol:@protocol(NIOSocketAddress)]) {
        // compare with wrapper
        if (object == self) {
            return YES;
        }
        // compare with host & port
        id<NIOSocketAddress> other = (id<NIOSocketAddress>)object;
        return other.port == _port && [other.host isEqualToString:_host];
    }
    return NO;
}

@end

@implementation NIOSocketAddress (Creation)

+ (instancetype)addressWithHost:(NSString *)ip port:(UInt16)port {
    NIOSocketAddress *address = [[NIOSocketAddress alloc] initWithHost:ip port:port];
    return address;
}

@end
