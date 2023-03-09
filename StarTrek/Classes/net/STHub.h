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
//  STHub.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import <StarTrek/NIOSocketAddress.h>
#import <StarTrek/STChannel.h>
#import <StarTrek/STConnection.h>

NS_ASSUME_NONNULL_BEGIN

/*
 *  Architecture:
 *
 *                 Connection        Connection      Connection
 *                 Delegate          Delegate        Delegate
 *                     ^                 ^               ^
 *                     :                 :               :
 *        ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~
 *                     :                 :               :
 *          +===+------V-----+====+------V-----+===+-----V------+===+
 *          ||  | connection |    | connection |   | connection |  ||
 *          ||  +------------+    +------------+   +------------+  ||
 *          ||          :                :               :         ||
 *          ||          :      HUB       :...............:         ||
 *          ||          :                        :                 ||
 *          ||     +-----------+           +-----------+           ||
 *          ||     |  channel  |           |  channel  |           ||
 *          +======+-----------+===========+-----------+============+
 *                 |  socket   |           |  socket   |
 *                 +-----^-----+           +-----^-----+
 *                       : (TCP)                 : (UDP)
 *                       :               ........:........
 *                       :               :               :
 *        ~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~
 *                       :               :               :
 *                       V               V               V
 *                  Remote Peer     Remote Peer     Remote Peer
 */

/**
 *  Connections & Channels Container
 */
@protocol STHub <FSMProcessor>

/**
 *  Get opened channel with direction (remote, local)
 *
 * @param remote - remote address
 * @param local  - local address
 * @return null on socket closed
 */
- (nullable id<STChannel>)openChannelForRemoteAddress:(nullable id<NIOSocketAddress>)remote
                                         localAddress:(nullable id<NIOSocketAddress>)local;

/**
 *  Get connection with direction (remote, local)
 *
 * @param remote - remote address
 * @param local  - local address
 * @return null on connection not found
 */
- (nullable id<STConnection>)connectToRemoteAddress:(id<NIOSocketAddress>)remote
                                       localAddress:(nullable id<NIOSocketAddress>)local;

@end

NS_ASSUME_NONNULL_END
