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
//  STChannel.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import <StarTrek/NIOByteChannel.h>
#import <StarTrek/NIOSelectableChannel.h>
#import <StarTrek/NIONetworkChannel.h>

#import <StarTrek/NIOSocketAddress.h>

NS_ASSUME_NONNULL_BEGIN

@protocol STChannel <NIOByteChannel>

//@property(nonatomic, readonly, getter=isOpen) BOOL opened;
@property(nonatomic, readonly, getter=isBound) BOOL bound;
@property(nonatomic, readonly, getter=isAlive) BOOL alive;  // isOpen() && (isConnected() || isBound())

//- (void)close;

/*================================================*\
|*          Readable Byte Channel                 *|
\*================================================*/

//- (NSInteger)readWithBuffer:(NIOByteBuffer *)dst

/*================================================*\
|*          Writable Byte Channel                 *|
\*================================================*/

//- (NSInteger)writeWithBuffer:(NIOByteBuffer *)src

/*================================================*\
|*          Selectable Channel                    *|
\*================================================*/

- (nullable NIOSelectableChannel *)configureBlocking:(BOOL)blocking;

@property(nonatomic, readonly, getter=isBlocking) BOOL blocking;

/*================================================*\
|*          Network Channel                       *|
\*================================================*/

- (nullable id<NIONetworkChannel>)bindLocalAddress:(id<NIOSocketAddress>)local;

@property(nonatomic, readonly, nullable) id<NIOSocketAddress> localAddress;

/*================================================*\
|*          Socket/Datagram Channel               *|
\*================================================*/

@property(nonatomic, readonly, getter=isConnected) BOOL connected;

- (nullable id<NIONetworkChannel>)connectRemoteAddress:(id<NIOSocketAddress>)remote;

@property(nonatomic, readonly, nullable) id<NIOSocketAddress> remoteAddress;

/*================================================*\
|*          Datagram Channel                      *|
\*================================================*/

- (nullable id<NIOByteChannel>)disconnect;

- (nullable id<NIOSocketAddress>)receiveWithBuffer:(NIOByteBuffer *)dst;

- (NSInteger)sendWithBuffer:(NIOByteBuffer *)src remoteAddress:(id<NIOSocketAddress>)remote;

@end

NS_ASSUME_NONNULL_END
