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

import '../fsm/runner.dart';
import '../net/channel.dart';
import '../net/connection.dart';
import '../net/hub.dart';
import '../net/state.dart';
import '../nio/address.dart';
import '../nio/exception.dart';
import '../type/pair.dart';


class BaseConnection extends AddressPairObject
    implements Connection, TimedConnection, ConnectionStateDelegate {
  BaseConnection(Channel? sock, {super.remote, super.local}) {
    _channelRef = sock == null ? null : WeakReference(sock);
  }

  static int kExpires = 16 * 1000;  // 16 seconds

  WeakReference<Channel>? _channelRef;
  WeakReference<ConnectionDelegate>? _delegateRef;

  // active times
  DateTime? _lastSentTime;
  DateTime? _lastReceivedTime;

  // connection state machine
  ConnectionStateMachine? _fsm;

  // protected
  void finalize() {
    // make sure the state machine is stopped
    setStateMachine(null);
    // make sure the relative channel is closed
    setChannel(null);
  }

  Future<Channel?> get channel async => getChannel();
  // protected
  Channel? getChannel() => _channelRef?.target;
  // protected
  Future<void> setChannel(Channel? sock) async {
    // 1. replace with new channel
    Channel? old = getChannel();
    _channelRef = sock == null ? null : WeakReference(sock);
    // 2. close old channel
    if (old == null || identical(old, sock)) {} else {
      if (old.isConnected) {
        await old.disconnect();
      }
    }
  }

  // delegate for handling connection events
  ConnectionDelegate? get delegate => _delegateRef?.target;
  set delegate(ConnectionDelegate? gate) =>
      _delegateRef = gate == null ? null : WeakReference(gate);

  // protected
  ConnectionStateMachine? getStateMachine() => _fsm;
  // protected
  Future<void> setStateMachine(ConnectionStateMachine? fsm) async {
    // 1. replace with new machine
    ConnectionStateMachine? old = _fsm;
    _fsm = fsm;
    // 2. stop old machine
    if (old == null || identical(old, fsm)) {} else {
      await old.stop();
    }
  }
  // protected
  ConnectionStateMachine createStateMachine() {
    ConnectionStateMachine machine = ConnectionStateMachine(this);
    machine.delegate = this;
    return machine;
  }

  @override
  bool get isClosed => getChannel()?.isClosed != false;

  @override
  bool get isBound => getChannel()?.isBound == true;

  @override
  bool get isConnected => getChannel()?.isConnected == true;

  @override
  bool get isAlive => (!isClosed) && (isConnected || isBound);
  // bool get isAlive => getChannel()?.isAlive == true;

  // @override
  // SocketAddress? get remoteAddress {
  //   SocketAddress? address = super.remoteAddress;
  //   if (address == null) {
  //     var sock = getChannel();
  //     if (sock != null) {
  //       address = sock.remoteAddress;
  //     }
  //   }
  //   return address;
  // }
  //
  // @override
  // SocketAddress? get localAddress {
  //   SocketAddress? address = super.localAddress;
  //   if (address == null) {
  //     var sock = getChannel();
  //     if (sock != null) {
  //       address = sock.localAddress;
  //     }
  //   }
  //   return address;
  // }

  @override
  String toString() {
    Type clazz = runtimeType;
    return '<$clazz remote="$remoteAddress" local="$localAddress">\n\t'
        '${getChannel()}\n</$clazz>';
  }

  @override
  Future<void> close() async {
    // stop state machine
    setStateMachine(null);
    // close channel
    setChannel(null);
  }

  Future<void> start() async {
    ConnectionStateMachine machine = createStateMachine();
    await machine.start();
    setStateMachine(machine);
  }

  Future<void> stop() async {
    setStateMachine(null);
    setChannel(null);
  }

  //
  //  I/O
  //

  @override
  Future<void> onReceivedData(Uint8List data) async {
    _lastReceivedTime = DateTime.now();  // update received time
    await delegate?.onConnectionReceived(data, this);
  }

  // protected
  Future<int> doSend(Uint8List src, SocketAddress? destination) async {
    Channel? sock = await channel;
    if (sock == null || !sock.isAlive) {
      assert(false, 'socket channel lost: $sock');
      return -1;
    } else if (destination == null) {
      assert(false, 'remote address should not empty');
      return -1;
    }
    int sent = await sock.send(src, destination);
    if (sent > 0) {
      // update sent time
      _lastSentTime = DateTime.now();
    }
    return sent;
  }

  @override
  Future<int> sendData(Uint8List data) async {
    // try to send data
    IOError? error;
    int sent = -1;
    try {
      sent = await doSend(data, remoteAddress);
      if (sent < 0) { // == -1
        throw SocketException('failed to send data: ${data.length} byte(s) to $remoteAddress');
      }
    } on IOException catch (ex) {
      // print(e);
      error = IOError(ex);
      // socket error, close current channel
      setChannel(null);
    }
    // callback
    if (error == null) {
      await delegate?.onConnectionSent(sent, data, this);
    } else {
      await delegate?.onConnectionFailed(error, data, this);
    }
    return sent;
  }

  //
  //  States
  //

  @override
  ConnectionState? get state => getStateMachine()?.currentState;

  @override
  Future<void> tick(DateTime now, int elapsed) async =>
      await getStateMachine()?.tick(now, elapsed);

  //
  //  Timed
  //

  @override
  DateTime? get lastSentTime => _lastSentTime;

  @override
  DateTime? get lastReceivedTime => _lastReceivedTime;

  @override
  bool isSentRecently(DateTime now) {
    int last = _lastSentTime?.millisecondsSinceEpoch ?? 0;
    return now.millisecondsSinceEpoch <= last + kExpires;
  }

  @override
  bool isReceivedRecently(DateTime now) {
    int last = _lastReceivedTime?.millisecondsSinceEpoch ?? 0;
    return now.millisecondsSinceEpoch <= last + kExpires;
  }

  @override
  bool isNotReceivedLongTimeAgo(DateTime now) {
    int last = _lastReceivedTime?.millisecondsSinceEpoch ?? 0;
    return now.millisecondsSinceEpoch > last + (kExpires << 3);
  }

  //
  //  Events
  //

  @override
  Future<void> enterState(ConnectionState? next, ConnectionStateMachine ctx, DateTime now) async {

  }

  @override
  Future<void> exitState(ConnectionState? previous, ConnectionStateMachine ctx, DateTime now) async {
    ConnectionState? current = ctx.currentState;
    // if current == 'ready'
    if (current?.index == ConnectionStateOrder.ready.index) {
      // if preparing == 'preparing'
      if (previous?.index == ConnectionStateOrder.preparing.index) {
        // connection state changed from 'preparing' to 'ready',
        // set times to expired soon.
        int soon = now.millisecondsSinceEpoch - (kExpires >> 1);
        int st = _lastSentTime?.millisecondsSinceEpoch ?? 0;
        if (st < soon) {
          _lastSentTime = DateTime.fromMillisecondsSinceEpoch(soon);
        }
        int rt = _lastReceivedTime?.millisecondsSinceEpoch ?? 0;
        if (rt < soon) {
          _lastReceivedTime = DateTime.fromMillisecondsSinceEpoch(soon);
        }
      }
    }
    // callback
    await delegate?.onConnectionStateChanged(previous, current, this);
  }

  @override
  Future<void> pauseState(ConnectionState? current, ConnectionStateMachine ctx, DateTime now) async {

  }

  @override
  Future<void> resumeState(ConnectionState? current, ConnectionStateMachine ctx, DateTime now) async {

  }

}


/// Active connection for client
class ActiveConnection extends BaseConnection {
  ActiveConnection(Hub hub, super.sock, {super.remote, super.local}) {
    _hubRef = WeakReference(hub);
  }

  late final WeakReference<Hub> _hubRef;

  // private
  Hub? get hub => _hubRef.target;

  bool _running = false;

  @override
  Future<void> start() async {
    await super.start();
    // start a background thread for calling 'run()'
    await _forceStop();
    _running = true;
    /*await */run();
  }

  Future<void> _forceStop() async {
    if (_running) {
      _running = false;
      await Runner.sleep(milliseconds: 2048);
    }
  }

  @override
  Future<void> stop() async {
    await _forceStop();
    await super.stop();
  }

  @override
  bool get isClosed => getStateMachine() == null;

  // protected
  Future<void> run() async {
    int lastTime = DateTime.now().millisecondsSinceEpoch;
    int interval = 16000;
    int now;
    Channel? sock;
    while (!isClosed) {
      await Runner.sleep(milliseconds: 1000);
      // check time interval
      now = DateTime.now().millisecondsSinceEpoch;
      if (now < lastTime + interval) {
        continue;
      }
      lastTime = now;
      if (interval < 256) {
        interval <<= 1;
      }
      // check socket channel
      sock = getChannel();
      if (sock == null || sock.isClosed) {
        // get new socket channel via hub
        sock = await hub?.open(remote: remoteAddress, local: localAddress);
        if (sock != null) {
          setChannel(sock);
        }
      } else if (sock.isAlive) {
        // socket channel is normal
        interval = 16;
      } else {
        await sock.close();
      }
    }
  }

}
