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

@end
