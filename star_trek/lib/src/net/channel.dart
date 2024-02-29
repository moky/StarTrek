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
import 'dart:io';
import 'dart:typed_data';

import 'package:object_key/object_key.dart';

import '../nio/address.dart';
import '../nio/channel.dart';
import '../nio/datagram.dart';
import '../nio/network.dart';
import '../nio/selectable.dart';
import '../nio/socket.dart';


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

  Future<NetworkChannel?> bind(SocketAddress local);

  SocketAddress? get localAddress;

  /*================================================*\
  |*          Socket/Datagram Channel               *|
  \*================================================*/

  bool get isConnected;

  Future<NetworkChannel?> connect(SocketAddress remote);

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


///
/// Socket Channels
///


SocketAddress? socketGetLocalAddress(SelectableChannel sock) {
  if (sock is SocketChannel) {
    // TCP
    return sock.localAddress;
  } else if (sock is DatagramChannel) {
    // UDP
    return sock.localAddress;
  } else {
    assert(false, 'unknown socket channel: $sock');
    return null;
  }
}

SocketAddress? socketGetRemoteAddress(SelectableChannel sock) {
  if (sock is SocketChannel) {
    // TCP
    return sock.remoteAddress;
  } else if (sock is DatagramChannel) {
    // UDP
    return sock.remoteAddress;
  } else {
    assert(false, 'unknown socket channel: $sock');
    return null;
  }
}


bool socketIsBlocking(SelectableChannel sock) {
  return sock.isBlocking;
}

bool socketIsConnected(SelectableChannel sock) {
  if (sock is SocketChannel) {
    // TCP
    return sock.isConnected;
  } else if (sock is DatagramChannel) {
    // UDP
    return sock.isConnected;
  } else {
    assert(false, 'unknown socket channel: $sock');
    return false;
  }
}

bool socketIsBound(SelectableChannel sock) {
  if (sock is SocketChannel) {
    // TCP
    return sock.isBound;
  } else if (sock is DatagramChannel) {
    // UDP
    return sock.isBound;
  } else {
    assert(false, 'unknown socket channel: $sock');
    return false;
  }
}

bool socketIsClosed(SelectableChannel sock) {
  return sock.isClosed;
}


/// Bind to local address
Future<bool> socketBind(NetworkChannel sock, SocketAddress local) async {
  try {
    await sock.bind(local);
    return sock is SelectableChannel && socketIsBound(sock as SelectableChannel);
  } on IOException catch (e) {
    print('[Socket] cannot bind socket: $local, $sock, $e');
    return false;
  }
}

/// Connect to remote address
Future<bool> socketConnect(NetworkChannel sock, SocketAddress remote) async {
  try {
    if (sock is SocketChannel) {
      // TCP
      var tcp = sock as SocketChannel;
      return await tcp.connect(remote);
    } else if (sock is DatagramChannel) {
      // UDP
      var udp = sock as DatagramChannel;
      await udp.connect(remote);
      return udp.isConnected;
    } else {
      assert(false, 'unknown socket channel: $sock');
      return false;
    }
  } on IOException catch (e) {
    print('[Socket] cannot connect socket: $remote, $sock, $e');
    return false;
  }
}

Future<bool> socketDisconnect(SelectableChannel sock) async {
  try {
    if (sock is SocketChannel) {
      // TCP
      await sock.close();
      return sock.isClosed;
    } else if (sock is DatagramChannel) {
      // UDP
      if (!sock.isConnected) {
        // not connect yet
        return true;
      }
      await sock.disconnect();
      return !sock.isConnected;
    } else {
      assert(false, 'unknown socket channel: $sock');
      return false;
    }
  } on IOException catch (e) {
    print('[Socket] cannot disconnect socket: $sock, $e');
    return false;
  }
}

/// safely close socket
Future<bool> socketShutdown(SelectableChannel sock) async {
  try {
    if (sock.isClosed) {
      // already closed
      return true;
    } else {
      await sock.close();
      return sock.isClosed;
    }
  } on IOException catch (e) {
    print('[Socket] cannot close socket: $sock, $e');
    return false;
  }
}
