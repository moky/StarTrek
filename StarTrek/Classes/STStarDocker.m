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
//  STStarDocker.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/9.
//

#import <ObjectKey/ObjectKey.h>

#import "STStarDocker.h"

@interface STDocker ()

@property(nonatomic, weak) id<STConnection> connection;

@property(nonatomic, strong) STDock *dock;

// remaining data to be sent
@property(nonatomic, strong) id<STDeparture> lastOutgo;
@property(nonatomic, strong) NSArray<NSData *> *lastFragments;

@end

@implementation STDocker

- (instancetype)initWithRemoteAddress:(id<NIOSocketAddress>)remote
                         localAddress:(id<NIOSocketAddress>)local {
    NSAssert(false, @"don't call me!");
    id<STConnection> conn = nil;
    return [self initWithConnection:conn];
}

/* designated initializer */
- (instancetype)initWithConnection:(id<STConnection>)conn {
    if (self = [super initWithRemoteAddress:conn.remoteAddress
                               localAddress:conn.localAddress]) {
        self.connection = conn;
        self.delegate = nil;
        self.dock = [self createDock];
        self.lastOutgo = nil;
        self.lastFragments = nil;
    }
    return self;
}

//- (void)finalize {
//    // make sure the relative connection is closed
//    [self removeConnection];
//    self.dock = nil;
//    [super finalize];
//}

// override for user-customized dock
- (STDock *)createDock {
    return [[STLockedDock alloc] init];
}

// private
- (void)removeConnection {
    // 1. clear connection reference
    id<STConnection> old = [self connection];
    self.connection = nil;
    // 2. close old connection
    if ([old isOpen]) {
        [old close];
    }
}

// Override
- (BOOL)isOpen {
    id<STConnection> conn = [self connection];
    return [conn isOpen];
}

// Override
- (BOOL)isAlive {
    id<STConnection> conn = [self connection];
    return [conn isAlive];
}

// Override
- (STDockerStatus)status {
    id<STConnection> conn = [self connection];
    if (!conn) {
        return STDockerStatusError;
    }
    return STDockerStatusFromConnectionState([conn state]);
}

//// Override
//- (id<NIOSocketAddress>)localAddress {
//    id<STConnection> conn = [self connection];
//    if (conn) {
//        return [conn localAddress];
//    }
//    return [super localAddress];
//}

// Override
- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ remote=\"%@\" local=\"%@\">\n\t%@\n</%@>",
    [self class], [self remoteAddress], [self localAddress], _connection, [self class]];
}

// Override
- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ remote=\"%@\" local=\"%@\">\n\t%@\n</%@>",
    [self class], [self remoteAddress], [self localAddress], _connection, [self class]];
}

// Override
- (BOOL)sendShip:(id<STDeparture>)ship {
    return [_dock addDeparture:ship];
}

// Override
- (void)processReceivedData:(NSData *)data {
    // 1. get income ship from received data
    id<STArrival> income = [self arrivalWithData:data];
    if (!income) {
        // waiting for more data
        return;
    }
    // 2. check income ship for respose
    income = [self checkArrival:income];
    if (!income) {
        // waiting for more fragment
    }
    // 3. callback for processing income ship with completed data package
    [_delegate docker:self receivedShip:income];
}

// Override
- (void)purge {
    [_dock purge];
}

// Override
- (void)close {
    [self removeConnection];
    self.dock = nil;
}

// Override
- (void)heartbeat {
    NSAssert(false, @"override me!");
}

// Override
- (BOOL)sendData:(nonnull NSData *)payload {
    NSAssert(false, @"override me!");
    return NO;
}

// Override
- (BOOL)process {
    // 1. get connection which is ready for sending data
    id<STConnection> conn = [self connection];
    if (![conn isAlive]) {
        // connection not ready now
        return NO;
    }
    NIOException *exception;
    NIOError *error;
    // 2. get data waiting to be sent out
    id<STDeparture> outgo;
    NSArray<NSData *> *fragments;
    if ([_lastFragments count] > 0) {
        // get remaining fragments from last outgo task
        outgo = self.lastOutgo;
        fragments = self.lastFragments;
        self.lastOutgo = nil;
        self.lastFragments = nil;
    } else {
        // get next outgo task
        NSTimeInterval now = OKGetCurrentTimeInterval();
        outgo = [self nextDepartureWithTime:now];
        if (!outgo) {
            // nothing to do now, return false to let the thread have a rest
            return NO;
        } else if ([outgo status:now] == STShipStatusFailed) {
            id<STDockerDelegate> delegate = [self delegate];
            if (delegate) {
                // callback for mission failed
                exception = [[NIOSocketException alloc] init];  // Request timeout
                error = [[NIOError alloc] initWithException:exception];
                [delegate docker:self failedToSendShip:outgo error:error];
            }
            // task timeout, return true to process next one
            return YES;
        } else {
            // get fragments from outgo task
            fragments = [outgo fragments];
            if ([fragments count] == 0) {
                // all fragments of this task have been sent already
                // return true to process next one
                return YES;
            }
        }
    }
    // 3. process fragments of outgo task
    NSInteger index = 0, sent = 0;
    @try {
        for (NSData *fra in fragments) {
            sent = [conn sendData:fra];
            if (sent < fra.length) {
                // buffer overflow?
                break;
            } else {
                NSAssert(sent == fra.length, @"length of fragment sent error: %ld, %ld", sent, fra.length);
                index += 1;
                sent = 0;  // clear counter
            }
        }
        if (index < [fragments count]) {
            // task failed
            exception = [[NIOSocketException alloc] init];
            error = [[NIOError alloc] initWithException:exception];
        } else {
            // task done
            return YES;
        }
    } @catch (NIOException *ex) {
        error = [[NIOError alloc] initWithException:ex];
    } @finally {
    }
    // 4. remove sent fragments
    if (index > 0) {
        NSUInteger len = [fragments count] - index;
        fragments = [fragments subarrayWithRange:NSMakeRange(index, len)];
    }
    // remove partially sent data of next fragment
    if (sent > 0) {
        NSData *next = [fragments firstObject];
        NSUInteger len = [next length] - sent;
        next = [next subdataWithRange:NSMakeRange(sent, len)];
        NSMutableArray *mArray;
        if ([fragments isKindOfClass:[NSMutableArray class]]) {
            mArray = (NSMutableArray *)fragments;
        } else {
            mArray = [fragments mutableCopy];
        }
        [mArray replaceObjectAtIndex:0 withObject:next];
        fragments = mArray;
    }
    // 5. store remaining data
    self.lastOutgo = outgo;
    self.lastFragments = fragments;
    // 6. callback for error
    [_delegate docker:self sendingShip:outgo error:error];
    return NO;
}

@end

@implementation STDocker (Shipping)

- (id<STArrival>)arrivalWithData:(NSData *)data {
    NSAssert(false, @"override me!");
    return nil;
}

- (id<STArrival>)checkArrival:(id<STArrival>)income {
    NSAssert(false, @"override me!");
    return nil;
}

- (void)checkResponseInArrival:(id<STArrival>)income {
    // check response for linked departure ship (same SN)
    id<STDeparture> linked = [_dock checkResponseInArrival:income];
    if (!linked) {
        // linked departure task not found, or not finished yet
        return;
    }
    // all fragments responded, task finished
    [_delegate docker:self sentShip:linked];
}


- (id<STArrival>)assembleArrival:(id<STArrival>)income {
    return [_dock assembleArrival:income];
}
- (id<STDeparture>)nextDepartureWithTime:(NSTimeInterval)now {
    return [_dock nextDepartureWithTime:now];
}

@end
