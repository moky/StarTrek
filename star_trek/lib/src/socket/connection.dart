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

  static Duration kExpires = Duration(seconds: 16);

  WeakReference<ConnectionDelegate>? _delegateRef;

  WeakReference<Channel>? _channelRef;

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
    if (sock != null) {
      _channelRef = WeakReference(sock);
    // } else {
    //   _channelRef = null;
    }
    // 2. close old channel
    if (old == null || identical(old, sock)) {} else {
      try {
        await old.close();
      } catch (e) {
        // await delegate?.onConnectionError(IOError(e), this);
      }
    }
  }

  //
  //  Flags
  //

  @override
  bool get isClosed {
    if (_channelRef == null) {
      // initializing
      return false;
    }
    return channel?.isClosed != false;
  }

  @override
  bool get isBound => channel?.isBound == true;

  @override
  bool get isConnected => channel?.isConnected == true;

  @override
  bool get isAlive => (!isClosed) && (isConnected || isBound);
  // bool get isAlive => channel?.isAlive == true;

  @override
  bool get isAvailable => channel?.isAvailable == true;

  @override
  bool get isVacant => channel?.isVacant == true;

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

  /// Get channel from hub
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
      await setChannel(null);
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
  Future<void> tick(DateTime now, Duration elapsed) async {
    if (_channelRef == null) {
      // not initialized
      return;
    }
    // drive state machine forward
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
    DateTime? lastTime = _lastSentTime;
    if (lastTime == null) {
      return false;
    }
    // return now <= last + kExpires;
    return lastTime.add(kExpires).isAfter(now);
  }

  @override
  bool isReceivedRecently(DateTime now) {
    DateTime? lastTime = _lastSentTime;
    if (lastTime == null) {
      return false;
    }
    // return now <= last + kExpires;
    return lastTime.add(kExpires).isAfter(now);
  }

  @override
  bool isNotReceivedLongTimeAgo(DateTime now) {
    DateTime? lastTime = _lastSentTime;
    if (lastTime == null) {
      return false;
    }
    // return now > last + (kExpires << 3);
    return lastTime.add(kExpires * 8).isBefore(now);
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
    int index = current?.index ?? -1;
    // if current == 'ready'
    if (index == ConnectionStateOrder.ready.index) {
      // if preparing == 'preparing'
      if (previous?.index == ConnectionStateOrder.preparing.index) {
        // connection state changed from 'preparing' to 'ready',
        // set times to expired soon.
        DateTime soon = now.subtract(kExpires ~/ 2);
        // int soon = now - (kExpires >> 1);
        DateTime? st = _lastSentTime;
        if (st == null || st.isBefore(soon)) {
          _lastSentTime = soon;
        }
        DateTime? rt = _lastReceivedTime;
        if (rt == null || rt.isBefore(soon)) {
          _lastReceivedTime = soon;
        }
      }
    }
    // callback
    await delegate?.onConnectionStateChanged(previous, current, this);
    // if current == 'error'
    if (index == ConnectionStateOrder.error.index) {
      // remove channel when error
      await setChannel(null);
    }
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

  // // private
  // Hub? get hub => _hubRef?.target;

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
    Duration sleeping = Duration(milliseconds: 1000);
    int expired = 0;
    int lastTime = 0;
    int interval = 8000;
    int now;
    Channel? sock;
    while (true) {
      await Runner.sleep(sleeping);
      if (isClosed) {
        break;
      }
      now = DateTime.now().millisecondsSinceEpoch;
      try {
        sock = channel;
        if (sock == null || sock.isClosed) {
          // first time to try connecting (lastTime == 0)?
          // or connection lost, then try to reconnect again.
          // check time interval for the trying here
          if (now < lastTime + interval) {
            continue;
          } else {
            // update last connect time
            lastTime = now;
          }
          // get new socket channel via hub
          Hub? hub = _hubRef?.target;
          if (hub == null) {
            assert(false, 'hub not found: $localAddress -> $remoteAddress');
            break;
          }
          // try to open a new socket channel from the hub.
          // the returned socket channel is opened for connecting,
          // but maybe failed,
          // so set an expired time to close it after timeout;
          // if failed to open a new socket channel,
          // then extend the time interval for next trying.
          sock = await openChannel(hub);
          if (sock != null) {
            // connect timeout after 2 minutes
            expired = now + 128000;
          } else if (interval < 128000) {
            interval <<= 1;
          }
        } else if (sock.isAlive) {
          // socket channel is normal, reset the time interval here.
          // this will work when the current connection lost
          interval = 8000;
        } else if (0 < expired && expired < now) {
          // connect timeout
          await sock.close();
        }
      } catch (e) {
        // print('[Socket] active connection error: $e, $st');
        var error = IOError(e);
        delegate?.onConnectionError(error, this);
      }
    }
    // connection exists
    print('[Socket] active connection exits: $remoteAddress');
  }

}
