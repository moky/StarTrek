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
import 'port/docker.dart';
import 'port/gate.dart';
import 'port/ship.dart';
import 'type/mapping.dart';


class DockerPool extends AddressPairMap<Docker> {

  @override
  void setItem(Docker? value, {SocketAddress? remote, SocketAddress? local}) {
    Docker? old = getItem(remote: remote, local: local);
    if (old != null && old != value) {
      removeItem(old, remote: remote, local: local);
    }
    super.setItem(value, remote: remote, local: local);
  }

  @override
  Docker? removeItem(Docker? value, {SocketAddress? remote, SocketAddress? local}) {
    Docker? cached = super.removeItem(value, remote: remote, local: local);
    if (cached == null || cached.isClosed) {} else {
      cached.close();
    }
    return cached;
  }
}


abstract class StarGate implements Gate, ConnectionDelegate {
  StarGate(DockerDelegate keeper) {
    _delegateRef = WeakReference(keeper);
    _dockerPool = createDockerPool();
  }

  // protected
  AddressPairMap<Docker> createDockerPool() => DockerPool();

  // delegate for handling docker events
  DockerDelegate? get delegate => _delegateRef.target;

  late final AddressPairMap<Docker> _dockerPool;
  late final WeakReference<DockerDelegate> _delegateRef;

  @override
  Future<bool> sendData(Uint8List payload, {required SocketAddress remote, SocketAddress? local}) async {
    Docker? docker = getDocker(remote: remote, local: local);
    if (docker == null || docker.isClosed) {
      return false;
    }
    return await docker.sendData(payload);
  }

  @override
  Future<bool> sendShip(Departure outgo, {required SocketAddress remote, SocketAddress? local}) async {
    Docker? docker = getDocker(remote: remote, local: local);
    if (docker == null || docker.isClosed) {
      return false;
    }
    return await docker.sendShip(outgo);
  }

  //
  //  Docker
  //

  ///  Create new docker for received data
  ///
  /// @param conn   - current connection
  /// @param data   - advance party
  /// @return docker
  // protected
  Docker? createDocker(Connection conn, List<Uint8List> data);

  // protected
  Set<Docker> allDockers() => _dockerPool.items;

  // protected
  Docker? getDocker({required SocketAddress remote, SocketAddress? local}) =>
      _dockerPool.getItem(remote: remote, local: local);

  // protected
  void setDocker(Docker docker, {required SocketAddress remote, SocketAddress? local}) =>
      _dockerPool.setItem(docker, remote: remote, local: local);

  // protected
  void removeDocker(Docker? docker, {required SocketAddress remote, SocketAddress? local}) =>
      _dockerPool.removeItem(docker, remote: remote, local: local);

  //
  //  Processor
  //

  @override
  Future<bool> process() async {
    Set<Docker> dockers = allDockers();
    // 1. drive all dockers to process
    int count = await driveDockers(dockers);
    // 2. cleanup for dockers
    cleanupDockers(dockers);
    return count > 0;
  }

  // protected
  Future<int> driveDockers(Set<Docker> dockers) async {
    int count = 0;
    for (Docker worker in dockers) {
      if (await worker.process()) {
        ++count;  // it's busy
      }
    }
    return count;
  }
  // protected
  void cleanupDockers(Set<Docker> dockers) {
    DateTime now = DateTime.now();
    for (Docker worker in dockers) {
      if (worker.isClosed) {
        // remove docker when connection closed
        removeDocker(worker, remote: worker.remoteAddress!, local: worker.localAddress);
      } else {
        // clear expired tasks
        worker.purge(now);
      }
    }
  }

  ///  Send a heartbeat package('PING') to remote address
  // protected
  Future<void> heartbeat(Connection connection) async {
    SocketAddress remote = connection.remoteAddress!;
    SocketAddress? local = connection.localAddress;
    Docker? worker = getDocker(remote: remote, local: local);
    if (worker != null) {
      await worker.heartbeat();
    }
  }

  //
  //  Connection Delegate
  //

  @override
  Future<void> onConnectionStateChanged(ConnectionState? previous, ConnectionState? current, Connection connection) async {
    // 1. callback when status changed
    DockerDelegate? keeper = delegate;
    if (keeper != null) {
      DockerStatus s1 = DockerStatus.getStatus(previous);
      DockerStatus s2 = DockerStatus.getStatus(current);
      if (s1 != s2) {
        // callback
        SocketAddress remote = connection.remoteAddress!;
        SocketAddress? local = connection.localAddress;
        Docker? docker = getDocker(remote: remote, local: local);
        // NOTICE: if the previous state is null, the docker maybe not
        //         created yet, this situation means the docker status
        //         not changed too, so no need to callback here.
        if (docker != null) {
          await keeper.onDockerStatusChanged(s1, s2, docker);
        }
      }
    }
    // 2. heartbeat when connection expired
    if (current?.index == ConnectionStateOrder.kExpired.index) {
      await heartbeat(connection);
    }
  }

  @override
  Future<void> onConnectionReceived(Uint8List data, Connection connection) async {
    SocketAddress remote = connection.remoteAddress!;
    SocketAddress? local = connection.localAddress;
    // get docker by (remote, local)
    Docker? worker = getDocker(remote: remote, local: local);
    if (worker != null) {
      // docker exists, call docker.onReceived(data);
      await worker.processReceived(data);
      return;
    }

    // cache advance party for this connection
    List<Uint8List> advanceParty = cacheAdvanceParty(data, connection);
    assert(advanceParty.isNotEmpty, 'advance party error');

    // docker not exists, check the data to decide which docker should be created
    worker = createDocker(connection, advanceParty);
    if (worker != null) {
      // cache docker for (remote, local)
      setDocker(worker, remote: worker.remoteAddress!, local: worker.localAddress);
      // process advance parties one by one
      for (Uint8List part in advanceParty) {
        await worker.processReceived(part);
      }
      // remove advance party
      clearAdvanceParty(connection);
    }
  }

  /// cache the advance party before decide which docker to use
  // protected
  List<Uint8List> cacheAdvanceParty(Uint8List data, Connection connection);
  // protected
  void clearAdvanceParty(Connection connection);

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
