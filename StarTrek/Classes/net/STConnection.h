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
//  STConnection.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import <FiniteStateMachine/FiniteStateMachine.h>

#import <StarTrek/NIOException.h>
#import <StarTrek/NIOSocketAddress.h>

NS_ASSUME_NONNULL_BEGIN

@class STConnectionState;

@protocol STConnection <SMTicker>

//
//  Flags
//
@property(nonatomic, readonly, getter=isOpen) BOOL opened;  // not closed
@property(nonatomic, readonly, getter=isBound) BOOL bound;
@property(nonatomic, readonly, getter=isConnected) BOOL connected;

@property(nonatomic, readonly, getter=isAlive) BOOL alive;  // isOpen() && (isConnected() || isBound())

@property(nonatomic, readonly, nullable) id<NIOSocketAddress> localAddress;
@property(nonatomic, readonly, nullable) id<NIOSocketAddress> remoteAddress;

/**
 *  Get state
 *
 * @return connection state
 */
@property(nonatomic, readonly, nullable) STConnectionState *state;

/**
 *  Send data
 *
 * @param data        - outgo data package
 * @return count of bytes sent, probably zero when it's non-blocking mode
 */
- (NSInteger)sendData:(NSData *)data;

/**
 *  Process received data
 *
 * @param data   - received data
 */
- (void)onReceivedData:(NSData *)data;

/**
 *  Close the connection
 */
- (void)close;

@end

@protocol STTimedConnection <NSObject>

@property(nonatomic, readonly) NSTimeInterval lastSentTime;
@property(nonatomic, readonly) NSTimeInterval lastReceivedTime;

- (BOOL)isSentRecently:(NSTimeInterval)now;
- (BOOL)isReceivedRecently:(NSTimeInterval)now;
- (BOOL)isNotReceivedLongTimeAgo:(NSTimeInterval)now;

@end

@protocol STConnectionDelegate <NSObject>

/**
 *  Called when connection state is changed
 *
 * @param previous   - old state
 * @param current    - new state
 * @param connection - current connection
 */
- (void)connection:(id<STConnection>)connection changedState:(nullable STConnectionState *)previous toState:(nullable STConnectionState *)current;

/**
 *  Called when connection received data
 *
 * @param data        - received data package
 * @param connection  - current connection
 */
- (void)connection:(id<STConnection>)connection receivedData:(NSData *)data;

/**
 *  Called after data sent via the connection
 *
 * @param sent        - length of sent bytes
 * @param data        - outgo data package
 * @param connection  - current connection
 */
- (void)connection:(id<STConnection>)connection sentData:(NSData *)data withLength:(NSInteger)sent;

/**
 *  Called when failed to send data via the connection
 *
 * @param error       - error message
 * @param data        - outgo data package
 * @param connection  - current connection
 */
- (void)connection:(id<STConnection>)connection failedToSendData:(NSData *)data error:(NIOError *)error;

/**
 *  Called when connection (receiving) error
 *
 * @param error       - error message
 * @param connection  - current connection
 */
- (void)connection:(id<STConnection>)connection error:(NIOError *)error;

@end

NS_ASSUME_NONNULL_END
