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

import 'net/connection.dart';
import 'nio/exception.dart';
import 'port/docker.dart';
import 'port/ship.dart';
import 'type/pair.dart';
import 'dock.dart';


abstract class StarDocker extends AddressPairObject implements Docker {
  StarDocker(Connection conn) : super(remote: conn.remoteAddress, local: conn.localAddress) {
    _connectionRef = WeakReference(conn);
    _delegateRef = null;
    _dock = createDock();
    // remaining data to be sent
    _lastOutgo = null;
    _lastFragments = [];
  }

  WeakReference<Connection>? _connectionRef;
  WeakReference<DockerDelegate>? _delegateRef;

  Dock? _dock;

  // remaining data to be sent
  Departure? _lastOutgo;
  late List<Uint8List> _lastFragments;

  // protected
  void finalize() {
    // make sure the relative connection is closed
    _removeConnection();
    _dock = null;
  }

  // protected
  Dock createDock() => Dock();  // override for user-customized dock

  // delegate for handling docker events
  DockerDelegate? get delegate => _delegateRef?.target;
  set delegate(DockerDelegate? keeper) =>
      _delegateRef = keeper == null ? null : WeakReference(keeper);

  // protected
  Connection? get connection => _connectionRef?.target;
  void _removeConnection() {
    // 1. clear connection reference
    Connection? old = _connectionRef?.target;
    _connectionRef = null;
    // 2. close old connection
    if (old == null || old.isClosed) {} else {
      old.close();
    }
  }

  @override
  bool get isClosed => connection?.isClosed != false;

  @override
  bool get isAlive => connection?.isAlive == true;

  @override
  DockerStatus get status => DockerStatus.getStatus(connection?.state);

  // @override
  // SocketAddress? get localAddress {
  //   Connection? conn = connection;
  //   return conn == null ? super.localAddress : conn.localAddress;
  // }

  @override
  String toString() {
    Type clazz = runtimeType;
    return '<$clazz remote="$remoteAddress" local="$localAddress">\n\t'
        '$connection\n</$clazz>';
  }

  @override
  Future<bool> sendShip(Departure ship) async =>
      _dock?.addDeparture(ship) ?? false;

  @override
  Future<void> processReceived(Uint8List data) async {
    // 1. get income ship from received data
    List<Arrival> ships = getArrivals(data);
    if (ships.isEmpty) {
      // waiting for more data
      return;
    }
    Arrival? income;
    for (Arrival item in ships) {
      // 2. check income ship for response
      income = checkArrival(item);
      if (income == null) {
        // waiting for more fragment
        return;
      }
      // 3. callback for processing income ship with completed data package
      await delegate?.onDockerReceived(income, this);
    }
  }

  ///  Get income ships from received data
  ///
  /// @param data - received data
  /// @return income ships carrying data package/fragments
  // protected
  List<Arrival> getArrivals(Uint8List data);

  ///  Check income ship for responding
  ///
  /// @param income - income ship carrying data package/fragment/response
  /// @return income ship carrying completed data package
  // protected
  Arrival? checkArrival(Arrival income);

  ///  Check and remove linked departure ship with same SN (and page index for fragment)
  ///
  /// @param income - income ship with SN
  // protected
  Future<void> checkResponse(Arrival income) async {
    // check response for linked departure ship (same SN)
    Departure? linked = _dock?.checkResponse(income);
    if (linked == null) {
      // linked departure task not found, or not finished yet
      return;
    }
    // all fragments responded, task finished
    await delegate?.onDockerSent(linked, this);
  }

  /// Check received ship for completed package
  ///
  /// @param income - income ship carrying data package (fragment)
  /// @return ship carrying completed data package
  // protected
  Arrival? assembleArrival(Arrival income) =>
      _dock?.assembleArrival(income);

  ///  Get outgo ship from waiting queue
  ///
  /// @param now - current time
  /// @return next new or timeout task
  // protected
  Departure? getNextDeparture(DateTime now) =>
      _dock?.getNextDeparture(now);

  @override
  void purge([DateTime? now]) => _dock?.purge(now);

  @override
  void close() {
    _removeConnection();
    _dock = null;
  }

  //
  //  Processor
  //

  @override
  Future<bool> process() async {
    // 1. get connection which is ready for sending data
    Connection? conn = connection;
    if (conn == null || !conn.isAlive) {
      // connection not ready now
      return false;
    }
    // 2. get data waiting to be sent out
    Departure? outgo = _lastOutgo;
    List<Uint8List> fragments = _lastFragments;
    if (outgo != null && fragments.isNotEmpty) {
      // got remaining fragments from last outgo task
      _lastOutgo = null;
      _lastFragments = [];
    } else {
      // get next outgo task
      DateTime now = DateTime.now();
      outgo = getNextDeparture(now);
      if (outgo == null) {
        // nothing to do now, return false to let the thread have a rest
        return false;
      } else if (outgo.getStatus(now) == ShipStatus.failed) {
        // callback for mission failed
        await delegate?.onDockerFailed(IOError('Request timeout'), outgo, this);
        // task timeout, return true to process next one
        return true;
      } else {
        // get fragments from outgo task
        fragments = outgo.fragments;
        if (fragments.isEmpty) {
          // all fragments of this task have been sent already
          // return true to process next one
          return true;
        }
      }
    }
    // 3. process fragments of outgo task
    IOError error;
    int index = 0, sent = 0;
    try {
      for (Uint8List fra in fragments) {
        sent = await conn.sendData(fra);
        if (sent < fra.length) {
          // buffer overflow?
          break;
        } else {
          assert(sent == fra.length, 'length of fragment sent error: $sent, ${fra.length}');
          index += 1;
          sent = 0;  // clear counter
        }
      }
      if (index < fragments.length) {
        // task failed
        throw SocketException('only $index/${fragments.length} fragments sent.');
      } else {
        // task done
        return true;
      }
    } on IOException catch (ex) {
      // socket error, callback
      error = IOError(ex);
    }
    // 4. remove sent fragments
    for (; index > 0; --index) {
      fragments.removeAt(0);
    }
    // remove partially sent data of next fragment
    if (sent > 0) {
      Uint8List last = fragments.removeAt(0);
      fragments.insert(0, last.sublist(sent));
    }
    // 5. store remaining data
    _lastOutgo = outgo;
    _lastFragments = fragments;
    // 6. callback for error
    //await delegate?.onDockerFailed(error, outgo, this);
    await delegate?.onDockerError(error, outgo, this);
    return false;
  }

}
