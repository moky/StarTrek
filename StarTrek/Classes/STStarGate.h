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
//  STStarGate.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/9.
//

#import <StarTrek/STAddressPairMap.h>
#import <StarTrek/STConnection.h>
#import <StarTrek/STDocker.h>
#import <StarTrek/STGate.h>

NS_ASSUME_NONNULL_BEGIN

@interface STGate : NSObject <STGate, STConnectionDelegate>

// delegate for handling docker events
@property(nonatomic, weak, readonly) id<STDockerDelegate> delegate;

- (instancetype)initWithDockerDelegate:(id<STDockerDelegate>)delegate
NS_DESIGNATED_INITIALIZER;

// protected
- (STAddressPairMap<id<STDocker>> *)createDockerPool;

@end

// protected
@interface STGate (Docker)

@property(nonatomic, copy, readonly) NSSet<id<STDocker>> *allDockers;

/**
 *  Create new docker for received data
 *
 * @param conn   - current connection
 * @param data   - advance party
 * @return docker
 */
- (id<STDocker>)createDockerWithConnection:(id<STConnection>)conn advanceParty:(NSArray<NSData *> *)data;

- (id<STDocker>)dockerWithRemoteAddress:(id<NIOSocketAddress>)remote
                           localAddress:(nullable id<NIOSocketAddress>)local;

- (void)setDocker:(id<STDocker>)worker
    remoteAddress:(id<NIOSocketAddress>)remote
     localAddress:(nullable id<NIOSocketAddress>)local;

- (void)removeDocker:(nullable id<STDocker>)worker
       remoteAddress:(id<NIOSocketAddress>)remote
        localAddress:(nullable id<NIOSocketAddress>)local;

@end

// protected
@interface STGate (Processor)

- (NSInteger)driveDockers:(NSSet<id<STDocker>> *)workers;

- (void)cleanupDockers:(NSSet<id<STDocker>> *)workers;

@end

// protected
@interface STGate (Ping)

/**
 *  Send a heartbeat package('PING') to remote address
 */
- (void)heartbeat:(id<STConnection>)connection;

@end

// protected
@interface STGate (Decision)

// cache the advance party before decide which docker to use
- (NSArray<NSData *> *)cacheAdvanceParty:(NSData *)data
                           forConnection:(id<STConnection>)conn;

- (void)clearAdvancePartyForConnection:(id<STConnection>)conn;

@end

NS_ASSUME_NONNULL_END
