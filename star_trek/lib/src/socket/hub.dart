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
import '../net/connection.dart';
import '../net/hub.dart';
import '../nio/address.dart';
import '../nio/exception.dart';
import '../type/mapping.dart';


class ConnectionPool extends AddressPairMap<Connection> {

  @override
  void setItem(Connection? value, {SocketAddress? remote, SocketAddress? local}) {
    Connection? old = getItem(remote: remote, local: local);
    if (old == null || identical(old, value)) {} else {
      removeItem(old, remote: remote, local: local);
    }
    super.setItem(value, remote: remote, local: local);
  }

  @override
  Connection? removeItem(Connection? value, {SocketAddress? remote, SocketAddress? local}) {
    Connection? cached = super.removeItem(value, remote: remote, local: local);
    if (value == null) {} else {
      /*await */value.close();
    }
    if (cached == null || identical(cached, value)) {} else {
      /*await */cached.close();
    }
    return cached;
  }

}


abstract class BaseHub implements Hub {
  BaseHub(ConnectionDelegate gate) {
    _delegateRef = WeakReference(gate);
    _connectionPool = createConnectionPool();
  }

  // protected
  AddressPairMap<Connection> createConnectionPool() => ConnectionPool();

  // delegate for handling connection events
  ConnectionDelegate? get delegate => _delegateRef.target;

  late final AddressPairMap<Connection> _connectionPool;
  late final WeakReference<ConnectionDelegate> _delegateRef;

  /*  Maximum Segment Size
     *  ~~~~~~~~~~~~~~~~~~~~
     *  Buffer size for receiving package
     *
     *  MTU        : 1500 bytes (excludes 14 bytes ethernet header & 4 bytes FCS)
     *  IP header  :   20 bytes
     *  TCP header :   20 bytes
     *  UDP header :    8 bytes
     */
  static int kMSS = 1472;  // 1500 - 20 - 8

  //
  //  Channel
  //

  ///  Get all channels
  ///
  /// @return copy of channels
  // protected
  Iterable<Channel> get allChannels;

  ///  Remove socket channel
  ///
  /// @param remote - remote address
  /// @param local  - local address
  /// @param channel - socket channel
  // protected
  Channel? removeChannel(Channel? channel, {SocketAddress? remote, SocketAddress? local});

  //
  //  Connection
  //

  ///  Create connection with sock channel & addresses
  ///
  /// @param remote - remote address
  /// @param local  - local address
  /// @return null on channel not exists
  // protected
  Connection? createConnection({required SocketAddress remote, SocketAddress? local});

  // protected
  Iterable<Connection> get allConnections => _connectionPool.items;

  // protected
  Connection? getConnection({required SocketAddress remote, SocketAddress? local}) =>
      _connectionPool.getItem(remote: remote, local: local);

  // protected
  void setConnection(Connection conn, {required SocketAddress remote, SocketAddress? local}) =>
      _connectionPool.setItem(conn, remote: remote, local: local);

  // protected
  Connection? removeConnection(Connection? conn, {required SocketAddress remote, SocketAddress? local}) =>
      _connectionPool.removeItem(conn, remote: remote, local: local);

  @override
  Future<Connection?> connect({required SocketAddress remote, SocketAddress? local}) async {
    Connection? conn = getConnection(remote: remote, local: local);
    if (conn == null) {
      conn = createConnection(remote: remote, local: local);
      if (conn != null) {
        // NOTICE: local address in the connection may be set to None
        setConnection(conn, remote: conn.remoteAddress!, local: conn.localAddress);
        // try to open channel with direction (remote, local)
        /*await */conn.start(this);
      }
    }
    return conn;
  }

  //
  //  Process
  //

  // protected
  Future<bool> driveChannel(Channel sock) async {
    if (sock.isAlive) {} else {
      // cannot drive closed channel
      return false;
    }
    Pair<Uint8List?, SocketAddress?> pair;
    Uint8List? data;
    SocketAddress? remote;
    SocketAddress? local;
    // try to receiver
    try {
      pair = await sock.receive(kMSS);
      data = pair.first;
      remote = pair.second;
    } on IOException catch (e) {
      // print(e);
      remote = sock.remoteAddress;
      local = sock.localAddress;
      ConnectionDelegate? gate = delegate;
      if (gate == null || remote == null) {
        // UDP channel may not connected,
        // so no connection for it
        removeChannel(sock, remote: remote, local: local);
      } else {
        // remove channel and callback with connection
        Connection? conn = getConnection(remote: remote, local: local);
        removeChannel(sock, remote: remote, local: local);
        if (conn != null) {
          await gate.onConnectionError(IOError(e), conn);
        }
      }
      return false;
    }
    if (remote == null) {
      // received nothing
      return false;
    } else {
      assert(data != null, 'data should not empty: $remote');
      local = sock.localAddress;
    }
    // get connection for processing received data
    Connection? conn = await connect(remote: remote, local: local);
    if (conn != null) {
      await conn.onReceivedData(data!);
    }
    return true;
  }

  // protected
  Future<int> driveChannels(Iterable<Channel> channels) async {
    int count = 0;
    for (Channel sock in channels) {
      // drive channel to receive data
      if (await driveChannel(sock)) {
        count += 1;
      }
    }
    return count;
  }

  // protected
  void cleanupChannels(Iterable<Channel> channels) {
    for (Channel sock in channels) {
      if (sock.isClosed) {
        // if channel not connected (TCP) and not bound (UDP),
        // means it's closed, remove it from the hub
        removeChannel(sock, remote: sock.remoteAddress, local: sock.localAddress);
      }
    }
  }

  DateTime _last = DateTime.now();

  // protected
  Future<void> driveConnections(Iterable<Connection> connections) async {
    DateTime now = DateTime.now();
    int delta = now.millisecondsSinceEpoch - _last.millisecondsSinceEpoch;
    for (Connection conn in connections) {
      // drive connection to go on
      await conn.tick(now, delta);
      // NOTICE: let the delegate to decide whether close an error connection
      //         or just remove it.
    }
    _last = now;
  }

  // protected
  void cleanupConnections(Iterable<Connection> connections) {
    for (Connection conn in connections) {
      if (conn.isClosed) {
        // if connection closed, remove it from the hub; notice that
        // ActiveConnection can reconnect, it'll be not connected
        // but still open, don't remove it in this situation.
        removeConnection(conn, remote: conn.remoteAddress!, local: conn.localAddress);
      }
    }
  }

  @override
  Future<bool> process() async {
    // 1. drive all channels to receive data
    Iterable<Channel> channels = allChannels;
    int count = await driveChannels(channels);
    // 2. drive all connections to move on
    Iterable<Connection> connections = allConnections;
    await driveConnections(connections);
    // 3. cleanup closed channels and connections
    cleanupChannels(channels);
    cleanupConnections(connections);
    return count > 0;
  }

}
