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


///  Star Ship
///  ~~~~~~~~~
///
///  Container carrying data package
abstract interface class Ship {

  ///  Get ID for this Ship
  ///
  /// @return SN
  dynamic get sn;

  ///  Update sent time
  ///
  /// @param now - current time
  void touch(DateTime now);

  ///  Check ship state
  ///
  /// @param now - current time
  /// @return current status
  ShipStatus getStatus(DateTime now);

}

enum ShipStatus {

  //
  //  Departure Ship Status
  //
  init,        // not try yet
  waiting,     // sent, waiting for responses
  timeout,     // waiting to send again
  done,        // all fragments responded (or no need respond)
  failed,      // tried 3 times and missed response(s)

  //
  //  Arrival Ship Status
  //
  assembling,  // waiting for more fragments
  expired,     // failed to received all fragments

}


///  Incoming Ship
///  ~~~~~~~~~~~~~
abstract interface class Arrival implements Ship {

  ///  Data package can be sent as separated batches
  ///
  /// @param income - income ship carried with message fragment
  /// @return new ship carried the whole data package
  Arrival? assemble(Arrival ship);

}


///  Outgoing Ship
///  ~~~~~~~~~~~~~
abstract interface class Departure implements Ship {

  ///  Get fragments to sent
  ///
  /// @return remaining separated data packages
  List<Uint8List> get fragments;

  ///  The arrival ship may carried response(s) for the departure.
  ///  if all fragments responded, means this task is finished.
  ///
  /// @param response - income ship carried with response
  /// @return true on task finished
  bool checkResponse(Arrival response);

  ///  Whether needs to wait for responses
  ///
  /// @return false for disposable
  bool get isImportant;

  ///  Task priority
  ///
  /// @return default is 0, smaller is faster
  int get priority;

}

abstract class DeparturePriority {

  // ignore_for_file: constant_identifier_names
  static const int URGENT = -1;
  static const int NORMAL = 0;
  static const int SLOWER = 1;

}
