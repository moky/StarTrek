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

import '../fsm/runner.dart';
import '../net/state.dart';
import '../nio/address.dart';
import 'ship.dart';


///  Star Worker
///  ~~~~~~~~~~~
///
///  Processor for Star Ships
abstract interface class Docker implements Processor {

  bool get isClosed;  // connection.isClosed
  bool get isAlive;   // connection.isAlive
  int get status;     // connection.state

  SocketAddress? get remoteAddress;
  SocketAddress? get localAddress;

  ///  Pack data to an outgo ship (with normal priority), and
  ///  append to the waiting queue for sending out
  ///
  /// @param payload  - data to be sent
  /// @return false on error
  bool sendData(Uint8List payload);

  ///  Append outgo ship (carrying data package, with priority)
  ///  to the waiting queue for sending out
  ///
  /// @param ship - outgo ship carrying data package/fragment
  /// @return false on duplicated
  bool sendShip(Departure ship);

  ///  Called when received data
  ///
  /// @param data   - received data package
  void processReceived(Uint8List data);

  ///  Send 'PING' for keeping connection alive
  void heartbeat();

  ///  Clear all expired tasks
  void purge([DateTime? now]);

  ///  Close connection for this docker
  void close();

}

abstract class DockerStatus {

  static const int kError     = -1;
  static const int kInit      = 0;
  static const int kPreparing = 1;
  static const int kReady     = 2;

  static int getStatus(ConnectionState? state) {
    if (state == null) {
      return kError;
    } else if (state.index == ConnectionStateOrder.kReady.index
        || state.index == ConnectionStateOrder.kExpired.index
        || state.index == ConnectionStateOrder.kMaintaining.index) {
      return kReady;
    } else if (state.index == ConnectionStateOrder.kPreparing.index) {
      return kPreparing;
    } else if (state.index == ConnectionStateOrder.kError.index) {
      return kError;
    } else {
      return kInit;
    }
  }

}


abstract interface class DockerDelegate {

  ///  Callback when new package received
  ///
  /// @param arrival     - income data package container
  /// @param docker      - connection docker
  void onDockerReceived(Arrival arrival, Docker docker);

  ///  Callback when package sent
  ///
  /// @param departure   - outgo data package container
  /// @param docker      - connection docker
  void onDockerSent(Departure departure, Docker docker);

  ///  Callback when failed to send package
  ///
  /// @param error       - error message
  /// @param departure   - outgo data package container
  /// @param docker      - connection docker
  void onDockerFailed(IOError error, Departure departure, Docker docker);

  ///  Callback when connection error
  ///
  /// @param error       - error message
  /// @param departure   - outgo data package container
  /// @param docker      - connection docker
  void onDockerError(IOError error, Departure departure, Docker docker);

  ///  Callback when connection status changed
  ///
  /// @param previous    - old status
  /// @param current     - new status
  /// @param docker      - connection docker
  void onDockerStatusChanged(int previous, int current, Docker docker);

}
