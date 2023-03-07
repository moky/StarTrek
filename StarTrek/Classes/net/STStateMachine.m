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
//  STStateMachine.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import "STConnection.h"
#import "STConnectionState.h"

#import "STStateMachine.h"

@interface STConnectionStateMachine ()

@property(nonatomic, weak) id<STConnection> connection;

@end

@implementation STConnectionStateMachine

- (instancetype)initWithConnection:(id<STConnection>)connection {
    if (self = [super initWithDefaultStateName:kSTConnectionStateDefault capacity:6]) {
        self.connection = connection;
        // init states
        STConnectionStateBuilder *builder = [self createStateBuilder];
        [self addState:[builder defaultState]];
        [self addState:[builder preparingState]];
        [self addState:[builder readyState]];
        [self addState:[builder expiredState]];
        [self addState:[builder maintainingState]];
        [self addState:[builder errorState]];
    }
    return self;
}

- (STConnectionStateBuilder *)createStateBuilder {
    STConnectionStateTransitionBuilder *stb;
    stb = [[STConnectionStateTransitionBuilder alloc] init];
    return [[STConnectionStateBuilder alloc] initWithTransitionBuilder:stb];
}

// Override
- (id<FSMContext>)context {
    return self;
}

@end

static inline FSMTransition *create_transition(NSString *name, FSMBlock block) {
    return [[FSMBlockTransition alloc] initWithTargetStateName:name block:block];
}

@implementation STConnectionStateTransitionBuilder

// Default -> Preparing
- (FSMTransition *)defaultPreparingTransition {
    return create_transition(kSTConnectionStatePreparing, ^BOOL(STConnectionStateMachine *machine, NSTimeInterval now) {
        id<STConnection> conn = [machine connection];
        // connection started? change state to 'preparing'
        return [conn isOpen];
    });
}

// Preparing -> Ready
- (FSMTransition *)preparingReadyTransition {
    return create_transition(kSTConnectionStatePreparing, ^BOOL(STConnectionStateMachine *machine, NSTimeInterval now) {
        id<STConnection> conn = [machine connection];
        // connected or bound, change state to 'ready'
        return [conn isAlive];
    });
}

// Preparing -> Default
- (FSMTransition *)preparingDefaultTransition {
    return create_transition(kSTConnectionStatePreparing, ^BOOL(STConnectionStateMachine *machine, NSTimeInterval now) {
        id<STConnection> conn = [machine connection];
        // connection stopped, change state to 'not_connect'
        return ![conn isOpen];
    });
}

// Ready -> Expired
- (FSMTransition *)readyExpiredTransition {
    return create_transition(kSTConnectionStatePreparing, ^BOOL(STConnectionStateMachine *machine, NSTimeInterval now) {
        id<STConnection> conn = [machine connection];
        if (![conn isAlive]) {
            return NO;
        }
        id<STTimedConnection> timed = (id<STTimedConnection>)conn;
        // connection still alive, but
        // long time no response, change state to 'maintain_expired'
        return ![timed isReceivedRecently:now];
    });
}

// Ready -> Error
- (FSMTransition *)readyErrorTransition {
    return create_transition(kSTConnectionStatePreparing, ^BOOL(STConnectionStateMachine *machine, NSTimeInterval now) {
        id<STConnection> conn = [machine connection];
        // connection lost, change state to 'error'
        return ![conn isAlive];
    });
}

// Expired -> Maintaining
- (FSMTransition *)expiredMaintainingTransition {
    return create_transition(kSTConnectionStatePreparing, ^BOOL(STConnectionStateMachine *machine, NSTimeInterval now) {
        id<STConnection> conn = [machine connection];
        if (![conn isAlive]) {
            return NO;
        }
        id<STTimedConnection> timed = (id<STTimedConnection>)conn;
        // connection still alive, and
        // sent recently, change state to 'maintaining'
        return [timed isSentRecently:now];
    });
}

// Expired -> Error
- (FSMTransition *)expiredErrorTransition {
    return create_transition(kSTConnectionStatePreparing, ^BOOL(STConnectionStateMachine *machine, NSTimeInterval now) {
        id<STConnection> conn = [machine connection];
        if (![conn isAlive]) {
            return YES;
        }
        id<STTimedConnection> timed = (id<STTimedConnection>)conn;
        // connection lost, or
        // long long time no response, change state to 'error'
        return [timed isNotReceivedLongTimeAgo:now];
    });
}

// Maintaining -> Ready
- (FSMTransition *)maintainingReadyTransition {
    return create_transition(kSTConnectionStatePreparing, ^BOOL(STConnectionStateMachine *machine, NSTimeInterval now) {
        id<STConnection> conn = [machine connection];
        if (![conn isAlive]) {
            return NO;
        }
        id<STTimedConnection> timed = (id<STTimedConnection>)conn;
        // connection still alive, and
        // received recently, change state to 'ready'
        return [timed isReceivedRecently:now];
    });
}

// Maintaining -> Expired
- (FSMTransition *)maintainingExpiredTransition {
    return create_transition(kSTConnectionStatePreparing, ^BOOL(STConnectionStateMachine *machine, NSTimeInterval now) {
        id<STConnection> conn = [machine connection];
        if (![conn isAlive]) {
            return NO;
        }
        id<STTimedConnection> timed = (id<STTimedConnection>)conn;
        // connection still alive, but
        // long time no sending, change state to 'maintain_expired'
        return ![timed isSentRecently:now];
    });
}

// Maintaining -> Error
- (FSMTransition *)maintainingErrorTransition {
    return create_transition(kSTConnectionStatePreparing, ^BOOL(STConnectionStateMachine *machine, NSTimeInterval now) {
        id<STConnection> conn = [machine connection];
        if (![conn isAlive]) {
            return YES;
        }
        id<STTimedConnection> timed = (id<STTimedConnection>)conn;
        // connection lost, or
        // long long time no response, change state to 'error'
        return [timed isNotReceivedLongTimeAgo:now];
    });
}

// Error -> Default
- (FSMTransition *)errorDefaultTransition {
    return create_transition(kSTConnectionStatePreparing, ^BOOL(STConnectionStateMachine *machine, NSTimeInterval now) {
        id<STConnection> conn = [machine connection];
        if (![conn isAlive]) {
            return NO;
        }
        id<STTimedConnection> timed = (id<STTimedConnection>)conn;
        // connection still alive, and
        // can receive data during this state
        STConnectionState *current = [machine currentState];
        NSTimeInterval enter = [current enterTime];
        return 0 < enter && enter < [timed lastReceivedTime];
    });
}

@end
