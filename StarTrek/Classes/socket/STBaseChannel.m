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
//  STBaseChannel.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import "NIOException.h"
#import "NIONetworkChannel.h"
#import "NIOByteChannel.h"
#import "NIOSocketChannel.h"
#import "NIODatagramChannel.h"

#import "STChannelController.h"

#import "STBaseChannel.h"

@interface STAddressPairObject (Hacking)

@property(nonatomic, strong, nullable) id<NIOSocketAddress> remoteAddress;
@property(nonatomic, strong, nullable) id<NIOSocketAddress> localAddress;

@end

@interface STChannel () {
    
    // flags
    BOOL _blocking;
    BOOL _opened;
    BOOL _connected;
    BOOL _bound;
}

@property(nonatomic, strong) id<STSocketReader> reader;
@property(nonatomic, strong) id<STSocketWriter> writer;

@property(nonatomic, strong) NIOSelectableChannel *socketChannel;

@end

static inline BOOL check_connected(NIOSelectableChannel *channel) {
    if ([channel isKindOfClass:[NIOSocketChannel class]]) {
        return [(NIOSocketChannel *)channel isConnected];
    } else if ([channel isKindOfClass:[NIODatagramChannel class]]) {
        return [(NIODatagramChannel *)channel isConnected];
    } else {
        return NO;
    }
}

static inline BOOL check_bound(NIOSelectableChannel *channel) {
    if ([channel isKindOfClass:[NIOSocketChannel class]]) {
        return [(NIOSocketChannel *)channel isBound];
    } else if ([channel isKindOfClass:[NIODatagramChannel class]]) {
        return [(NIODatagramChannel *)channel isBound];
    } else {
        return NO;
    }
}

@implementation STChannel

- (instancetype)initWithSocket:(NIOSelectableChannel *)sock
                 remoteAddress:(nullable id<NIOSocketAddress>)remote
                  localAddress:(nullable id<NIOSocketAddress>)local {
    if (self = [super initWithRemoteAddress:remote localAddress:local]) {
        self.reader = [self createReader];
        self.writer = [self createWriter];
        self.socketChannel = sock;
        [self refreshFlags];
    }
    return self;
}

//- (void)finalize {
//    // make sure the relative socket is removed
//    [self removeSocketChannel];
//    [super finalize];
//}

- (id<STSocketReader>)createReader {
    NSAssert(false, @"override me!");
    return nil;
}

- (id<STSocketWriter>)createWriter {
    NSAssert(false, @"override me!");
    return nil;
}

- (void)refreshFlags {
    NIOSelectableChannel *sock = _socketChannel;
    // update channel status
    if (sock) {
        _blocking = [sock isBlocking];
        _opened = [sock isOpen];
        _connected = check_connected(sock);
        _bound = check_bound(sock);
    }
}

// private
- (void)removeSocketChannel {
    // 1. clear inner channel
    NIOSelectableChannel *old = self.socketChannel;
    self.socketChannel = nil;
    // 2. refresh flags
    [self refreshFlags];
    // 3. close old channel
    if ([old isOpen]) {
        [old close];
    }
}

// Override
- (NIOSelectableChannel *)configureBlocking:(BOOL)blocking {
    NIOSelectableChannel *sock = [self socketChannel];
    if (!sock) {
        //@throw [[NIOSocketException alloc] init];
        return nil;
    }
    [sock configureBlocking:blocking];
    _blocking = blocking;
    return sock;
}

// Override
- (BOOL)isBlocking {
    return _blocking;
}

// Override
- (BOOL)isOpen {
    return _opened;
}

// Override
- (BOOL)isConnected {
    return _connected;
}

// Override
- (BOOL)isBound {
    return _bound;
}

// Override
- (BOOL)isAlive {
    return [self isOpen] && ([self isConnected] || [self isBound]);
}

// Override
- (NSString *)debugDescription {
    NSString *child = [_socketChannel debugDescription];
    return [NSString stringWithFormat:@"<%@ remote=\"%@\" local=\"%@\">\n\t%@\n</%@>",
    [self class], [self remoteAddress], [self localAddress], child, [self class]];
}

// Override
- (id<NIONetworkChannel>)bindLocalAddress:(id<NIOSocketAddress>)local throws:(NIOException **)error {
    if (!local) {
        local = [self localAddress];
        NSAssert(local, @"local address not set");
    }
    NIOSelectableChannel *sock = [self socketChannel];
    id<NIONetworkChannel> nc;
    
    NIOException *e = nil;
    if (!sock) {
        e = [[NIOSocketException alloc] init];
    } else {
        nc = [(id<NIONetworkChannel>)sock bindLocalAddress:local throws:&e];
    }
    if (e) {
        if (error) {
            *error = e;
        }
        //@throw e;
        return nil;
    }
    
    self.localAddress = local;
    _bound = YES;
    _opened = YES;
    _blocking = [sock isBlocking];
    return nc;
}

// Override
- (id<NIONetworkChannel>)connectRemoteAddress:(id<NIOSocketAddress>)remote throws:(NIOException **)error {
    if (!remote) {
        remote = [self remoteAddress];
        NSAssert(remote, @"remote address not set");
    }
    NIOSelectableChannel *sock = [self socketChannel];

    NIOException *e = nil;
    if (!sock) {
        e = [[NIOSocketException alloc] init];
    } else if ([sock isKindOfClass:[NIOSocketChannel class]]) {
        [(NIOSocketChannel *)sock connectRemoteAddress:remote throws:&e];
    } else if ([sock isKindOfClass:[NIODatagramChannel class]]) {
        [(NIODatagramChannel *)sock connectRemoteAddress:remote throws:&e];
    } else {
        e = [[NIOSocketException alloc] init];
    }
    if (e) {
        if (error) {
            *error = e;
        }
        //@throw e;
        return nil;
    }
    
    self.remoteAddress = remote;
    _connected = YES;
    _opened = YES;
    _blocking = [sock isBlocking];
    return (id<NIONetworkChannel>)sock;
}

// Override
- (id<NIOByteChannel>)disconnect {
    NIOSelectableChannel *sock = _socketChannel;
    if ([sock isKindOfClass:[NIODatagramChannel class]]) {
        NIODatagramChannel *udp = (NIODatagramChannel *)sock;
        if ([udp isConnected]) {
            return [udp disconnect];
        }
    } else {
        [self removeSocketChannel];
    }
    if ([sock conformsToProtocol:@protocol(NIOByteChannel)]) {
        return (id<NIOByteChannel>)sock;
    } else {
        return nil;
    }
}

// Override
- (void)close {
    // close inner socket and refresh flags
    [self removeSocketChannel];
}

//
//  Input/Output
//

// Override
- (NSInteger)readWithBuffer:(NIOByteBuffer *)dst throws:(NIOException **)error {
    NIOException *e = nil;
    NSInteger cnt = [self.reader readWithBuffer:dst throws:&e];
    if (!e) {
        // normal return
        return cnt;
    } else {
        // @catch (NIOException *e)
        [self close];

        if (error) {
            *error = e;
        }
        //@throw e;
        return cnt; // -1;
    }
}

// Override
- (NSInteger)writeWithBuffer:(NIOByteBuffer *)src throws:(NIOException **)error {
    NIOException *e = nil;
    NSInteger cnt = [self.writer writeWithBuffer:src throws:&e];
    if (!e) {
        // normal return
        return cnt;
    } else {
        // @catch (NIOException *e)
        [self close];
        
        if (error) {
            *error = e;
        }
        //@throw e;
        return cnt; // -1;
    }
}

// Override
- (id<NIOSocketAddress>)receiveWithBuffer:(NIOByteBuffer *)dst throws:(NIOException **)error {
    NIOException *e = nil;
    id<NIOSocketAddress> remote = [self.reader receiveWithBuffer:dst throws:&e];
    if (!e) {
        // normal return
        return remote;
    } else {
        // @catch (NIOException *e)
        [self close];

        if (error) {
            *error = e;
        }
        //@throw e;
        return remote; // nil;
    }
}

// Override
- (NSInteger)sendWithBuffer:(NIOByteBuffer *)src remoteAddress:(id<NIOSocketAddress>)remote
                     throws:(NIOException **)error {
    NIOException *e = nil;
    NSInteger cnt = [self.writer sendWithBuffer:src remoteAddress:remote throws:&e];
    if (!e) {
        // normal return
        return cnt;
    } else {
        // @catch (NIOException *e)
        [self close];

        if (error) {
            *error = e;
        }
        //@throw e;
        return cnt; // -1;
    }
}

@end
