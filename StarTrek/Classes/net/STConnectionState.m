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
//  STConnectionState.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import "STStateMachine.h"

#import "STConnectionState.h"

NSString *kSTConnectionStateDefault     = @"default";
NSString *kSTConnectionStatePreparing   = @"preparing";
NSString *kSTConnectionStateReady       = @"ready";
NSString *kSTConnectionStateMaintaining = @"maintaining";
NSString *kSTConnectionStateExpired     = @"expired";
NSString *kSTConnectionStateError       = @"error";

@interface STConnectionState () {
    
    NSTimeInterval _enterTime;
}

@end

@implementation STConnectionState

/* designated initializer */
- (instancetype)initWithName:(NSString *)name
                    capacity:(NSUInteger)countOfTransitions {
    if (self = [super initWithName:name capacity:countOfTransitions]) {
        _enterTime = 0;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[STConnectionState class]]) {
        if (self == object) {
            return YES;
        }
        STConnectionState *state = (STConnectionState *)object;
        object = [state name];
    }
    return [self.name isEqual:object];
}

- (NSString *)description {
    return self.name;
}

- (NSString *)debugDescription {
    return self.name;
}

- (NSTimeInterval)enterTime {
    return _enterTime;
}

//
//  FSM Delegate
//

// Override
- (void)onEnter:(id<FSMState>)previous machine:(id<FSMContext>)ctx time:(NSTimeInterval)now {
    _enterTime = now;
}

// Override
- (void)onExit:(id<FSMState>)next machine:(id<FSMContext>)ctx time:(NSTimeInterval)now {
    _enterTime = 0;
}

// Override
- (void)onPaused:(id<FSMContext>)ctx time:(NSTimeInterval)now {
    //
}

// Override
- (void)onResume:(id<FSMContext>)ctx time:(NSTimeInterval)now {
    //
}

@end

@interface STConnectionStateBuilder () {
    
    STConnectionStateTransitionBuilder *_stb;
}

@end

@implementation STConnectionStateBuilder

- (instancetype)initWithTransitionBuilder:(STConnectionStateTransitionBuilder *)builder {
    if (self = [super init]) {
        _stb = builder;
    }
    return self;
}

// Connection not started yet
- (STConnectionState *)defaultState {
    STConnectionState *state;
    state = [[STConnectionState alloc] initWithName:kSTConnectionStateDefault
                                           capacity:1];
    // Default -> Preparing
    [state addTransition:_stb.defaultPreparingTransition];
    return state;
}

// Connection started, preparing to connect/bind
- (STConnectionState *)preparingState {
    STConnectionState *state;
    state = [[STConnectionState alloc] initWithName:kSTConnectionStatePreparing
                                           capacity:2];
    // Preparing -> Ready
    [state addTransition:_stb.preparingReadyTransition];
    // Preparing -> Default
    [state addTransition:_stb.preparingDefaultTransition];
    return state;
}

// Normal state of connection
- (STConnectionState *)readyState {
    STConnectionState *state;
    state = [[STConnectionState alloc] initWithName:kSTConnectionStateReady
                                           capacity:2];
    // Ready -> Expired
    [state addTransition:_stb.readyExpiredTransition];
    // Ready -> Error
    [state addTransition:_stb.readyErrorTransition];
    return state;
}

// Long time no response, need maintaining
- (STConnectionState *)expiredState {
    STConnectionState *state;
    state = [[STConnectionState alloc] initWithName:kSTConnectionStateExpired
                                           capacity:2];
    // Expired -> Maintaining
    [state addTransition:_stb.expiredMaintainingTransition];
    // Expired -> Error
    [state addTransition:_stb.expiredErrorTransition];
    return state;
}

// Heartbeat sent, waiting response
- (STConnectionState *)maintainingState {
    STConnectionState *state;
    state = [[STConnectionState alloc] initWithName:kSTConnectionStateMaintaining
                                           capacity:3];
    // Maintaining -> Ready
    [state addTransition:_stb.maintainingReadyTransition];
    // Maintaining -> Expired
    [state addTransition:_stb.maintainingExpiredTransition];
    // Maintaining -> Error
    [state addTransition:_stb.maintainingErrorTransition];
    return state;
}

// Connection lost
- (STConnectionState *)errorState {
    STConnectionState *state;
    state = [[STConnectionState alloc] initWithName:kSTConnectionStateError
                                           capacity:1];
    // Error -> Default
    [state addTransition:_stb.errorDefaultTransition];
    return state;
}

@end
