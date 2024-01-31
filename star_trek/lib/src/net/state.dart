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
import '../fsm/base.dart';
import '../fsm/machine.dart';
import 'connection.dart';


/*
 *    Finite States
 *    ~~~~~~~~~~~~~
 *
 *             //===============\\          (Start)          //=============\\
 *             ||               || ------------------------> ||             ||
 *             ||    Default    ||                           ||  Preparing  ||
 *             ||               || <------------------------ ||             ||
 *             \\===============//         (Timeout)         \\=============//
 *                                                               |       |
 *             //===============\\                               |       |
 *             ||               || <-----------------------------+       |
 *             ||     Error     ||          (Error)                 (Connected
 *             ||               || <-----------------------------+   or bound)
 *             \\===============//                               |       |
 *                 A       A                                     |       |
 *                 |       |            //===========\\          |       |
 *                 (Error) +----------- ||           ||          |       |
 *                 |                    ||  Expired  || <--------+       |
 *                 |       +----------> ||           ||          |       |
 *                 |       |            \\===========//          |       |
 *                 |       (Timeout)           |         (Timeout)       |
 *                 |       |                   |                 |       V
 *             //===============\\     (Sent)  |             //=============\\
 *             ||               || <-----------+             ||             ||
 *             ||  Maintaining  ||                           ||    Ready    ||
 *             ||               || ------------------------> ||             ||
 *             \\===============//       (Received)          \\=============//
 *
 */


///  Connection State Machine
///  ~~~~~~~~~~~~~~~~~~~~~~~~
class ConnectionStateMachine
    extends BaseMachine<ConnectionStateMachine, ConnectionStateTransition, ConnectionState>
    implements MachineContext {
  ConnectionStateMachine(Connection connection) : _connectionRef = WeakReference(connection) {
    // init states
    ConnectionStateBuilder builder = createStateBuilder();
    addState(builder.getDefaultState());
    addState(builder.getPreparingState());
    addState(builder.getReadyState());
    addState(builder.getExpiredState());
    addState(builder.getMaintainingState());
    addState(builder.getErrorState());
  }

  final WeakReference<Connection> _connectionRef;

  Connection? get connection => _connectionRef.target;

  @override
  ConnectionStateMachine get context => this;

  // protected
  ConnectionStateBuilder createStateBuilder() =>
      ConnectionStateBuilder(StateTransitionBuilder());

}


///  Connection State Transition
///  ~~~~~~~~~~~~~~~~~~~~~~~~~~~
class ConnectionStateTransition extends BaseTransition<ConnectionStateMachine> {
  ConnectionStateTransition(ConnectionStateOrder order, this.eval) : super(order.index);

  final StateEvaluate eval;

  @override
  Future<bool> evaluate(ConnectionStateMachine ctx, DateTime now) async => eval(ctx, now);

}

typedef StateEvaluate = Future<bool> Function(ConnectionStateMachine ctx, DateTime now);

class StateTransitionBuilder {

  // Default -> Preparing
  getDefaultPreparingTransition() => ConnectionStateTransition(
    ConnectionStateOrder.kPreparing, (ctx, now) async {
      Connection? conn = ctx.connection;
      // connection started? change state to 'preparing'
      return !(conn == null || conn.isClosed);
    },
  );

  // Preparing -> Ready
  getPreparingReadyTransition() => ConnectionStateTransition(
    ConnectionStateOrder.kReady, (ctx, now) async {
      Connection? conn = ctx.connection;
      // connected or bound, change state to 'ready'
      return conn != null && conn.isAlive;
    },
  );

  // Preparing -> Default
  getPreparingDefaultTransition() => ConnectionStateTransition(
    ConnectionStateOrder.kDefault, (ctx, now) async {
      Connection? conn = ctx.connection;
      // connection stopped, change state to 'not_connect'
      return conn == null || conn.isClosed;
    },
  );

  // Ready -> Expired
  getReadyExpiredTransition() => ConnectionStateTransition(
    ConnectionStateOrder.kExpired, (ctx, now) async {
      Connection? conn = ctx.connection;
      if (conn == null || !conn.isAlive) {
        return false;
      }
      TimedConnection timed = conn as TimedConnection;
      // connection still alive, but
      // long time no response, change state to 'maintain_expired'
      return !timed.isReceivedRecently(now);
    },
  );

  // Ready -> Error
  getReadyErrorTransition() => ConnectionStateTransition(
    ConnectionStateOrder.kError, (ctx, now) async {
      Connection? conn = ctx.connection;
      // connection lost, change state to 'error'
      return conn == null || !conn.isAlive;
    },
  );

  // Expired -> Maintaining
  getExpiredMaintainingTransition() => ConnectionStateTransition(
    ConnectionStateOrder.kMaintaining, (ctx, now) async {
      Connection? conn = ctx.connection;
      if (conn == null || !conn.isAlive) {
        return false;
      }
      TimedConnection timed = conn as TimedConnection;
      // connection still alive, and
      // sent recently, change state to 'maintaining'
      return timed.isSentRecently(now);
    },
  );

  // Expired -> Error
  getExpiredErrorTransition() => ConnectionStateTransition(
    ConnectionStateOrder.kError, (ctx, now) async {
      Connection? conn = ctx.connection;
      if (conn == null || !conn.isAlive) {
        return true;
      }
      TimedConnection timed = conn as TimedConnection;
      // connection lost, or
      // long long time no response, change state to 'error'
      return timed.isNotReceivedLongTimeAgo(now);
    },
  );

  // Maintaining -> Ready
  getMaintainingReadyTransition() => ConnectionStateTransition(
    ConnectionStateOrder.kReady, (ctx, now) async {
      Connection? conn = ctx.connection;
      if (conn == null || !conn.isAlive) {
        return false;
      }
      TimedConnection timed = conn as TimedConnection;
      // connection still alive, and
      // received recently, change state to 'ready'
      return timed.isReceivedRecently(now);
    },
  );

  // Maintaining -> Expired
  getMaintainingExpiredTransition() => ConnectionStateTransition(
    ConnectionStateOrder.kExpired, (ctx, now) async {
      Connection? conn = ctx.connection;
      if (conn == null || !conn.isAlive) {
        return false;
      }
      TimedConnection timed = conn as TimedConnection;
      // connection still alive, but
      // long time no sending, change state to 'maintain_expired'
      return !timed.isSentRecently(now);
    },
  );

  // Maintaining -> Error
  getMaintainingErrorTransition() => ConnectionStateTransition(
    ConnectionStateOrder.kError, (ctx, now) async {
      Connection? conn = ctx.connection;
      if (conn == null || !conn.isAlive) {
        return true;
      }
      TimedConnection timed = conn as TimedConnection;
      // connection lost, or
      // long long time no response, change state to 'error'
      return timed.isNotReceivedLongTimeAgo(now);
    },
  );

  // Error -> Default
  getErrorDefaultTransition() => ConnectionStateTransition(
    ConnectionStateOrder.kDefault, (ctx, now) async {
      Connection? conn = ctx.connection;
      if (conn == null || !conn.isAlive) {
        return false;
      }
      TimedConnection timed = conn as TimedConnection;
      // connection still alive, and
      // can receive data during this state
      ConnectionState? current = ctx.currentState;
      DateTime? enter = current?.enterTime;
      DateTime? last = timed.lastReceivedTime;
      return enter != null && last != null && enter.isBefore(last);
    },
  );

}


///  Connection State Delegate
///  ~~~~~~~~~~~~~~~~~~~~~~~~~
///
///  callback when connection state changed
abstract interface class ConnectionStateDelegate
    implements MachineDelegate<ConnectionStateMachine, ConnectionStateTransition, ConnectionState> {}

class ConnectionStateOrder {
  ConnectionStateOrder(this.index, this.name);

  final int index;
  final String name;

  @override
  String toString() => '<$runtimeType index="$index" name="$name"/>';

  static int _next = 0;
  static _create(String name) => ConnectionStateOrder(_next++, name);

  //
  //  Connection State Orders
  //
  static final kDefault     = _create('DEFAULT');
  static final kPreparing   = _create('PREPARING');
  static final kReady       = _create('READY');
  static final kMaintaining = _create('MAINTAINING');
  static final kExpired     = _create('EXPIRED');
  static final kError       = _create('ERROR');

}

///  Connection State
///  ~~~~~~~~~~~~~~~~
///
///  Defined for indicating connection state
///
///      DEFAULT     - 'initialized', or sent timeout
///      PREPARING   - connecting or binding
///      READY       - got response recently
///      EXPIRED     - long time, needs maintaining (still connected/bound)
///      MAINTAINING - sent 'PING', waiting for response
///      ERROR       - long long time no response, connection lost
class ConnectionState extends BaseState<ConnectionStateMachine, ConnectionStateTransition> {
  ConnectionState(ConnectionStateOrder order) : super(order.index) {
    name = order.name;
  }

  late final String name;
  DateTime? _enterTime;

  DateTime? get enterTime => _enterTime;

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (other is ConnectionState) {
      if (identical(this, other)) {
        // same object
        return true;
      }
      return index == other.index;
    } else if (other is ConnectionStateOrder) {
      return index == other.index;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => index;

  @override
  Future<void> onEnter(State<ConnectionStateMachine, ConnectionStateTransition>? previous,
      ConnectionStateMachine ctx, DateTime now) async {
    _enterTime = now;
  }

  @override
  Future<void> onExit(State<ConnectionStateMachine, ConnectionStateTransition>? next,
      ConnectionStateMachine ctx, DateTime now) async {
    _enterTime = null;
  }

  @override
  Future<void> onPause(ConnectionStateMachine ctx, DateTime now) async {

  }

  @override
  Future<void> onResume(ConnectionStateMachine ctx, DateTime now) async {

  }

}

///  State Builder
///  ~~~~~~~~~~~~~
class ConnectionStateBuilder {
  ConnectionStateBuilder(this.stb);

  final StateTransitionBuilder stb;

  // Connection not started yet
  getDefaultState() {
    ConnectionState state = ConnectionState(ConnectionStateOrder.kDefault);
    // Default -> Preparing
    state.addTransition(stb.getDefaultPreparingTransition());
    return state;
  }

  // Connection started, preparing to connect/bind
  getPreparingState() {
    ConnectionState state = ConnectionState(ConnectionStateOrder.kPreparing);
    // Preparing -> Ready
    state.addTransition(stb.getPreparingReadyTransition());
    // Preparing -> Default
    state.addTransition(stb.getPreparingDefaultTransition());
    return state;
  }

  // Normal state of connection
  getReadyState() {
    ConnectionState state = ConnectionState(ConnectionStateOrder.kReady);
    // Ready -> Expired
    state.addTransition(stb.getReadyExpiredTransition());
    // Ready -> Error
    state.addTransition(stb.getReadyErrorTransition());
    return state;
  }

  // Long time no response, need maintaining
  getExpiredState() {
    ConnectionState state = ConnectionState(ConnectionStateOrder.kExpired);
    // Expired -> Maintaining
    state.addTransition(stb.getExpiredMaintainingTransition());
    // Expired -> Error
    state.addTransition(stb.getExpiredErrorTransition());
    return state;
  }

  // Heartbeat sent, waiting response
  getMaintainingState() {
    ConnectionState state = ConnectionState(ConnectionStateOrder.kMaintaining);
    // Maintaining -> Ready
    state.addTransition(stb.getMaintainingReadyTransition());
    // Maintaining -> Expired
    state.addTransition(stb.getMaintainingExpiredTransition());
    // Maintaining -> Error
    state.addTransition(stb.getMaintainingErrorTransition());
    return state;
  }

  // Connection lost
  getErrorState() {
    ConnectionState state = ConnectionState(ConnectionStateOrder.kError);
    // Error -> Default
    state.addTransition(stb.getErrorDefaultTransition());
    return state;
  }

}
