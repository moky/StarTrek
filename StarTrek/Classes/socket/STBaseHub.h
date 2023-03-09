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
//  STBaseHub.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <StarTrek/STAddressPairMap.h>
#import <StarTrek/STConnection.h>
#import <StarTrek/STHub.h>

NS_ASSUME_NONNULL_BEGIN

@interface STHub : NSObject <STHub>

// delegate for handling connection events
@property(nonatomic, weak, readonly) id<STConnectionDelegate> delegate;

- (instancetype)initWithConnectionDelegate:(id<STConnectionDelegate>)delegate
NS_DESIGNATED_INITIALIZER;

// protected
- (STAddressPairMap<id<STConnection>> *)createConnectionPool;

@end

@interface STHub (Channel)  // protected

/**
 *  Get all channels
 *
 * @return copy of channels
 */
@property(nonatomic, copy, readonly) NSSet<id<STChannel>> *allChannels;

/**
 *  Remove socket channel
 *
 * @param remote  - remote address
 * @param local   - local address
 * @param channel - socket channel
 */
- (void)removeChannel:(id<STChannel>)channel
        remoteAddress:(id<NIOSocketAddress>)remote
         localAddress:(id<NIOSocketAddress>)local;

@end

@interface STHub (Connection)  // protected

@property(nonatomic, copy, readonly) NSSet<id<STConnection>> *allConnections;

/**
 *  Create connection with sock channel & addresses
 *
 * @param channel - socket channel
 * @param remote  - remote address
 * @param local   - local address
 * @return null on channel not exists
 */
- (id<STConnection>)createConnectionWithChannel:(id<STChannel>)channel
                                  remoteAddress:(id<NIOSocketAddress>)remote
                                   localAddress:(id<NIOSocketAddress>)local;

// protected
- (id<STConnection>)connectionWithRemoteAddress:(id<NIOSocketAddress>)remote
                                   localAddress:(id<NIOSocketAddress>)local;

// protected
- (void)setConnection:(id<STConnection>)conn
        remoteAddress:(id<NIOSocketAddress>)remote
         localAddress:(id<NIOSocketAddress>)local;

// protected
- (void)removeConnection:(id<STConnection>)conn
           remoteAddress:(id<NIOSocketAddress>)remote
            localAddress:(id<NIOSocketAddress>)local;

@end

@interface STHub (Processor)

// protected
- (BOOL)driveChannel:(id<STChannel>)channel;

// protected
- (NSInteger)driveChannels:(NSSet<id<STChannel>> *)channels;

// protected
- (void)cleanupChannels:(NSSet<id<STChannel>> *)channels;

// protected
- (void)driveConnections:(NSSet<id<STConnection>> *)connections;

// protected
- (void)cleanupConnections:(NSSet<id<STConnection>> *)connections;

@end

NS_ASSUME_NONNULL_END
