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
//  STBaseChannel.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <StarTrek/STAddressPairObject.h>
#import <StarTrek/STChannel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol STSocketReader;
@protocol STSocketWriter;

@interface STChannel : STAddressPairObject <STChannel>

// socket reader/writer
@property(nonatomic, readonly) id<STSocketReader> reader;
@property(nonatomic, readonly) id<STSocketWriter> writer;

@property(nonatomic, readonly) NIOSelectableChannel *socketChannel;

/**
 *  Create channel
 *
 * @param remote      - remote address
 * @param local       - local address
 */
- (instancetype)initWithSocket:(NIOSelectableChannel *)sock
                 remoteAddress:(nullable id<NIOSocketAddress>)remote
                  localAddress:(nullable id<NIOSocketAddress>)local;

// create socket reader/writer
- (id<STSocketReader>)createReader;
- (id<STSocketWriter>)createWriter;

// refresh flags with inner socket
- (void)refreshFlags;

@end

NS_ASSUME_NONNULL_END
