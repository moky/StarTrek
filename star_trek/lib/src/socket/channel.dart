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
import '../net/helper.dart';
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


///  Socket Channel Controller
///  ~~~~~~~~~~~~~~~~~~~~~~~~~
///
///  Reader, Writer
abstract class ChannelController<C extends SelectableChannel> {
  ChannelController(BaseChannel<C> channel) :
        _channelRef = WeakReference(channel);

  final WeakReference<BaseChannel<C>> _channelRef;

  BaseChannel<C>? get channel => _channelRef.target;

  SocketAddress? get remoteAddress => channel?.remoteAddress;
  SocketAddress? get localAddress => channel?.localAddress;

  C? get socket => channel?.socket;

}


abstract class BaseChannel<C extends SelectableChannel>
    extends AddressPairObject implements Channel {
  BaseChannel({super.remote, super.local}) {
    // create socket reader & writer
    reader = createReader();
    writer = createWriter();
  }

  SocketReader createReader();
  SocketWriter createWriter();

  // protected
  late final SocketReader reader;
  late final SocketWriter writer;

  // inner socket
  C? _sock;
  bool? _closed;

  //
  //  Socket
  //

  C? get socket => _sock;

  /// Set inner socket for this channel
  Future<void> setSocket(C? sock) async {
    // 1. replace with new socket
    C? old = _sock;
    if (sock != null) {
      _sock = sock;
      _closed = false;
    } else {
      _sock = null;
      _closed = true;
    }
    // 2. close old socket
    if (old == null || identical(old, sock)) {} else {
      await SocketHelper.socketDisconnect(old);
    }
  }

  //
  //  States
  //

  @override
  ChannelStatus get status {
    if (_closed == null) {
      // initializing
      return ChannelStatus.init;
    }
    C? sock = _sock;
    if (sock == null || SocketHelper.socketIsClosed(sock)) {
      // closed
      return ChannelStatus.closed;
    } else if (SocketHelper.socketIsConnected(sock) || SocketHelper.socketIsBound(sock)) {
      // normal
      return ChannelStatus.alive;
    } else {
      // opened
      return ChannelStatus.open;
    }
  }

  @override
  bool get isClosed {
    if (_closed == null) {
      // initializing
      return false;
    }
    C? sock = _sock;
    return sock == null || SocketHelper.socketIsClosed(sock);
  }

  @override
  bool get isBound {
    C? sock = _sock;
    return sock != null && SocketHelper.socketIsBound(sock);
  }

  @override
  bool get isConnected {
    C? sock = _sock;
    return sock != null && SocketHelper.socketIsConnected(sock);
  }

  @override
  bool get isAlive => (!isClosed) && (isConnected || isBound);

  @override
  bool get isAvailable {
    C? sock = _sock;
    if (sock == null || SocketHelper.socketIsClosed(sock)) {
      return false;
    } else if (SocketHelper.socketIsConnected(sock) || SocketHelper.socketIsBound(sock)) {
      // alive, check reading buffer
      return checkAvailable(sock);
    } else {
      return false;
    }
  }

  // protected
  bool checkAvailable(C sock) => SocketHelper.socketIsAvailable(sock);

  @override
  bool get isVacant {
    C? sock = _sock;
    if (sock == null || SocketHelper.socketIsClosed(sock)) {
      return false;
    } else if (SocketHelper.socketIsConnected(sock) || SocketHelper.socketIsBound(sock)) {
      // alive, check writing buffer
      return checkVacant(sock);
    } else {
      return false;
    }
  }

  // protected
  bool checkVacant(C sock) => SocketHelper.socketIsVacant(sock);

  @override
  bool get isBlocking {
    C? sock = _sock;
    return sock != null && SocketHelper.socketIsBlocking(sock);
  }

  @override
  String toString() {
    String clazz = className;
    return '<$clazz remote="$remoteAddress" local="$localAddress"'
        ' closed=$isClosed bound=$isBound connected=$isConnected>\n\t'
        '$_sock\n</$clazz>';
  }

  @override
  SelectableChannel? configureBlocking(bool block) {
    C? sock = socket;
    sock?.configureBlocking(block);
    return sock;
  }

  // protected
  Future<bool> doBind(C sock, SocketAddress local) async {
    if (sock is NetworkChannel) {
      return await SocketHelper.socketBind(sock as NetworkChannel, local);
    }
    assert(false, 'socket error: $sock');
    return false;
  }

  // protected
  Future<bool> doConnect(C sock, SocketAddress remote) async {
    if (sock is NetworkChannel) {
      return await SocketHelper.socketConnect(sock as NetworkChannel, remote);
    }
    assert(false, 'socket error: $sock');
    return false;
  }

  // protected
  Future<bool> doDisconnect(C sock) async =>
      await SocketHelper.socketDisconnect(sock);

  @override
  Future<NetworkChannel?> bind(SocketAddress local) async {
    C? sock = socket;
    bool ok = sock != null && await doBind(sock, local);
    if (!ok) {
      assert(false, 'failed to bind socket: $local');
      return null;
    }
    localAddress = local;
    return sock as NetworkChannel;
  }

  @override
  Future<NetworkChannel?> connect(SocketAddress remote) async {
    C? sock = socket;
    bool ok = sock != null && await doConnect(sock, remote);
    if (!ok) {
      assert(false, 'failed to connect socket: $remote');
      return null;
    }
    remoteAddress = remote;
    return sock as NetworkChannel;
  }

  @override
  Future<ByteChannel?> disconnect() async {
    C? sock = _sock;
    bool ok = sock == null || await doDisconnect(sock);
    if (!ok) {
      assert(false, 'failed to disconnect socket: $sock');
      return null;
    }
    // remoteAddress = null;
    return sock is ByteChannel ? sock as ByteChannel : null;
  }

  @override
  Future<void> close() async =>
      await setSocket(null);

  //
  //  Reading, Writing
  //

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
