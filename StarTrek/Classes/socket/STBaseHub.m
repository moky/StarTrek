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
//  STBaseHub.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <ObjectKey/ObjectKey.h>

#import "STBaseHub.h"

@interface __ConnectionPool : STAddressPairMap<id<STConnection>>

@end

@implementation __ConnectionPool

// Override
- (void)setObject:(id<STConnection>)value
        forRemote:(nullable id)remote local:(nullable id)local {
    id<STConnection> old = [self objectForRemote:remote local:local];
    if (old && old != value) {
        [self removeObject:old forRemote:remote local:local];
    }
    [super setObject:value forRemote:remote local:local];
}

// Override
- (id<STConnection>)removeObject:(nullable id<STConnection>)value
                       forRemote:(nullable id)remote local:(nullable id)local {
    id<STConnection> cached = [super removeObject:value forRemote:remote local:local];
    if ([cached isOpen]) {
        [cached close];
    }
    return cached;
}

@end

#pragma mark -

/*  Maximum Segment Size
 *  ~~~~~~~~~~~~~~~~~~~~
 *  Buffer size for receiving package
 *
 *  MTU        : 1500 bytes (excludes 14 bytes ethernet header & 4 bytes FCS)
 *  IP header  :   20 bytes
 *  TCP header :   20 bytes
 *  UDP header :    8 bytes
 */
static const NSInteger NIO_MSS = 1472;  // 1500 - 20 - 8

@interface STHub () {
    
    NSTimeInterval _lastTimeDriveConnections;
}

@property(nonatomic, strong) STAddressPairMap<id<STConnection>> *connectionPool;

@property(nonatomic, weak) id<STConnectionDelegate> delegate;

@end

@implementation STHub

- (instancetype)init {
    NSAssert(false, @"DON'T call me!");
    id<STConnectionDelegate> delegate = nil;
    return [self initWithConnectionDelegate:delegate];
}

/* designated initializer */
- (instancetype)initWithConnectionDelegate:(id<STConnectionDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        self.connectionPool = [self createConnectionPool];
        _lastTimeDriveConnections = OKGetCurrentTimeInterval();
    }
    return self;
}

- (STAddressPairMap<id<STConnection>> *)createConnectionPool {
    return [[__ConnectionPool alloc] init];
}

// Override
- (BOOL)process {
    // 1. drive all channels to receive data
    NSSet<id<STChannel>> *channels = [self allChannels];
    NSInteger count = [self driveChannels:channels];
    // 2. drive all connections to move on
    NSSet<id<STConnection>> *connections = [self allConnections];
    [self driveConnections:connections];
    // 3. cleanup closed channels and connections
    [self cleanupChannels:channels];
    [self cleanupConnections:connections];
    return count > 0;
}

// Override
- (nullable id<STConnection>)connectToRemoteAddress:(id<NIOSocketAddress>)remote
                                       localAddress:(nullable id<NIOSocketAddress>)local {
    id<STConnection> conn = [self connectionWithRemoteAddress:remote localAddress:local];
    if (conn) {
        // check local address
        if (!local) {
            return conn;
        }
        id<NIOSocketAddress> address = [conn localAddress];
        if (!address || [address isEqual:local]) {
            return conn;
        }
        // local address not matched? ignore this connection
    }
    // try to open channel with direction (remote, local)
    id<STChannel> sock = [self openChannelForRemoteAddress:remote localAddress:local];
    if (![sock isOpen]) {
        return nil;
    }
    // create with channel
    conn = [self createConnectionWithChannel:sock remoteAddress:remote localAddress:local];
    if (conn) {
        // NOTICE: local address in the connection may be set to None
        [self setConnection:conn
              remoteAddress:conn.remoteAddress
               localAddress:conn.localAddress];
    }
    return conn;
}

// Override
- (nullable id<STChannel>)openChannelForRemoteAddress:(nullable id<NIOSocketAddress>)remote
                                         localAddress:(nullable id<NIOSocketAddress>)local {
    NSAssert(false, @"override me!");
    return nil;
}

@end

@implementation STHub (Channel)

- (NSSet<id<STChannel>> *)allChannels {
    NSAssert(false, @"override me!");
    return nil;
}

- (void)removeChannel:(id<STChannel>)channel
        remoteAddress:(id<NIOSocketAddress>)remote
         localAddress:(id<NIOSocketAddress>)local {
    NSAssert(false, @"override me!");
}

@end

@implementation STHub (Connection)

- (id<STConnection>)createConnectionWithChannel:(id<STChannel>)channel
                                  remoteAddress:(id<NIOSocketAddress>)remote
                                   localAddress:(id<NIOSocketAddress>)local {
    NSAssert(false, @"override me!");
    return nil;
}

- (NSSet<id<STConnection>> *)allConnections {
    return [_connectionPool allValues];
}

- (id<STConnection>)connectionWithRemoteAddress:(id<NIOSocketAddress>)remote
                                   localAddress:(id<NIOSocketAddress>)local {
    return [_connectionPool objectForRemote:remote local:local];
}

- (void)setConnection:(id<STConnection>)conn
        remoteAddress:(id<NIOSocketAddress>)remote
         localAddress:(id<NIOSocketAddress>)local {
    [_connectionPool setObject:conn forRemote:remote local:local];
}

- (void)removeConnection:(id<STConnection>)conn
           remoteAddress:(id<NIOSocketAddress>)remote
            localAddress:(id<NIOSocketAddress>)local {
    [_connectionPool removeObject:conn forRemote:remote local:local];
}

@end

@implementation STHub (Processor)

- (NSUInteger)availableInChannel:(id<STChannel>)channel {
    NSAssert(false, @"override me!");
    return NIO_MSS;
}

- (BOOL)driveChannel:(id<STChannel>)sock {
    if (![sock isAlive]) {
        // cannot drive closed channel
        return NO;
    }
    NSUInteger capacity = [self availableInChannel:sock];
    if (capacity == 0) {
        // no data received
        return NO;
    }
    NIOByteBuffer *buffer = [NIOByteBuffer bufferWithCapacity:capacity];
    id<NIOSocketAddress> remote;
    id<NIOSocketAddress> local;
    id<STConnection> conn;
    // try to receive
    @try {
        remote = [sock receiveWithBuffer:buffer];
    } @catch (NIOException *e) {
        remote = [sock remoteAddress];
        local = [sock localAddress];
        id<STConnectionDelegate> delegate = [self delegate];
        if (!delegate || !remote) {
            // UDP channel may not connected,
            // so no connection for it
            [self removeChannel:sock remoteAddress:remote localAddress:local];
        } else {
            // remove channel and callback with connection
            conn = [self connectionWithRemoteAddress:remote localAddress:local];
            [self removeChannel:sock remoteAddress:remote localAddress:local];
            if (conn) {
                NIOError *error = [[NIOError alloc] initWithException:e];
                [delegate connection:conn error:error];
            }
        }
        return NO;
    } @finally {
    }
    if (!remote) {
        // received nothing
        return NO;
    }
    local = [sock localAddress];
    // get connection for processing received data
    conn = [self connectionWithRemoteAddress:remote localAddress:local];
    if (conn) {
        NSMutableData *data = [[NSMutableData alloc] initWithLength:[buffer position]];
        [buffer flip];
        [buffer getData:data];
        [conn onReceivedData:data];
    }
    return YES;
}

- (NSInteger)driveChannels:(NSSet<id<STChannel>> *)channels {
    NSInteger count = 0;
    for (id<STChannel> sock in channels) {
        // drive channel to receive data
        if ([self driveChannel:sock]) {
            count += 1;
        }
    }
    return count;
}

- (void)cleanupChannels:(NSSet<id<STChannel>> *)channels {
    for (id<STChannel> sock in channels) {
        if (![sock isAlive]) {
            // if channel not connected (TCP) and not bound (UDP),
            // means it's closed, remove it from the hub
            [self removeChannel:sock
                  remoteAddress:sock.remoteAddress
                   localAddress:sock.localAddress];
        }
    }
}

- (void)driveConnections:(NSSet<id<STConnection>> *)connections {
    NSTimeInterval now = OKGetCurrentTimeInterval();
    NSTimeInterval delta = now - _lastTimeDriveConnections;
    for (id<STConnection> conn in connections) {
        // drive connection to go on
        [conn tick:now elapsed:delta];
        // NOTICE: let the delegate to decide whether close an error connection
        //         or just remove it.
    }
    _lastTimeDriveConnections = now;
}

- (void)cleanupConnections:(NSSet<id<STConnection>> *)connections {
    for (id<STConnection> conn in connections) {
        if (![conn isOpen]) {
            // if connection closed, remove it from the hub; notice that
            // ActiveConnection can reconnect, it'll be not connected
            // but still open, don't remove it in this situation.
            [self removeConnection:conn
                     remoteAddress:conn.remoteAddress
                      localAddress:conn.localAddress];
        }
    }
}

@end
