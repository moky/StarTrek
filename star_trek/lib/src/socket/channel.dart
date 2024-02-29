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

import '../net/channel.dart';
import '../nio/address.dart';
import '../nio/channel.dart';
import '../nio/network.dart';
import '../nio/selectable.dart';
import '../type/pair.dart';


abstract interface class SocketReader {

  ///  Read data from socket
  Future<Uint8List?> read(int maxLen);

  ///  Receive data via socket, and return remote address
  Future<Pair<Uint8List?, SocketAddress?>> receive(int maxLen);

}

abstract interface class SocketWriter {

  ///  Write data into socket
  ///
  /// @param src - data to send
  /// @return sent length
  Future<int> write(Uint8List src);

  ///  Send data via socket with remote address
  ///
  /// @param src - data to send
  /// @param target - remote address
  /// @return sent length
  Future<int> send(Uint8List src, SocketAddress target);

}


abstract class BaseChannel<C extends SelectableChannel>
    extends AddressPairObject implements Channel {
  BaseChannel(C sock, {super.remote, super.local}) {
    reader = createReader();
    writer = createWriter();
    _impl = sock;
    refreshFlags();
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
  // bool _closed = false;
  bool _connected = false;
  bool _bound = false;

  // protected
  void refreshFlags() {
    C? sock = _impl;
    if (sock == null) {
      _blocking = false;
      // _closed = false;
      _connected = false;
      _bound = false;
    } else {
      _blocking = socketIsBlocking(sock);
      // _closed = socketIsClosed(sock);
      _connected = socketIsConnected(sock);
      _bound = socketIsBound(sock);
    }
  }

  C? get socket => getSocket();
  // protected
  C? getSocket() => _impl;
  // protected
  Future<void> setSocket(C? sock) async {
    // 1. clear inner channel
    C? old = _impl;
    _impl = null;
    // 2. refresh flags
    refreshFlags();
    // 3. close old channel
    if (old == null || identical(old, sock)) {} else {
      await closeSocket(old);
    }
  }

  // protected
  Future<void> closeSocket(C sock) async => await socketShutdown(sock);

  // protected
  void finalize() {
    // make sure the relative socket is removed
    setSocket(null);
  }

  @override
  SelectableChannel? configureBlocking(bool block) {
    C? sock = socket;
    if (sock == null) {
      throw SocketException('socket closed');
    } else {
      sock.configureBlocking(block);
    }
    _blocking = block;
    return sock;
  }

  @override
  bool get isBlocking => _blocking;

  @override
  bool get isClosed {
    // return _closed;
    C? sock = getSocket();
    return sock == null || socketIsClosed(sock);
  }

  @override
  bool get isConnected => _connected;

  @override
  bool get isBound => _bound;

  @override
  bool get isAlive => (!isClosed) && (isConnected || isBound);

  // @override
  // SocketAddress? get remoteAddress {
  //   SocketAddress? address = super.remoteAddress;
  //   if (address == null) {
  //     C? sock = getSocket();
  //     if (sock != null) {
  //       address = socketGetRemoteAddress(sock);
  //     }
  //   }
  //   return address;
  // }
  //
  // @override
  // SocketAddress? get localAddress {
  //   SocketAddress? address = super.localAddress;
  //   if (address == null) {
  //     C? sock = getSocket();
  //     if (sock != null) {
  //       address = socketGetLocalAddress(sock);
  //     }
  //   }
  //   return address;
  // }

  @override
  String toString() {
    Type clazz = runtimeType;
    return '<$clazz remote="$remoteAddress" local="$localAddress">\n\t'
        '$_impl\n</$clazz>';
  }

  @override
  Future<NetworkChannel?> bind(SocketAddress local) async {
    // if (local == null) {
    //   local = localAddress;
    //   if (local == null) {
    //     assert(false, 'local address not set');
    //     return null;
    //   }
    // }
    C? sock = socket;
    if (sock == null) {
      throw SocketException('socket closed');
    }
    // _closed = false;
    _blocking = socketIsBlocking(sock);
    NetworkChannel nc = sock as NetworkChannel;
    bool ok = await socketBind(nc, local);
    assert(ok, 'failed to bind socket: $local');
    localAddress = local;
    _bound = true;
    return nc;
  }

  @override
  Future<NetworkChannel?> connect(SocketAddress remote) async {
    // if (remote == null) {
    //   remote = remoteAddress;
    //   if (remote == null) {
    //     assert(false, 'remote address not set');
    //     return null;
    //   }
    // }
    C? sock = socket;
    if (sock == null) {
      throw SocketException('socket closed');
    }
    // _closed = true;
    _blocking = socketIsBlocking(sock);
    NetworkChannel nc = sock as NetworkChannel;
    bool ok = await socketConnect(nc, remote);
    assert(ok, 'failed to connect socket: $remote');
    remoteAddress = remote;
    _connected = true;
    return nc;
  }

  @override
  Future<ByteChannel?> disconnect() async {
    // 1. clear inner socket
    C? sock = _impl;
    _impl = null;
    // 2. refresh flags
    refreshFlags();
    // 3. close connected socket
    if (sock != null && socketIsConnected(sock)) {
      bool ok = await socketDisconnect(sock);
      assert(ok, 'failed to disconnect socket: $sock');
    }
    return sock is ByteChannel ? sock as ByteChannel : null;
  }

  @override
  Future<void> close() async {
    // close inner socket and refresh flags
    await setSocket(null);
  }

  @override
  Future<Uint8List?> read(int maxLen) async {
    try {
      return await reader.read(maxLen);
    } on IOException {
      await close();
      rethrow;
    }
  }

  @override
  Future<int> write(Uint8List src) async {
    try {
      return await writer.write(src);
    } on IOException {
      await close();
      rethrow;
    }
  }

  @override
  Future<Pair<Uint8List?, SocketAddress?>> receive(int maxLen) async {
    try {
      return await reader.receive(maxLen);
    } on IOException {
      await close();
      rethrow;
    }
  }

  @override
  Future<int> send(Uint8List src, SocketAddress target) async {
    try {
      return await writer.send(src, target);
    } on IOException {
      await close();
      rethrow;
    }
  }

}
