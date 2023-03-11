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
//  STStarGate.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/9.
//

#import "STStarGate.h"

@interface __DockerPool : STAddressPairMap<id<STDocker>>

@end

@implementation __DockerPool

// Override
- (void)setObject:(id<STDocker>)value
        forRemote:(nullable id)remote local:(nullable id)local {
    id<STDocker> old = [self objectForRemote:remote local:local];
    if (old && old != value) {
        [self removeObject:old forRemote:remote local:local];
    }
    [super setObject:value forRemote:remote local:local];
}

// Override
- (id<STDocker>)removeObject:(nullable id<STDocker>)value
                   forRemote:(nullable id)remote local:(nullable id)local {
    id<STDocker> cached = [super removeObject:value forRemote:remote local:local];
    if ([cached isOpen]) {
        [cached close];
    }
    return cached;
}

@end

#pragma mark -

@interface STGate ()

@property(nonatomic, strong) STAddressPairMap<id<STDocker>> *dockerPool;

@property(nonatomic, weak) id<STDockerDelegate> delegate;

@end

@implementation STGate

- (instancetype)init {
    NSAssert(false, @"DON'T call me!");
    id<STDockerDelegate> delegate = nil;
    return [self initWithDockerDelegate:delegate];
}

/* designated initializer */
- (instancetype)initWithDockerDelegate:(id<STDockerDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        self.dockerPool = [self createDockerPool];
    }
    return self;
}

- (STAddressPairMap<id<STDocker>> *)createDockerPool {
    return [[__DockerPool alloc] init];
}

// Override
- (BOOL)sendData:(NSData *)payload
   remoteAddress:(id<NIOSocketAddress>)remote
    localAddress:(nullable id<NIOSocketAddress>)local {
    id<STDocker> docker = [self dockerWithRemoteAddress:remote localAddress:local];
    if ([docker isOpen]) {
        return [docker sendData:payload];
    } else {
        return NO;
    }
}

// Override
- (BOOL)sendShip:(id<STDeparture>)outgo
   remoteAddress:(id<NIOSocketAddress>)remote
    localAddress:(nullable id<NIOSocketAddress>)local {
    id<STDocker> docker = [self dockerWithRemoteAddress:remote localAddress:local];
    if ([docker isOpen]) {
        return [docker sendShip:outgo];
    } else {
        return NO;
    }
}

// Override
- (BOOL)process {
    NSSet<id<STDocker>> *dockers = [self allDockers];
    // 1. drive all dockers to process
    NSInteger count = [self driveDockers:dockers];
    // 2. cleanup dockers
    [self cleanupDockers:dockers];
    return count > 0;
}

//
//  Connection Delegate
//

// Override
- (void)connection:(id<STConnection>)conn
      changedState:(STConnectionState *)previous
           toState:(STConnectionState *)current {
    // 1. callback when status changed
    id<STDockerDelegate> delegate = [self delegate];
    if (delegate) {
        STDockerStatus s1 = STDockerStatusFromConnectionState(previous);
        STDockerStatus s2 = STDockerStatusFromConnectionState(current);
        // check status
        if (s1 != s2) {
            // callback
            id<STDocker> worker = [self dockerWithRemoteAddress:conn.remoteAddress
                                                   localAddress:conn.localAddress];
            // NOTICE: if the previous state is null, the docker maybe not
            //         created yet, this situation means the docker status
            //         not changed too, so no need to callback here.
            if (worker) {
                [delegate docker:worker changedStatus:s1 toStatus:s2];
            }
        }
    }
    // 2. heartbeat when connection expired
    if (current.index == STConnectionStateOrderExpired) {
        [self heartbeat:conn];
    }
}

// Override
- (void)connection:(id<STConnection>)conn receivedData:(NSData *)data {
    // get docker by (remote, local)
    id<STDocker> worker = [self dockerWithRemoteAddress:conn.remoteAddress
                                           localAddress:conn.localAddress];
    if (worker) {
        // docker exists, call docker.onReceived(data);
        [worker processReceivedData:data];
        return;
    }
    
    // cache advance party for this connection
    NSArray<NSData *> * advanceParty = [self cacheAdvanceParty:data
                                                 forConnection:conn];
    NSAssert([advanceParty count] > 0, @"advance party error");
    
    // docker not exists, check the data to decide which docker should be created
    worker = [self createDockerWithConnection:conn advanceParty:advanceParty];
    if (worker) {
        // cache docker for (remote, local)
        [self setDocker:worker
          remoteAddress:worker.remoteAddress
           localAddress:worker.localAddress];
        // process advance parties one by one
        for (NSData *part in advanceParty) {
            [worker processReceivedData:part];
        }
        // remove advance party
        [self clearAdvancePartyForConnection:conn];
    }
}

// Override
- (void)connection:(id<STConnection>)connection
          sentData:(NSData *)data withLength:(NSInteger)sent {
    // ignore event for sending success
}

// Override
- (void)connection:(id<STConnection>)connection failedToSendData:(NSData *)data
             error:(NIOError *)error {
    // ignore event for sending failed
}

// Override
- (void)connection:(id<STConnection>)connection error:(NIOError *)error {
    // ignore event for receiveing error
}

@end

@implementation STGate (Docker)

- (id<STDocker>)createDockerWithConnection:(id<STConnection>)conn
                              advanceParty:(NSArray<NSData *> *)data {
    NSAssert(false, @"override me!");
    return nil;
}

- (NSSet<id<STDocker>> *)allDockers {
    return [_dockerPool allValues];
}

- (id<STDocker>)dockerWithRemoteAddress:(id<NIOSocketAddress>)remote
                           localAddress:(nullable id<NIOSocketAddress>)local {
    return [_dockerPool objectForRemote:remote local:local];
}

- (void)setDocker:(id<STDocker>)worker
    remoteAddress:(id<NIOSocketAddress>)remote
     localAddress:(nullable id<NIOSocketAddress>)local {
    [_dockerPool setObject:worker forRemote:remote local:local];
}

- (void)removeDocker:(nullable id<STDocker>)worker
       remoteAddress:(id<NIOSocketAddress>)remote
        localAddress:(nullable id<NIOSocketAddress>)local {
    [_dockerPool removeObject:worker forRemote:remote local:local];
}

@end

@implementation STGate (Processor)

- (NSInteger)driveDockers:(NSSet<id<STDocker>> *)workers {
    __block NSInteger count = 0;
    [workers enumerateObjectsWithOptions:NSEnumerationConcurrent
                              usingBlock:^(id<STDocker> docker, BOOL *stop) {
        if ([docker process]) {
            ++count;  // it's buzy
        }
    }];
    return count > 0;
}

- (void)cleanupDockers:(NSSet<id<STDocker>> *)workers {
    __weak __typeof(self) weakSelf = self;
    [workers enumerateObjectsWithOptions:NSEnumerationConcurrent
                              usingBlock:^(id<STDocker> docker, BOOL *stop) {
        if ([docker isOpen]) {
            // clear expired tasks
            [docker purge];
        } else {
            // remove docker when connection closed
            [weakSelf removeDocker:docker
                     remoteAddress:docker.remoteAddress
                      localAddress:docker.localAddress];
        }
    }];
}

@end

@implementation STGate (Ping)

- (void)heartbeat:(id<STConnection>)conn {
    id<STDocker> worker = [self dockerWithRemoteAddress:conn.remoteAddress
                                           localAddress:conn.localAddress];
    [worker heartbeat];
}

@end

@implementation STGate (Decision)

// cache the advance party before decide which docker to use
- (NSArray<NSData *> *)cacheAdvanceParty:(NSData *)data
                           forConnection:(id<STConnection>)conn {
    NSAssert(false, @"override me!");
    return nil;
}

- (void)clearAdvancePartyForConnection:(id<STConnection>)conn {
    NSAssert(false, @"override me!");
}

@end
