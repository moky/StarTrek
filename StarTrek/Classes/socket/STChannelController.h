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
//  STChannelController.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <ObjectKey/ObjectKey.h>

#import <StarTrek/NIOSocketAddress.h>
#import <StarTrek/NIOByteBuffer.h>

#import <StarTrek/STBaseChannel.h>

@protocol STSocketReader <NSObject>

/**
 *  Read data from socket
 *
 * @param dst - buffer to save data
 * @return data length
 * @throws IOException on socket error
 */
- (NSInteger)readWithBuffer:(NIOByteBuffer *)dst throws:(NIOException **)error;

/**
 *  Receive data via socket, and return remote address
 *
 * @param dst - buffer to save data
 * @return remote address
 * @throws IOException on socket error
 */
- (id<NIOSocketAddress>) receiveWithBuffer:(NIOByteBuffer *)dst throws:(NIOException **)error;

@end

@protocol STSocketWriter <NSObject>

/**
 *  Write data into socket
 *
 * @param src - data to send
 * @return sent length
 * @throws IOException on socket error
 */
- (NSInteger)writeWithBuffer:(NIOByteBuffer *)src throws:(NIOException **)error;

/**
 *  Send data via socket with remote address
 *
 * @param src - data to send
 * @param target - remote address
 * @return sent length
 * @throws IOException on socket error
 */
- (NSInteger)sendWithBuffer:(NIOByteBuffer *)src remoteAddress:(id<NIOSocketAddress>)target throws:(NIOException **)error;

@end

@protocol STChannelChecker <NSObject>

// 1. check E_AGAIN
//    the socket will raise 'Resource temporarily unavailable'
//    when received nothing in non-blocking mode,
//    or buffer overflow while sending too many bytes,
//    here we should ignore this exception.
// 2. check timeout
//    in blocking mode, the socket will wait until send/received data,
//    but if timeout was set, it will raise 'timeout' error on timeout,
//    here we should ignore this exception
- (NIOException *)checkError:(NIOException *)error socketChannel:(NIOSelectableChannel *)sock;

// 1. check timeout
//    in blocking mode, the socket will wait until received something,
//    but if timeout was set, it will return nothing too, it's normal;
//    otherwise, we know the connection was lost.
- (NIOException *)checkData:(NIOByteBuffer *)buf length:(NSInteger)len socketChannel:(NIOSelectableChannel *)sock;

@end

#pragma mark -

/**
 *  Socket Channel Controller
 *  ~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 *  Reader, Writer, ErrorChecker
 */
@interface STChannelController<__covariant C : NIOSelectableChannel *> : NSObject <STChannelChecker>

@property(nonatomic, readonly, weak) STChannel *channel;
@property(nonatomic, readonly) C socket;

@property(nonatomic, readonly) id<NIOSocketAddress> remoteAddress;
@property(nonatomic, readonly) id<NIOSocketAddress> localAddress;

- (instancetype)initWithChannel:(STChannel *)channel;

// protected
- (id<STChannelChecker>)createChecker;

@end

#pragma mark -

@interface STChannelReader<__covariant C : NIOSelectableChannel *> : STChannelController <STSocketReader>

// protected
- (NSInteger)tryRead:(NIOByteBuffer *)dst socketChannel:(C)sock throws:(NIOException **)error;

@end

@interface STChannelWriter<__covariant C : NIOSelectableChannel *> : STChannelController <STSocketWriter>

// protected
- (NSInteger)tryWrite:(NIOByteBuffer *)src socketChannel:(C)sock throws:(NIOException **)error;

@end
