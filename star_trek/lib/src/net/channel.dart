/* license: https://mit-license.org
 *
 *  Star Trek: Interstellar Transport
 *
 *                               Written in 2024 by Moky <albert.moky@gmail.com>
 *
 * =============================================================================
 * The MIT License (MIT)
 *
 * Copyright (c) 2024 Albert Moky
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * =============================================================================
 */
import 'dart:typed_data';

import '../type/address.dart';

abstract interface class Channel {

  bool get isClosed;  // !isOpen()

  bool get isBound;

  bool get isAlive;  // isOpen && (isConnected || isBound)

  ///  Close the channel
  Future<void> close();

  /*================================================*\
  |*          Readable Byte Channel                 *|
  \*================================================*/

  ///  Reads a sequence of bytes from this channel into the given buffer.
  Future<int> read(ByteBuffer dst);

  /*================================================*\
  |*          Writable Byte Channel                 *|
  \*================================================*/

  ///  Writes a sequence of bytes to this channel from the given buffer.
  Future<int> write(ByteBuffer src);

  /*================================================*\
  |*          Selectable Channel                    *|
  \*================================================*/

  ///  Adjusts this channel's blocking mode.
  configureBlocking(bool block);

  bool get isBlocking;

  /*================================================*\
  |*          Network Channel                       *|
  \*================================================*/

  ///  Binds the channel's socket to a local address (host, port).
  Future<dynamic> bind(SocketAddress local);

  SocketAddress? get localAddress;

  /*================================================*\
  |*          Socket/Datagram Channel               *|
  \*================================================*/

  bool get isConnected;

  ///  Connects this channel's socket.
  Future<dynamic> connect(SocketAddress remote);

  SocketAddress? get remoteAddress;

  /*================================================*\
  |*          Datagram Channel                      *|
  \*================================================*/

  ///  Disconnects this channel's socket.
  Future<dynamic> disconnect();

  ///  Receives a data package via this channel.
  Future<SocketAddress?> receive(ByteBuffer dst);

  ///  Sends a data package via this channel.
  Future<int> send(ByteBuffer src, SocketAddress target);

}
