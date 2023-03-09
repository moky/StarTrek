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
//  STChannelController.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import "NIOException.h"
#import "NIOByteChannel.h"

#import "STBaseChannel.h"

#import "STChannelController.h"

@interface ChannelChecker : NSObject <STChannelChecker>

@end

@implementation ChannelChecker

- (NIOException *)checkError:(NIOException *)error
                socketChannel:(NIOSelectableChannel *)sock {
    // TODO: check 'E_AGAIN' & TimeoutException
    return error;
}

- (NIOException *)checkData:(NIOByteBuffer *)buf
                     length:(NSInteger)len
              socketChannel:(NIOSelectableChannel *)sock {
    // TODO: check Timeout for received nothing
    if (len == -1) {
        return [[NIOClosedChannelException alloc] init];
    }
    return nil;
}

@end

#pragma mark -

@interface STChannelController ()

@property(nonatomic, weak) STChannel *channel;

@property(nonatomic, strong) id<STChannelChecker> checker;

@end

@implementation STChannelController

- (instancetype)initWithChannel:(STChannel *)channel {
    if (self = [super init]) {
        self.channel = channel;
        self.checker = [self createChecker];
    }
    return self;
}

- (NIOSelectableChannel *)socket {
    return [self.channel socketChannel];
}

- (id<NIOSocketAddress>)remoteAddress {
    return [self.channel remoteAddress];
}

- (id<NIOSocketAddress>)localAddress {
    return [self.channel localAddress];
}

//
//  Checker
//

// Override
- (NIOException *)checkError:(NIOException *)error
               socketChannel:(NIOSelectableChannel *)sock {
    return [self.checker checkError:error socketChannel:sock];
}

// Override
- (NIOException *)checkData:(NIOByteBuffer *)buf
                     length:(NSInteger)len
              socketChannel:(NIOSelectableChannel *)sock {
    return [self.checker checkData:buf length:len socketChannel:sock];
}

- (id<STChannelChecker>)createChecker {
    return [[ChannelChecker alloc] init];
}

@end

#pragma mark -

@implementation STChannelReader

- (NSInteger)tryRead:(NIOByteBuffer *)dst socketChannel:(NIOSelectableChannel *)sock {
    @try {
        return [(id<NIOReadableByteChannel>)sock readWithBuffer:dst];
    } @catch (NIOException *e) {
        e = [self checkError:e socketChannel:sock];
        if (e) {
            // connection lost?
            @throw e;
        }
        // received nothing
        return -1;
    }
}

// Override
- (NSInteger)readWithBuffer:(NIOByteBuffer *)dst {
    NIOSelectableChannel *sock = [self socket];
    NSAssert([sock conformsToProtocol:@protocol(NIOReadableByteChannel)], @"socket error, cannot send data: %@", sock);
    NSInteger cnt = [self tryRead:dst socketChannel:sock];
    // check data
    NIOException *error = [self checkData:dst length:cnt socketChannel:sock];
    if (error) {
        // connection lost!
        @throw error;
    }
    // OK
    return cnt;
    
}

- (id<NIOSocketAddress>)receiveWithBuffer:(NIOByteBuffer *)dst {
    NSAssert(false, @"override me!");
    return nil;
}


- (NIOException *)checkData:(NIOByteBuffer *)buf
                     length:(NSInteger)len
              socketChannel:(NIOSelectableChannel *)sock {
    NSAssert(false, @"override me!");
    return nil;
}

- (NIOException *)checkError:(NIOException *)error
               socketChannel:(NIOSelectableChannel *)sock {
    NSAssert(false, @"override me!");
    return nil;
}

@end

@implementation STChannelWriter

- (NSInteger)tryWrite:(NIOByteBuffer *)src socketChannel:(NIOSelectableChannel *)sock {
    @try {
        return [(id<NIOWritableByteChannel>)sock writeWithBuffer:src];
    } @catch (NIOException *e) {
        e = [self checkError:e socketChannel:sock];
        if (e) {
            // connection lost?
            @throw e;
        }
        // buffer overflow!
        return 0;
    }
}

- (NSInteger)writeWithBuffer:(NIOByteBuffer *)src {
    NIOSelectableChannel *sock = [self socket];
    NSAssert([sock conformsToProtocol:@protocol(NIOWritableByteChannel)], @"socket error, cannot write data: %ld byte(s)", src.position);
    NSInteger sent = 0;
    NSInteger rest = [src position];
    NSInteger cnt;
    while (YES) {  // while ([sock isOpen])
        cnt = [self tryWrite:src socketChannel:sock];
        // check send result
        if (cnt <= 0) {
            // buffer overflow?
            break;
        }
        // something sent, check remaining data
        sent += cnt;
        rest -= cnt;
        if (rest <= 0) {
            // done!
            break;
        //} else {
        //    // remove sent part
        }
    }
    return sent;
}

- (NSInteger)sendWithBuffer:(NIOByteBuffer *)src
              remoteAddress:(id<NIOSocketAddress>)target {
    NSAssert(false, @"override me!");
    return 0;
}


- (NIOException *)checkData:(NIOByteBuffer *)buf
                     length:(NSInteger)len
              socketChannel:(NIOSelectableChannel *)sock {
    NSAssert(false, @"override me!");
    return nil;
}

- (NIOException *)checkError:(NIOException *)error
               socketChannel:(NIOSelectableChannel *)sock {
    NSAssert(false, @"override me!");
    return nil;
}

@end
