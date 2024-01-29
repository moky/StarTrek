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

import '../net/channel.dart';
import '../net/connection.dart';
import '../net/hub.dart';
import '../net/state.dart';
import '../nio/address.dart';
import '../type/pair.dart';


class BaseConnection extends AddressPairObject
    implements Connection, TimedConnection, ConnectionStateDelegate {
  BaseConnection(super.remoteAddress, super.localAddress, Channel sock) {
    _channelRef = WeakReference(sock);
  }

  static int kExpires = 16 * 1000;  // 16 seconds

  WeakReference<Channel>? _channelRef;
  WeakReference<ConnectionDelegate>? _delegateRef;

  // active times
  DateTime? _lastSentTime;
  DateTime? _lastReceivedTime;

  // connection state machine
  StateMachine? _fsm;

  // protected
  void finalize() {
    // make sure the relative channel is closed
    channel = null;
    stateMachine = null;
  }

  Channel? get channel => _channelRef?.target;
  set channel(Channel? newChannel) {
    // 1. replace with new channel
    Channel? oldChannel = _channelRef?.target;
    _channelRef = newChannel == null ? null : WeakReference(newChannel);
    // 2. close old channel
    if (oldChannel != null && oldChannel != newChannel) {
      if (oldChannel.isConnected) {
        oldChannel.disconnect();
      }
    }
  }

  // delegate for handling connection events
  ConnectionDelegate? get delegate => _delegateRef?.target;
  set delegate(ConnectionDelegate? gate) =>
      _delegateRef = gate == null ? null : WeakReference(gate);

  // protected
  StateMachine? get stateMachine => _fsm;
  // private
  set stateMachine(StateMachine? newMachine) {
    // 1. replace with new machine
    StateMachine? oldMachine = _fsm;
    _fsm = newMachine;
    // 2. stop old machine
    if (oldMachine != null && oldMachine != newMachine) {
      oldMachine.stop();
    }
  }
  // protected
  StateMachine createStateMachine() {
    StateMachine machine = StateMachine(this);
    machine.delegate = this;
    return machine;
  }

  @override
  bool get isClosed => channel?.isClosed != false;

  @override
  bool get isBound => channel?.isBound == true;

  @override
  bool get isConnected => channel?.isConnected == true;

  @override
  bool get isAlive => (!isClosed) && (isConnected || isBound);
  // bool get isAlive => channel?.isAlive == true;

  @override
  String toString() {
    Type clazz = runtimeType;
    return '<$clazz remote="$remoteAddress" local="$localAddress">\n\t'
        '$channel\n</$clazz>';
  }

  @override
  Future<void> close() async {
    channel = null;
    stateMachine = null;
  }

  Future<void> start() async {
    StateMachine machine = createStateMachine();
    stateMachine = machine;
    await machine.start();
  }

  Future<void> stop() async {
    channel = null;
    stateMachine = null;
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
    Channel? sock = channel;
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
        throw IOException('failed to send data: ${data.length} byte(s) to $remoteAddress');
      }
    } on IOException catch (e) {
      // print(e);
      error = IOError(e);
      // socket error, close current channel
      channel = null;
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
  ConnectionState? get state => stateMachine?.currentState;

  @override
  Future<void> tick(DateTime now, int elapsed) async =>
      await stateMachine?.tick(now, elapsed);

  //
  //  Timed
  //

  @override
  DateTime? get lastReceivedTime => _lastSentTime;

  @override
  DateTime? get lastSentTime => _lastReceivedTime;

  @override
  bool isSentRecently(DateTime now) =>
      now.millisecondsSinceEpoch <= (_lastSentTime?.millisecondsSinceEpoch ?? 0) + kExpires;

  @override
  bool isReceivedRecently(DateTime now) =>
      now.millisecondsSinceEpoch <= (_lastReceivedTime?.millisecondsSinceEpoch ?? 0) + kExpires;

  @override
  bool isNotReceivedLongTimeAgo(DateTime now) =>
      now.millisecondsSinceEpoch > (_lastReceivedTime?.millisecondsSinceEpoch ?? 0) + (kExpires << 3);

  //
  //  Events
  //

  @override
  Future<void> enterState(ConnectionState? next, StateMachine ctx, DateTime now) async {

  }

  @override
  Future<void> exitState(ConnectionState? previous, StateMachine ctx, DateTime now) async {
    ConnectionState? current = ctx.currentState;
    // if current == 'ready'
    if (current?.index == ConnectionStateOrder.kReady.index) {
      // if preparing == 'preparing'
      if (previous?.index == ConnectionStateOrder.kPreparing.index) {
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
  Future<void> pauseState(ConnectionState? current, StateMachine ctx, DateTime now) async {

  }

  @override
  Future<void> resumeState(ConnectionState? current, StateMachine ctx, DateTime now) async {

  }

}


/// Active connection for client
class ActiveConnection extends BaseConnection {
  ActiveConnection(super.remoteAddress, super.localAddress, super.sock, Hub hub) {
    _hubRef = WeakReference(hub);
  }

  late final WeakReference<Hub> _hubRef;

  // private
  Hub? get hub => _hubRef.target;

  @override
  bool get isClosed => stateMachine != null;

  @override
  Channel? get channel {
    Channel? sock = _channelRef?.target;
    if (sock == null || sock.isClosed) {
      if (stateMachine == null) {
        // closed (not start yet)
        return null;
      }
      // get new channel via hub
      sock = hub?.open(remote: remoteAddress, local: localAddress);
      // assert(sock != null, 'failed to open channel: $remoteAddress, $localAddress');
      channel = sock;
    }
    return sock;
  }

}
