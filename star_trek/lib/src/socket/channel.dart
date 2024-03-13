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
import '../nio/exception.dart';
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

abstract class ChannelReader<C extends SelectableChannel>
    extends ChannelController<C> implements SocketReader {
  ChannelReader(super.channel);

  @override
  Future<Uint8List?> read(int maxLen) async {
    C? sock = socket;
    if (sock == null || sock.isClosed) {
      throw ClosedChannelException();
    } else if (sock is ReadableByteChannel) {
      return await (sock as ReadableByteChannel).read(maxLen);
    } else {
      assert(false, 'socket error, cannot read data: $sock');
      return null;
    }
  }

}

abstract class ChannelWriter<C extends SelectableChannel>
    extends ChannelController<C> implements SocketWriter {
  ChannelWriter(super.channel);

  @override
  Future<int> write(Uint8List src) async {
    C? sock = socket;
    if (sock == null || sock.isClosed) {
      throw ClosedChannelException();
    } else if (sock is WritableByteChannel) {
      return await (sock as WritableByteChannel).write(src);
    } else {
      assert(false, 'socket error, cannot write data: ${src.lengthInBytes} byte(s)');
      return -1;
    }
  }

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
    // } else {
    //   _sock = null;
    }
    // 2. close old socket
    if (old == null || identical(old, sock)) {} else {
      await socketDisconnect(old);
    }
  }

  //
  //  Flags
  //

  @override
  bool get isClosed {
    C? sock = _sock;
    if (sock == null) {
      // initializing
      return false;
    } else {
      return socketIsClosed(sock);
    }
  }

  @override
  bool get isBound {
    C? sock = socket;
    return sock != null && socketIsBound(sock);
  }

  @override
  bool get isConnected {
    C? sock = socket;
    return sock != null && socketIsConnected(sock);
  }

  @override
  bool get isAlive => (!isClosed) && (isConnected || isBound);

  @override
  bool get isAvailable => isAlive;

  @override
  bool get isVacant => isAlive;

  @override
  bool get isBlocking {
    C? sock = socket;
    return sock != null && socketIsBlocking(sock);
  }

  @override
  String toString() {
    Type clazz = runtimeType;
    return '<$clazz remote="$remoteAddress" local="$localAddress"'
        ' closed=$isClosed bound=$isBound connected="$isConnected" >\n\t'
        '$socket\n</$clazz>';
  }

  @override
  SelectableChannel? configureBlocking(bool block) {
    C? sock = socket;
    sock?.configureBlocking(block);
    return sock;
  }

  @override
  Future<NetworkChannel?> bind(SocketAddress local) async {
    NetworkChannel? nc = socket as NetworkChannel?;
    bool ok = nc != null && await socketBind(nc, local);
    assert(ok, 'failed to bind socket: $local');
    localAddress = local;
    return nc;
  }

  @override
  Future<NetworkChannel?> connect(SocketAddress remote) async {
    NetworkChannel? nc = socket as NetworkChannel?;
    bool ok = nc != null && await socketConnect(nc, remote);
    assert(ok, 'failed to connect socket: $remote');
    remoteAddress = remote;
    return nc;
  }

  @override
  Future<ByteChannel?> disconnect() async {
    C? sock = _sock;
    if (sock == null) {
      return null;
    }
    bool ok = await socketDisconnect(sock);
    assert(ok, 'failed to disconnect socket: $sock');
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
