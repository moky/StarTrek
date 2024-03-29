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
//  STBaseConnection.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <StarTrek/STAddressPairObject.h>
#import <StarTrek/STChannel.h>
#import <StarTrek/STConnection.h>
#import <StarTrek/STConnectionState.h>
#import <StarTrek/STStateMachine.h>
#import <StarTrek/STHub.h>

@interface STConnection : STAddressPairObject <STConnection, STTimedConnection, STConnectionStateDelegate>

@property(nonatomic, weak) id<STConnectionDelegate> delegate;  // delegate for handling connection events
@property(nonatomic, weak) id<STChannel> channel;  // socket channel

- (instancetype)initWithChannel:(id<STChannel>)channel
                  remoteAddress:(id<NIOSocketAddress>)remote
                   localAddress:(id<NIOSocketAddress>)local;

// protected
- (STConnectionStateMachine *)stateMachine;
// protected
- (STConnectionStateMachine *)createStateMachine;

- (void)start;
- (void)stop;

// protected
- (NSInteger)sendBuffer:(NIOByteBuffer *)src remoteAddress:(id<NIOSocketAddress>)destination
                 throws:(NIOException **)error;

@end

/**
 * Active connection for client
 */
@interface STActiveConnection : STConnection

- (instancetype)initWithHub:(id<STHub>)hub
                    channel:(id<STChannel>)channel
              remoteAddress:(id<NIOSocketAddress>)remote
               localAddress:(id<NIOSocketAddress>)local;

@end
