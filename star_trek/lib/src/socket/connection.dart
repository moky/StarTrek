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
  BaseConnection({super.remote, super.local});

  static int kExpires = 16 * 1000;  // 16 seconds

  WeakReference<ConnectionDelegate>? _delegateRef;

  WeakReference<Channel>? _channelRef;
  bool? _closed;

  // active times
  DateTime? _lastSentTime;
  DateTime? _lastReceivedTime;

  // connection state machine
  ConnectionStateMachine? _fsm;

  // delegate for handling connection events
  ConnectionDelegate? get delegate => _delegateRef?.target;
  set delegate(ConnectionDelegate? gate) =>
      _delegateRef = gate == null ? null : WeakReference(gate);

  //
  //  State Machine
  //

  // protected
  ConnectionStateMachine? get stateMachine => _fsm;
  // private
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

  //
  //  Channel
  //

  Channel? get channel => _channelRef?.target;

  // protected
  Future<void> setChannel(Channel? sock) async {
    // 1. replace with new channel
    Channel? old = _channelRef?.target;
    if (sock == null) {
      _channelRef = null;
      _closed = true;
    } else {
      _channelRef = WeakReference(sock);
      _closed = false;  // sock.isClosed;
    }
    // 2. close old channel
    if (old == null || identical(old, sock)) {} else {
      await old.close();
    }
  }

  //
  //  Flags
  //

  @override
  bool get isClosed => _closed != null && channel?.isClosed != false;

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
    // stop state machine
    await setStateMachine(null);
    // close channel
    await setChannel(null);
  }

  @override
  Future<void> start(Hub hub) async {
    // 1. get channel from hub
    await openChannel(hub);
    // 2. start state machine
    await startMachine();
  }

  // protected
  Future<void> startMachine() async {
    ConnectionStateMachine machine = createStateMachine();
    await setStateMachine(machine);
    await machine.start();
  }

  // protected
  Future<Channel?> openChannel(Hub hub) async {
    Channel? sock = await hub.open(remote: remoteAddress, local: localAddress);
    if (sock == null) {
      assert(false, 'failed to open channel: remote=$remoteAddress, local=$localAddress');
    } else {
      await setChannel(sock);
    }
    return sock;
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
  ConnectionState? get state => stateMachine?.currentState;

  @override
  Future<void> tick(DateTime now, int elapsed) async {
    if (_closed == null) {
      // not initialized
      return;
    }
    await stateMachine?.tick(now, elapsed);
  }

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
  ActiveConnection({super.remote, super.local});

  WeakReference<Hub>? _hubRef;

  @override
  bool get isClosed => stateMachine == null;

  @override
  Future<void> start(Hub hub) async {
    _hubRef = WeakReference(hub);
    // 1. start state machine
    await startMachine();
    // 2. start a background thread to check channel
    /*await */run();
  }

  Future<void> run() async {
    int expired = 0;
    int lastTime = 0;
    int interval = 16000;
    int now;
    Channel? sock;
    while (!isClosed) {
      await Runner.sleep(milliseconds: 1000);
      //
      //  1. check time interval
      //
      now = DateTime.now().millisecondsSinceEpoch;
      if (now < lastTime + interval) {
        continue;
      }
      lastTime = now;
      if (interval < 256000) {
        interval <<= 1;
      }
      //
      //  2. check socket channel
      //
      sock = channel;
      if (sock == null || sock.isClosed) {
        // get new socket channel via hub
        Hub? hub = _hubRef?.target;
        if (hub == null) {
          assert(false, 'hub lost');
          break;
        }
        sock = await openChannel(hub);
        if (sock == null) {
          print('[Socket] failed to open channel: $localAddress -> $remoteAddress');
        } else {
          // connect timeout after 2 minutes
          expired = now + 128 * 1000;
        }
      } else if (sock.isAlive) {
        // socket channel is normal
        interval = 16000;
      } else if (0 < expired && expired < now) {
        // connect timeout
        await sock.close();
      }
    }
  }

}
