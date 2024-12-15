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

import 'net/connection.dart';
import 'net/state.dart';
import 'nio/address.dart';
import 'nio/exception.dart';
import 'port/docker.dart';
import 'port/gate.dart';
import 'port/ship.dart';
import 'type/mapping.dart';

import 'stardocker.dart';


class PorterPool extends AddressPairMap<Porter> {

  @override
  Porter? setItem(Porter? value, {SocketAddress? remote, SocketAddress? local}) {
    // remove cached item
    Porter? cached = super.removeItem(value, remote: remote, local: local);
    // if (cached == null || identical(cached, value)) {} else {
    //   /*await */cached.close();
    // }
    Porter? old = super.setItem(value, remote: remote, local: local);
    assert(old == null, 'should not happen');
    return cached;
  }

  // @override
  // Porter? removeItem(Porter? value, {SocketAddress? remote, SocketAddress? local}) {
  //   Porter? cached = super.removeItem(value, remote: remote, local: local);
  //   if (cached == null || identical(cached, value)) {} else {
  //     /*await */cached.close();
  //   }
  //   if (value == null) {} else {
  //     /*await */value.close();
  //   }
  //   return cached;
  // }

}


abstract class StarGate implements Gate, ConnectionDelegate {
  StarGate(PorterDelegate keeper) {
    _delegateRef = WeakReference(keeper);
    _porterPool = createPorterPool();
  }

  // protected
  AddressPairMap<Porter> createPorterPool() => PorterPool();

  // delegate for handling docker events
  PorterDelegate? get delegate => _delegateRef.target;

  late final AddressPairMap<Porter> _porterPool;
  late final WeakReference<PorterDelegate> _delegateRef;

  @override
  Future<bool> sendData(Uint8List payload, {required SocketAddress remote, SocketAddress? local}) async {
    Porter? docker = getPorter(remote: remote, local: local);
    if (docker == null) {
      assert(false, 'docker not found: $local -> $remote');
      return false;
    } else if (!docker.isAlive) {
      assert(false, 'docker not alive: $local -> $remote');
      return false;
    }
    return await docker.sendData(payload);
  }

  @override
  Future<bool> sendShip(Departure outgo, {required SocketAddress remote, SocketAddress? local}) async {
    Porter? docker = getPorter(remote: remote, local: local);
    if (docker == null) {
      assert(false, 'docker not found: $local -> $remote');
      return false;
    } else if (!docker.isAlive) {
      assert(false, 'docker not alive: $local -> $remote');
      return false;
    }
    return await docker.sendShip(outgo);
  }

  //
  //  Docker
  //

  ///  Create new docker for received data
  ///
  /// @param remote - remote address
  /// @param local  - local address
  /// @return Docker
  // protected
  Porter createPorter({required SocketAddress remote, SocketAddress? local});

  // protected
  Iterable<Porter> allPorters() => _porterPool.items;

  // protected
  Porter? removePorter(Porter? porter, {required SocketAddress remote, SocketAddress? local}) =>
      _porterPool.removeItem(porter, remote: remote, local: local);

  // protected
  Porter? getPorter({required SocketAddress remote, SocketAddress? local}) =>
      _porterPool.getItem(remote: remote, local: local);

  // protected
  Porter? setPorter(Porter porter, {required SocketAddress remote, SocketAddress? local}) =>
      _porterPool.setItem(porter, remote: remote, local: local);

  // protected
  Future<Porter?> dock(Connection connection, bool newPorter) async {
    SocketAddress? remote = connection.remoteAddress;
    SocketAddress? local = connection.localAddress;
    if (remote == null) {
      assert(false, 'remote address should not empty');
      return null;
    }
    //
    //  1. try to get docker
    //
    Porter? docker = getPorter(remote: remote, local: local);
    if (docker != null) {
      // found
      return docker;
    } else if (!newPorter) {
      // no need to create new docker
      return null;
    }
    //
    //  2. create new docker
    //
    docker = createPorter(remote: remote, local: local);
    Porter? cached = setPorter(docker, remote: remote, local: local);
    if (cached == null || identical(cached, docker)) {} else {
      await cached.close();
    }
    //
    //  3. set connection for this docker
    //
    if (docker is StarPorter) {
      // set connection for this docker
      await docker.setConnection(connection);
    } else {
      assert(false, 'docker error: $remote, $docker');
    }
    return docker;
  }

  //
  //  Processor
  //

  @override
  Future<bool> process() async {
    Iterable<Porter> dockers = allPorters();
    // 1. drive all dockers to process
    int count = await drivePorters(dockers);
    // 2. cleanup for dockers
    await cleanupPorters(dockers);
    return count > 0;
  }

  // protected
  Future<int> drivePorters(Iterable<Porter> porters) async {
    int count = 0;
    for (Porter docker in porters) {
      if (await docker.process()) {
        ++count;  // it's busy
      }
    }
    return count;
  }
  // protected
  Future<void> cleanupPorters(Iterable<Porter> porters) async {
    DateTime now = DateTime.now();
    Porter? cached;
    for (Porter docker in porters) {
      if (!docker.isClosed) {
        // docker connected,
        // clear expired tasks
        docker.purge(now);
        continue;
      }
      // remove docker when connection closed
      cached = removePorter(docker, remote: docker.remoteAddress!, local: docker.localAddress);
      if (cached == null || identical(cached, docker)) {} else {
        await cached.close();
      }
    }
  }

  ///  Send a heartbeat package('PING') to remote address
  // protected
  Future<void> heartbeat(Connection connection) async {
    SocketAddress remote = connection.remoteAddress!;
    SocketAddress? local = connection.localAddress;
    Porter? docker = getPorter(remote: remote, local: local);
    await docker?.heartbeat();
  }

  //
  //  Connection Delegate
  //

  @override
  Future<void> onConnectionStateChanged(ConnectionState? previous, ConnectionState? current, Connection connection) async {
    // convert status
    PorterStatus s1 = PorterStatus.getStatus(previous);
    PorterStatus s2 = PorterStatus.getStatus(current);
    //
    //  1. callback when status changed
    //
    if (s1 != s2) {
      bool notFinished = s2 != PorterStatus.error;
      Porter? docker = await dock(connection, notFinished);
      if (docker == null) {
        // connection closed and docker removed
        return;
      }
      // callback for docker status
      await delegate?.onPorterStatusChanged(s1, s2, docker);
    }
    //
    //  2. heartbeat when connection expired
    //
    if (current?.index == ConnectionStateOrder.expired.index) {
      await heartbeat(connection);
    }
  }

  @override
  Future<void> onConnectionReceived(Uint8List data, Connection connection) async {
    Porter? docker = await dock(connection, true);
    if (docker == null) {
      assert(false, 'failed to create docker: $connection');
    } else {
      await docker.processReceived(data);
    }
  }

  @override
  Future<void> onConnectionSent(int sent, Uint8List data, Connection connection) async {
    // ignore event for sending success
  }

  @override
  Future<void> onConnectionFailed(IOError error, Uint8List data, Connection connection) async {
    // ignore event for sending failed
  }

  @override
  Future<void> onConnectionError(IOError error, Connection connection) async {
    // ignore event for receiving error
  }

}
