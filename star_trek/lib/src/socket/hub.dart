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

import 'connection.dart';


class ConnectionPool extends AddressPairMap<Connection> {

  @override
  Connection? setItem(Connection? value, {SocketAddress? remote, SocketAddress? local}) {
    // remove cached item
    Connection? cached = super.removeItem(value, remote: remote, local: local);
    // if (cached == null || identical(cached, value)) {} else {
    //   /*await */cached.close();
    // }
    Connection? old = super.setItem(value, remote: remote, local: local);
    assert(old == null, 'should not happen');
    return cached;
  }

  // @override
  // Connection? removeItem(Connection? value, {SocketAddress? remote, SocketAddress? local}) {
  //   Connection? cached = super.removeItem(value, remote: remote, local: local);
  //   if (cached == null || identical(cached, value)) {} else {
  //     /*await */cached.close();
  //   }
  //   if (value == null) {} else {
  //     /*await */value.close();
  //   }
  //   return cached;
  // }

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
  // ignore: non_constant_identifier_names
  static int MSS = 1472;  // 1500 - 20 - 8

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
  /// @return Connection
  // protected
  Connection createConnection({required SocketAddress remote, SocketAddress? local});

  // protected
  Iterable<Connection> get allConnections => _connectionPool.items;

  // protected
  Connection? getConnection({required SocketAddress remote, SocketAddress? local}) =>
      _connectionPool.getItem(remote: remote, local: local);

  // protected
  Connection? setConnection(Connection conn, {required SocketAddress remote, SocketAddress? local}) =>
      _connectionPool.setItem(conn, remote: remote, local: local);

  // protected
  Connection? removeConnection(Connection? conn, {required SocketAddress remote, SocketAddress? local}) =>
      _connectionPool.removeItem(conn, remote: remote, local: local);

  @override
  Future<Connection?> connect({required SocketAddress remote, SocketAddress? local}) async {
    //
    //  0. pre-checking
    //
    Connection? conn = getConnection(remote: remote, local: local);
    if (conn != null) {
      // check local address
      if (local == null) {
        return conn;
      }
      SocketAddress? address = conn.localAddress;
      if (address == null || address == local) {
        return conn;
      }
    }
    //
    //  1. create new connection & cache it
    //
    conn = createConnection(remote: remote, local: local);
    local ??= conn.localAddress;
    // cache the connection
    var cached = setConnection(conn, remote: remote, local: local);
    if (cached == null || identical(cached, conn)) {} else {
      await cached.close();
    }
    //
    //  2. start the new connection
    //
    if (conn is BaseConnection) {
      // try to open channel with direction (remote, local)
      await conn.start(this);
    } else {
      assert(false, 'connection error: $remote, $conn');
    }
    return conn;
  }

  //
  //  Process
  //

  // protected
  Future<void> closeChannel(Channel sock) async {
    try {
      if (sock.isClosed) {} else {
        await sock.close();
      }
    } on IOException catch (_) {
      // print(e);
    }
  }

  // protected
  Future<bool> driveChannel(Channel sock) async {
    //
    //  0. check channel state
    //
    ChannelStatus cs = sock.status;
    if (cs == ChannelStatus.init) {
      // preparing
      return false;
    } else if (cs == ChannelStatus.closed) {
      // finished
      return false;
    }
    // cs == opened
    // cs == alive
    Uint8List? data;
    SocketAddress? remote;
    SocketAddress? local;
    //
    //  1. try to receive
    //
    try {
      Pair<Uint8List?, SocketAddress?> pair = await sock.receive(MSS);
      data = pair.first;
      remote = pair.second;
    } on IOException catch (e) {
      // print(e);
      remote = sock.remoteAddress;
      local = sock.localAddress;
      ConnectionDelegate? gate = delegate;
      Channel? cached;
      if (gate == null || remote == null) {
        // UDP channel may not connected,
        // so no connection for it
        cached = removeChannel(sock, remote: remote, local: local);
      } else {
        // remove channel and callback with connection
        Connection? conn = getConnection(remote: remote, local: local);
        cached = removeChannel(sock, remote: remote, local: local);
        if (conn != null) {
          await gate.onConnectionError(IOError(e), conn);
        }
      }
      // close removed/error channels
      if (cached == null || identical(cached, sock)) {} else {
        await closeChannel(cached);
      }
      await closeChannel(sock);
      return false;
    }
    if (remote == null || data == null) {
      // received nothing
      return false;
    } else {
      assert(data.isNotEmpty, 'data should not empty: $remote');
      local = sock.localAddress;
    }
    //
    //  2. get connection for processing received data
    //
    Connection? conn = await connect(remote: remote, local: local);
    if (conn != null) {
      await conn.onReceivedData(data);
    }
    return true;
  }

  // protected
  Future<int> driveChannels(Iterable<Channel> channels) async {
    int count = 0;
    List<Future<bool>> futures = [];
    Future<bool> task;
    for (Channel sock in channels) {
      // drive channel to receive data
      task = driveChannel(sock);
      futures.add(task);
    }
    List<bool> results = await Future.wait(futures);
    for (bool busy in results) {
      if (busy) {
        count += 1;  // it's busy
      }
    }
    return count;
  }

  // protected
  Future<void> cleanupChannels(Iterable<Channel> channels) async {
    Channel? cached;
    for (Channel sock in channels) {
      if (sock.isClosed) {
        // if channel not connected (TCP) and not bound (UDP),
        // means it's closed, remove it from the hub
        cached = removeChannel(sock, remote: sock.remoteAddress, local: sock.localAddress);
        if (cached == null || identical(cached, sock)) {} else {
          await closeChannel(cached);
        }
      }
    }
  }

  DateTime _last = DateTime.now();

  // protected
  Future<void> driveConnections(Iterable<Connection> connections) async {
    DateTime now = DateTime.now();
    int delta = now.microsecondsSinceEpoch - _last.microsecondsSinceEpoch;
    Duration elapsed = Duration(microseconds: delta);
    List<Future<void>> futures = [];
    Future<void> task;
    for (Connection conn in connections) {
      // drive connection to go on
      task = conn.tick(now, elapsed);
      futures.add(task);
      // NOTICE: let the delegate to decide whether close an error connection
      //         or just remove it.
    }
    await Future.wait(futures);
    _last = now;
  }

  // protected
  Future<void> cleanupConnections(Iterable<Connection> connections) async {
    Connection? cached;
    for (Connection conn in connections) {
      if (conn.isClosed) {
        // if connection closed, remove it from the hub; notice that
        // ActiveConnection can reconnect, it'll be not connected
        // but still open, don't remove it in this situation.
        cached = removeConnection(conn, remote: conn.remoteAddress!, local: conn.localAddress);
        if (cached == null || identical(cached, conn)) {} else {
          await cached.close();
        }
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
    await cleanupChannels(channels);
    await cleanupConnections(connections);
    return count > 0;
  }

}
