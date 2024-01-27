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

import '../net/channel.dart';
import '../nio/address.dart';
import '../nio/channel.dart';
import '../nio/datagram.dart';
import '../nio/network.dart';
import '../nio/selectable.dart';
import '../nio/socket.dart';
import '../type/pair.dart';


abstract interface class SocketReader {

  ///  Read data from socket
  ///
  /// @param dst - buffer to save data
  /// @return data length
  /// @throws IOException on socket error
  Future<int> read(ByteBuffer dst);

  ///  Receive data via socket, and return remote address
  ///
  /// @param dst - buffer to save data
  /// @return remote address
  /// @throws IOException on socket error
  Future<SocketAddress?> receive(ByteBuffer dst);

}

abstract interface class SocketWriter {

  ///  Write data into socket
  ///
  /// @param src - data to send
  /// @return sent length
  /// @throws IOException on socket error
  Future<int> write(ByteBuffer src);

  ///  Send data via socket with remote address
  ///
  /// @param src - data to send
  /// @param target - remote address
  /// @return sent length
  /// @throws IOException on socket error
  Future<int> send(ByteBuffer src, SocketAddress target);

}


abstract class BaseChannel<C extends SelectableChannel>
    extends AddressPairObject implements Channel {
  BaseChannel(super.remoteAddress, super.localAddress, C sock) {
    reader = createReader();
    writer = createWriter();
    _impl = sock;
  }

  SocketReader createReader();
  SocketWriter createWriter();

  // protected
  late final SocketReader reader;
  late final SocketWriter writer;

  // inner socket
  C? _impl;

  // flags
  bool _blocking = false;
  bool _opened = false;
  bool _connected = false;
  bool _bound = false;

  // protected
  void refreshFlags() {
    C? sock = _impl;
    if (sock == null) {
      _blocking = false;
      _opened = false;
      _connected = false;
      _bound = false;
    } else {
      _blocking = sock.isBlocking;
      _opened = !sock.isClosed;
      _connected = _isConnected(sock);
      _bound = _isBound(sock);
    }
  }

  static bool _isConnected(SelectableChannel channel) {
    if (channel is SocketChannel) {
      return channel.isConnected;
    } else if (channel is DatagramChannel) {
      return channel.isConnected;
    }
    return false;
  }
  static bool _isBound(SelectableChannel channel) {
    if (channel is SocketChannel) {
      return channel.isBound;
    } else if (channel is DatagramChannel) {
      return channel.isBound;
    }
    return false;
  }

  C? get socketChannel => _impl;

  void finalize() {
    _removeSocketChannel();
  }
  void _removeSocketChannel() {
    // 1. clear inner channel
    C? old = _impl;
    _impl = null;
    // 2. refresh flags
    refreshFlags();
    // 3. close old channel
    if (old == null || old.isClosed) {} else {
      old.close();
    }
  }

  @override
  SelectableChannel? configureBlocking(bool block) {
    C? sock = socketChannel;
    if (sock == null) {
      assert(false, 'socket closed');
      return null;
    }
    sock.configureBlocking(block);
    _blocking = block;
    return sock;
  }

  @override
  bool get isBlocking => _blocking;

  @override
  bool get isClosed => !_opened;

  @override
  bool get isConnected => _connected;

  @override
  bool get isBound => _bound;

  @override
  bool get isAlive => (!isClosed) && (isConnected || isBound);

  @override
  String toString() {
    Type clazz = runtimeType;
    return '<$clazz remote="$remoteAddress" local="$localAddress">\n\t'
        '$_impl\n</$clazz>';
  }

  @override
  Future<NetworkChannel?> bind(SocketAddress? local) async {
    if (local == null) {
      local = localAddress;
      if (local == null) {
        assert(false, 'local address not set');
        return null;
      }
    }
    C? sock = socketChannel;
    if (sock == null) {
      assert(false, 'socket closed');
      return null;
    }
    NetworkChannel nc = sock as NetworkChannel;
    nc.bind(local);
    localAddress = local;
    _bound = true;
    _opened = true;
    _blocking = sock.isBlocking;
    return nc;
  }

  @override
  Future<NetworkChannel?> connect(SocketAddress? remote) async {
    if (remote == null) {
      remote = remoteAddress;
      if (remote == null) {
        assert(false, 'remote address not set');
        return null;
      }
    }
    C? sock = socketChannel;
    if (sock == null) {
      assert(false, 'socket closed');
      return null;
    } else if (sock is SocketChannel) {
      await sock.connect(remote);
    } else if (sock is DatagramChannel) {
      await sock.connect(remote);
    } else {
      assert(false, 'unknown datagram channel: $sock');
      return null;
    }
    remoteAddress = remote;
    _connected = true;
    _opened = true;
    _blocking = sock.isBlocking;
    return sock as NetworkChannel;
  }

  @override
  Future<ByteChannel?> disconnect() async {
    C? sock = _impl;
    if (sock is DatagramChannel) {
      if (sock.isConnected) {
        try {
          await sock.disconnect();
        } finally {
          refreshFlags();
        }
      }
    } else {
      _removeSocketChannel();
    }
    return sock is ByteChannel ? sock as ByteChannel : null;
  }

  @override
  Future<void> close() async {
    // close inner socket and refresh flags
    _removeSocketChannel();
  }

  @override
  Future<int> read(ByteBuffer dst) async {
    try {
      return await reader.read(dst);
    } catch (e) {
      await close();
      rethrow;
    }
  }

  @override
  Future<int> write(ByteBuffer src) async {
    try {
      return await writer.write(src);
    } catch (e) {
      await close();
      rethrow;
    }
  }

  @override
  Future<SocketAddress?> receive(ByteBuffer dst) async {
    try {
      return await reader.receive(dst);
    } catch (e) {
      await close();
      rethrow;
    }
  }

  @override
  Future<int> send(ByteBuffer src, SocketAddress target) async {
    try {
      return await writer.send(src, target);
    } catch (e) {
      await close();
      rethrow;
    }
  }

}
