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
import '../nio/exception.dart';
import 'ship.dart';


///  Star Worker
///  ~~~~~~~~~~~
///
///  Processor for Star Ships
abstract interface class Docker implements Processor {

  bool get isClosed;        // connection.isClosed
  bool get isAlive;         // connection.isAlive
  DockerStatus get status;  // connection.state

  SocketAddress? get remoteAddress;
  SocketAddress? get localAddress;

  ///  Pack data to an outgo ship (with normal priority), and
  ///  append to the waiting queue for sending out
  ///
  /// @param payload  - data to be sent
  /// @return false on error
  Future<bool> sendData(Uint8List payload);

  ///  Append outgo ship (carrying data package, with priority)
  ///  to the waiting queue for sending out
  ///
  /// @param ship - outgo ship carrying data package/fragment
  /// @return false on duplicated
  Future<bool> sendShip(Departure ship);

  ///  Called when received data
  ///
  /// @param data   - received data package
  Future<void> processReceived(Uint8List data);

  ///  Send 'PING' for keeping connection alive
  Future<void> heartbeat();

  ///  Clear all expired tasks
  void purge([DateTime? now]);

  ///  Close connection for this docker
  void close();

}

enum DockerStatus {
  init,
  preparing,
  ready,
  error;

  //
  //  State Convert
  //
  static DockerStatus getStatus(ConnectionState? state) {
    if (state == null) {
      return error;
    } else if (state.index == ConnectionStateOrder.ready.index
        || state.index == ConnectionStateOrder.expired.index
        || state.index == ConnectionStateOrder.maintaining.index) {
      return ready;
    } else if (state.index == ConnectionStateOrder.preparing.index) {
      return preparing;
    } else if (state.index == ConnectionStateOrder.error.index) {
      return error;
    } else {
      return init;
    }
  }

}


abstract interface class DockerDelegate {

  ///  Callback when new package received
  ///
  /// @param arrival     - income data package container
  /// @param docker      - connection docker
  Future<void> onDockerReceived(Arrival arrival, Docker docker);

  ///  Callback when package sent
  ///
  /// @param departure   - outgo data package container
  /// @param docker      - connection docker
  Future<void> onDockerSent(Departure departure, Docker docker);

  ///  Callback when failed to send package
  ///
  /// @param error       - error message
  /// @param departure   - outgo data package container
  /// @param docker      - connection docker
  Future<void> onDockerFailed(IOError error, Departure departure, Docker docker);

  ///  Callback when connection error
  ///
  /// @param error       - error message
  /// @param departure   - outgo data package container
  /// @param docker      - connection docker
  Future<void> onDockerError(IOError error, Departure departure, Docker docker);

  ///  Callback when connection status changed
  ///
  /// @param previous    - old status
  /// @param current     - new status
  /// @param docker      - connection docker
  Future<void> onDockerStatusChanged(DockerStatus previous, DockerStatus current, Docker docker);

}
