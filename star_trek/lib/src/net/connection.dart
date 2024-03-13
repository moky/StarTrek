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

import '../fsm/ticker.dart';
import '../nio/address.dart';
import '../nio/exception.dart';

import 'state.dart';


abstract interface class Connection implements Ticker {

  //
  //  Flags
  //
  bool get isClosed;     // !isOpen()
  bool get isBound;
  bool get isConnected;

  bool get isAlive;      // isOpen && (isConnected || isBound)

  /// ready for reading
  bool get isAvailable;  // isAlive
  /// ready for writing
  bool get isVacant;     // isAlive

  SocketAddress? get localAddress;
  SocketAddress? get remoteAddress;

  ConnectionState? get state;

  ///  Send data
  ///
  /// @param data - outgo data package
  /// @return count of bytes sent, probably zero when it's non-blocking mode
  Future<int> sendData(Uint8List data);

  ///  Process received data
  ///
  /// @param data - received data
  Future<void> onReceivedData(Uint8List data);

  ///  Close the connection
  Future<void> close();

}


abstract interface class ConnectionDelegate {

  ///  Called when connection state is changed
  ///
  /// @param previous   - old state
  /// @param current    - new state
  /// @param connection - current connection
  Future<void> onConnectionStateChanged(ConnectionState? previous, ConnectionState? current, Connection connection);

  ///  Called when connection received data
  ///
  /// @param data        - received data package
  /// @param connection  - current connection
  Future<void> onConnectionReceived(Uint8List data, Connection connection);

  ///  Called after data sent via the connection
  ///
  /// @param sent        - length of sent bytes
  /// @param data        - outgo data package
  /// @param connection  - current connection
  Future<void> onConnectionSent(int sent, Uint8List data, Connection connection);

  ///  Called when failed to send data via the connection
  ///
  /// @param error       - error message
  /// @param data        - outgo data package
  /// @param connection  - current connection
  Future<void> onConnectionFailed(IOError error, Uint8List data, Connection connection);

  ///  Called when connection (receiving) error
  ///
  /// @param error       - error message
  /// @param connection  - current connection
  Future<void> onConnectionError(IOError error, Connection connection);

}


///  Connection with sent/received time
abstract interface class TimedConnection {

  DateTime? get lastSentTime;

  DateTime? get lastReceivedTime;

  bool isSentRecently(DateTime now);

  bool isReceivedRecently(DateTime now);

  bool isNotReceivedLongTimeAgo(DateTime now);

}
