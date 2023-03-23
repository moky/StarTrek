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
//  STConnectionState.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import <FiniteStateMachine/FiniteStateMachine.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(UInt8, STConnectionStateOrder) {
    STConnectionStateOrderDefault = 0,
    STConnectionStateOrderPreparing,
    STConnectionStateOrderReady,
    STConnectionStateOrderMaintaining,
    STConnectionStateOrderExpired,
    STConnectionStateOrderError
};

/**
 *  Connection State
 *  ~~~~~~~~~~~~~~~~
 *
 *  Defined for indicating connection state
 *
 *      DEFAULT     - 'initialized', or sent timeout
 *      PREPARING   - connecting or binding
 *      READY       - got response recently
 *      EXPIRED     - long time, needs maintaining (still connected/bound)
 *      MAINTAINING - sent 'PING', waiting for response
 *      ERROR       - long long time no response, connection lost
 */
@interface STConnectionState : SMState

@property(nonatomic, readonly) NSTimeInterval enterTime;

@end

/**
 *  Connection State Delegate
 *  ~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 *  callback when connection state changed
 */
@protocol STConnectionStateDelegate <SMDelegate>

@end

@class STConnectionStateTransitionBuilder;

/**
 *  State Builder
 *  ~~~~~~~~~~~~~
 */
@interface STConnectionStateBuilder : NSObject

- (instancetype)initWithTransitionBuilder:(STConnectionStateTransitionBuilder *)builder;

// Connection not started yet
- (STConnectionState *)defaultState;

// Connection started, preparing to connect/bind
- (STConnectionState *)preparingState;

// Normal state of connection
- (STConnectionState *)readyState;

// Long time no response, need maintaining
- (STConnectionState *)expiredState;

// Heartbeat sent, waiting response
- (STConnectionState *)maintainingState;

// Connection lost
- (STConnectionState *)errorState;

@end

NS_ASSUME_NONNULL_END
