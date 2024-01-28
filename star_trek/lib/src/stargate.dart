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
  void setItem(SocketAddress? remote, SocketAddress? local, Docker? value) {
    Docker? old = getItem(remote, local);
    if (old != null && old != value) {
      removeItem(remote, local, old);
    }
    super.setItem(remote, local, value);
  }

  @override
  Docker? removeItem(SocketAddress? remote, SocketAddress? local, Docker? value) {
    Docker? cached = super.removeItem(remote, local, value);
    if (cached == null || cached.isClosed) {} else {
      cached.close();
    }
    return cached;
  }
}


abstract class StarGate implements Gate, ConnectionDelegate {
  StarGate(DockerDelegate delegate) {
    _delegateRef = WeakReference(delegate);
    _dockerPool = createDockerPool();
  }

  // protected
  AddressPairMap<Docker> createDockerPool() => DockerPool();

  // delegate for handling docker events
  DockerDelegate? get delegate => _delegateRef.target;

  late final AddressPairMap<Docker> _dockerPool;
  late final WeakReference<DockerDelegate> _delegateRef;

  @override
  bool sendData(Uint8List payload, SocketAddress remote, SocketAddress local) {
    Docker? docker = getDocker(remote, local);
    if (docker == null || docker.isClosed) {
      return false;
    }
    return docker.sendData(payload);
  }

  @override
  bool sendShip(Departure outgo, SocketAddress remote, SocketAddress local) {
    Docker? docker = getDocker(remote, local);
    if (docker == null || docker.isClosed) {
      return false;
    }
    return docker.sendShip(outgo);
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
  Docker? getDocker(SocketAddress remote, SocketAddress? local) =>
      _dockerPool.getItem(remote, local);

  // protected
  void setDocker(SocketAddress remote, SocketAddress? local, Docker docker) =>
      _dockerPool.setItem(remote, local, docker);

  // protected
  void removeDocker(SocketAddress remote, SocketAddress? local, Docker? docker) =>
      _dockerPool.removeItem(remote, local, docker);

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
        removeDocker(worker.remoteAddress!, worker.localAddress, worker);
      } else {
        // clear expired tasks
        worker.purge(now);
      }
    }
  }

  ///  Send a heartbeat package('PING') to remote address
  // protected
  void heartbeat(Connection connection) {
    SocketAddress remote = connection.remoteAddress!;
    SocketAddress? local = connection.localAddress;
    Docker? worker = getDocker(remote, local);
    if (worker != null) {
      worker.heartbeat();
    }
  }

  //
  //  Connection Delegate
  //

  @override
  Future<void> onConnectionStateChanged(ConnectionState? previous, ConnectionState? current, Connection connection) async {
    // 1. callback when status changed
    DockerDelegate? delegate = this.delegate;
    if (delegate != null) {
      int s1 = DockerStatus.getStatus(previous);
      int s2 = DockerStatus.getStatus(current);
      if (s1 != s2) {
        // callback
        SocketAddress remote = connection.remoteAddress!;
        SocketAddress? local = connection.localAddress;
        Docker? docker = getDocker(remote, local);
        // NOTICE: if the previous state is null, the docker maybe not
        //         created yet, this situation means the docker status
        //         not changed too, so no need to callback here.
        if (docker != null) {
          delegate.onDockerStatusChanged(s1, s2, docker);
        }
      }
    }
    // 2. heartbeat when connection expired
    if (current?.index == ConnectionStateOrder.kExpired.index) {
      heartbeat(connection);
    }
  }

  @override
  Future<void> onConnectionReceived(Uint8List data, Connection connection) async {
    SocketAddress remote = connection.remoteAddress!;
    SocketAddress? local = connection.localAddress;
    // get docker by (remote, local)
    Docker? worker = getDocker(remote, local);
    if (worker != null) {
      // docker exists, call docker.onReceived(data);
      worker.processReceived(data);
      return;
    }

    // cache advance party for this connection
    List<Uint8List> advanceParty = cacheAdvanceParty(data, connection);
    assert(advanceParty.isNotEmpty, 'advance party error');

    // docker not exists, check the data to decide which docker should be created
    worker = createDocker(connection, advanceParty);
    if (worker != null) {
      // cache docker for (remote, local)
      setDocker(worker.remoteAddress!, worker.localAddress, worker);
      // process advance parties one by one
      for (Uint8List part in advanceParty) {
        worker.processReceived(part);
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
