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
//  STBaseConnection.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <ObjectKey/ObjectKey.h>

#import "STBaseConnection.h"

#define CONNECTION_EXPIRES 16.0  // seconds

@interface STConnection () {
    
    NSTimeInterval _lastSentTime;
    NSTimeInterval _lastReceivedTime;
    
    __strong STConnectionStateMachine *_fsm;
    
    __weak id<STChannel> _channel;
}

@end

@implementation STConnection

- (instancetype)initWithChannel:(id<STChannel>)channel
                  remoteAddress:(id<NIOSocketAddress>)remote
                   localAddress:(id<NIOSocketAddress>)local {
    if (self = [super initWithRemoteAddress:remote localAddress:local]) {
        self.channel = channel;
        self.delegate = nil;
        
        // active time
        _lastSentTime = 0;
        _lastReceivedTime = 0;
        
        // connection state machine
        _fsm = nil;
    }
    return self;
}

//- (void)finalize {
//    // make sure the relative channel is closed
//    [self setChannel:nil];
//    [self setStateMachine:nil];
//    [super finalize];
//}

// protected
- (STConnectionStateMachine *)stateMachine {
    return _fsm;
}

// private
- (void)setStateMachine:(STConnectionStateMachine *)newMachine {
    // 1. replace with new machine
    STConnectionStateMachine *oldMachine = _fsm;
    _fsm = newMachine;
    // 2. stop old machine
    if (oldMachine && oldMachine != newMachine) {
        [oldMachine stop];
    }
}

// protected
- (STConnectionStateMachine *)createStateMachine {
    STConnectionStateMachine *machine;
    machine = [[STConnectionStateMachine alloc] initWithConnection:self];
    [machine setDelegate:self];
    return machine;
}

// protected
- (id<STChannel>)channel {
    return _channel;
}

// protected
- (void)setChannel:(id<STChannel>)newChannel {
    // 1. replace with new channel
    id<STChannel> oldChannel = _channel;
    _channel = newChannel;
    // 2. close old channel
    if (oldChannel && oldChannel != newChannel) {
        if ([oldChannel isConnected]) {
            @try {
                [oldChannel disconnect];
            } @catch (NIOException *e) {
            } @finally {
            }
        }
    }
}

// Override
- (BOOL)isOpen {
    id<STChannel> sock = [self channel];
    return [sock isOpen];
}

// Override
- (BOOL)isBound {
    id<STChannel> sock = [self channel];
    return [sock isBound];
}

// Override
- (BOOL)isConnected {
    id<STChannel> sock = [self channel];
    return [sock isConnected];
}

// Override
- (BOOL)isAlive {
    //id<STChannel> sock = [self channel];
    //return [sock isAlive];
    return [self isOpen] && ([self isConnected] || [self isBound]);
}

// Override
- (NSString *)debugDescription {
    NSString *child = [_channel debugDescription];
    return [NSString stringWithFormat:@"<%@ remote=\"%@\" local=\"%@\">\n\t%@\n</%@>",
    [self class], [self remoteAddress], [self localAddress], child, [self class]];
}

// Override
- (void)close {
    [self setChannel:nil];
    [self setStateMachine:nil];
}

- (void)start {
    STConnectionStateMachine *machine = [self createStateMachine];
    [machine start];
    [self setStateMachine:machine];
}

- (void)stop {
    [self setChannel:nil];
    [self setStateMachine:nil];
}

//
//  I/O
//

// Override
- (void)onReceivedData:(NSData *)data {
    _lastReceivedTime = OKGetCurrentTimeInterval();
    [_delegate connection:self receivedData:data];
}

// protected
- (NSInteger)sendBuffer:(NIOByteBuffer *)src remoteAddress:(id<NIOSocketAddress>)destination {
    id<STChannel> sock = [self channel];
    if (![sock isAlive]) {
        //@throw [[NIOException alloc] init];
        return -1;
    }
    NSInteger sent = [sock sendWithBuffer:src remoteAddress:destination];
    if (sent > 0) {
        // update sent time
        _lastSentTime = OKGetCurrentTimeInterval();
    }
    return sent;
}

// Override
- (NSInteger)sendData:(NSData *)pack {
    // try to send data
    NIOError *error = nil;
    NSInteger sent = -1;
    @try {
        // prepare buffer
        NIOByteBuffer *buffer = [NIOByteBuffer bufferWithCapacity:pack.length];
        [buffer putData:pack];
        // send buffer
        id<NIOSocketAddress> destination = [self remoteAddress];
        sent = [self sendBuffer:buffer remoteAddress:destination];
        if (sent < 0) {  // == -1
            @throw [[NIOException alloc] init];
        }
    } @catch (NIOException *e) {
        error = [[NIOError alloc] initWithException:e];
        // socket error, close current channel
        [self setChannel:nil];
    } @finally {
    }
    // callback
    if (error) {
        [_delegate connection:self failedToSendData:pack error:error];
    } else {
        [_delegate connection:self sentData:pack withLength:sent];
    }
    return sent;
}

//
//  States
//

// Override
- (STConnectionState *)state {
    STConnectionStateMachine *machine = [self stateMachine];
    return [machine currentState];
}

// Override
- (void)tick:(NSTimeInterval)now elapsed:(NSTimeInterval)delta {
    STConnectionStateMachine *machine = [self stateMachine];
    if (machine) {
        [machine tick:now elapsed:delta];
    }
}

//
//  Timed
//

// Override
- (NSTimeInterval)lastSentTime {
    return _lastSentTime;
}

// Override
- (NSTimeInterval)lastReceivedTime {
    return _lastReceivedTime;
}

// Override
- (BOOL)isSentRecently:(NSTimeInterval)now {
    return now <= _lastSentTime + CONNECTION_EXPIRES;
}

// Override
- (BOOL)isReceivedRecently:(NSTimeInterval)now {
    return now <= _lastReceivedTime + CONNECTION_EXPIRES;
}

// Override
- (BOOL)isNotReceivedLongTimeAgo:(NSTimeInterval)now {
    return now > _lastReceivedTime + (CONNECTION_EXPIRES * 8);
}

//
//  Events
//

// Override
- (void)machine:(__kindof id<FSMContext>)ctx
     enterState:(__kindof id<FSMState>)next
           time:(NSTimeInterval)now {
    
}

// Override
- (void)machine:(STConnectionStateMachine *)ctx
      exitState:(STConnectionState *)previous
           time:(NSTimeInterval)now {
    STConnectionState *current = [ctx currentState];
    // if current == 'ready'
    if (current && current.index == STConnectionStateOrderReady) {
        // if previous == 'preparing'
        if (previous && previous.index == STConnectionStateOrderPreparing) {
            // connection state changed from 'preparing' to 'ready',
            // set times to expired soon.
            NSTimeInterval timestamp = now - (CONNECTION_EXPIRES / 2);
            if (_lastSentTime < timestamp) {
                _lastSentTime = timestamp;
            }
            if (_lastReceivedTime < timestamp) {
                _lastReceivedTime = timestamp;
            }
        }
    }
    // callback
    [_delegate connection:self changedState:previous toState:current];
}

// Override
- (void)machine:(__kindof id<FSMContext>)ctx
     pauseState:(__kindof id<FSMState>)current
           time:(NSTimeInterval)now {
    
}

// Override
- (void)machine:(__kindof id<FSMContext>)ctx
    resumeState:(__kindof id<FSMState>)current
           time:(NSTimeInterval)now {
    
}

@end

@interface STActiveConnection ()

@property(nonatomic, weak) id<STHub> hub;

@end

@implementation STActiveConnection

- (instancetype)initWithHub:(id<STHub>)hub
                    channel:(id<STChannel>)channel
              remoteAddress:(id<NIOSocketAddress>)remote
               localAddress:(id<NIOSocketAddress>)local {
    if (self = [super initWithChannel:channel remoteAddress:remote localAddress:local]) {
        self.hub = hub;
    }
    return self;
}

// Override
- (BOOL)isOpen {
    return [self stateMachine] != nil;
}

// Override
- (id<STChannel>)channel {
    id<STChannel> sock = [super channel];
    if (![sock isOpen]) {
        if ([self stateMachine] == nil) {
            // closed (not start yet)
            return nil;
        }
        // get new channel via hub
        id<NIOSocketAddress> remote = [self remoteAddress];
        id<NIOSocketAddress> local = [self localAddress];
        sock = [self.hub openChannelForRemoteAddress:remote localAddress:local];
        NSAssert(sock, @"failed to open channel: %@, %@", remote, local);
        [self setChannel:sock];
    }
    return sock;
}

@end
