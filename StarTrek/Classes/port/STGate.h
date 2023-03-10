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
//  STGate.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import <FiniteStateMachine/FiniteStateMachine.h>

#import <StarTrek/NIOSocketAddress.h>
#import <StarTrek/STShip.h>

NS_ASSUME_NONNULL_BEGIN

/*
 *  Architecture:
 *
 *              Docker Delegate   Docker Delegate   Docker Delegate
 *                     ^                 ^               ^
 *                     :                 :               :
 *        ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~ ~:~ ~ ~ ~ ~ ~ ~
 *                     :                 :               :
 *          +==========V=================V===============V==========+
 *          ||         :                 :               :         ||
 *          ||         :      Gate       :               :         ||
 *          ||         :                 :               :         ||
 *          ||  +------------+    +------------+   +------------+  ||
 *          ||  |   docker   |    |   docker   |   |   docker   |  ||
 *          +===+------------+====+------------+===+------------+===+
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
 *  Star Gate
 *  ~~~~~~~~~
 */
@protocol STGate <FSMProcessor>

/**
 *  Pack data to an outgo ship (with normal priority), and
 *  append to the waiting queue of docker for remote address
 *
 * @param payload - data to be sent
 * @param remote  - remote address
 * @param local   - local address
 * @return false on error
 */
- (BOOL)sendData:(NSData *)payload remoteAddress:(id<NIOSocketAddress>)remote localAddress:(nullable id<NIOSocketAddress>)local;

/**
 *  Append outgo ship (carrying data package, with priority)
 *  to the waiting queue of docker for remote address
 *
 * @param outgo  - departure ship
 * @param remote - remote address
 * @param local  - local address
 * @return false on error
 */
- (BOOL)sendShip:(id<STDeparture>)outgo remoteAddress:(id<NIOSocketAddress>)remote localAddress:(nullable id<NIOSocketAddress>)local;

@end

NS_ASSUME_NONNULL_END
