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

import 'package:object_key/object_key.dart';

import '../nio/address.dart';
import '../nio/channel.dart';
import '../nio/network.dart';
import '../nio/selectable.dart';


abstract interface class Channel implements ByteChannel {

  // bool get isClosed;  // !isOpen()

  bool get isBound;

  bool get isAlive;  // isOpen && (isConnected || isBound)

  // Future<void> close();

  /*================================================*\
  |*          Readable Byte Channel                 *|
  \*================================================*/

  // Future<Uint8List?> read(int maxLen);

  /*================================================*\
  |*          Writable Byte Channel                 *|
  \*================================================*/

  // Future<int> write(Uint8List src);

  /*================================================*\
  |*          Selectable Channel                    *|
  \*================================================*/

  SelectableChannel? configureBlocking(bool block);

  bool get isBlocking;

  /*================================================*\
  |*          Network Channel                       *|
  \*================================================*/

  Future<NetworkChannel?> bind(SocketAddress? local);

  SocketAddress? get localAddress;

  /*================================================*\
  |*          Socket/Datagram Channel               *|
  \*================================================*/

  bool get isConnected;

  Future<NetworkChannel?> connect(SocketAddress? remote);

  SocketAddress? get remoteAddress;

  /*================================================*\
  |*          Datagram Channel                      *|
  \*================================================*/

  Future<ByteChannel?> disconnect();

  ///  Receives a data package via this channel.
  Future<Pair<Uint8List?, SocketAddress?>> receive(int maxLen);

  ///  Sends a data package via this channel.
  Future<int> send(Uint8List src, SocketAddress target);

}
