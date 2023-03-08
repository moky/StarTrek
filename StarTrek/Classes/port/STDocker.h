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
//  STDocker.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import <FiniteStateMachine/FiniteStateMachine.h>

#import <StarTrek/NIOSocketAddress.h>
#import <StarTrek/NIOException.h>

#import <StarTrek/STConnectionState.h>
#import <StarTrek/STShip.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(UInt8, STDockerStatus) {
    STDockerStatusError     = -1,
    STDockerStatusInit      =  0,
    STDockerStatusPreparing =  1,
    STDockerStatusReady     =  2,
};

#ifdef __cplusplus
extern "C" {
#endif

STDockerStatus STDockerStatusFromConnectionState(STConnectionState *state);

#ifdef __cplusplus
} /* end of extern "C" */
#endif

/**
 *  Star Worker
 *  ~~~~~~~~~~~
 *
 *  Processor for Star Ships
 */
@protocol STDocker <FSMProcessor>

@property(nonatomic, readonly, getter=isOpen) BOOL opened;  // connection.isOpen()
@property(nonatomic, readonly, getter=isAlive) BOOL alive;  // connection.isAlive()

@property(nonatomic, readonly) STDockerStatus status;

@property(nonatomic, readonly) id<NIOSocketAddress> remoteAddress;
@property(nonatomic, readonly) id<NIOSocketAddress> localAddress;

/**
 *  Pack data to an outgo ship (with normal priority), and
 *  append to the waiting queue for sending out
 *
 * @param payload  - data to be sent
 * @return false on error
 */
- (BOOL)sendData:(NSData *)payload;

/**
 *  Append outgo ship (carrying data package, with priority)
 *  to the waiting queue for sending out
 *
 * @param ship - outgo ship carrying data package/fragment
 * @return false on duplicated
 */
- (BOOL)sendShip:(id<STDeparture>)ship;

/**
 *  Called when received data
 *
 * @param data   - received data package
 */
- (void)processReceivedData:(NSData *)data;

/**
 *  Send 'PING' for keeping connection alive
 */
- (void)heartbeat;

/**
 *  Clear all expired tasks
 */
- (void)purge;

/**
 *  Close connection for this docker
 */
- (void)close;

@end

@protocol STDockerDelegate <NSObject>

/**
 *  Callback when new package received
 *
 * @param arrival     - income data package container
 * @param worker      - connection docker
 */
- (void)docker:(id<STDocker>)worker receivedShip:(id<STArrival>)arrival;

/**
 *  Callback when package sent
 *
 * @param departure   - outgo data package container
 * @param worker      - connection docker
 */
- (void)docker:(id<STDocker>)worker sentShip:(id<STDeparture>)departure;

/**
 *  Callback when failed to send package
 *
 * @param error       - error message
 * @param departure   - outgo data package container
 * @param worker      - connection docker
 */
- (void)docker:(id<STDocker>)worker failedToSendShip:(id<STDeparture>)departure error:(NIOError *)error;

/**
 *  Callback when connection error
 *
 * @param error       - error message
 * @param departure   - outgo data package container
 * @param worker      - connection docker
 */
- (void)docker:(id<STDocker>)worker sendingShip:(id<STDeparture>)departure error:(NIOError *)error;

/**
 *  Callback when connection status changed
 *
 * @param previous    - old status
 * @param current     - new status
 * @param worker      - connection docker
 */
- (void)docker:(id<STDocker>)worker changedStatus:(STDockerStatus)previous toStatus:(STDockerStatus)current;

@end

NS_ASSUME_NONNULL_END
