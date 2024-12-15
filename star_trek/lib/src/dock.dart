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
import 'port/ship.dart';
import 'arrival.dart';
import 'departure.dart';


///  Star Dock
///  ~~~~~~~~~
///
///  Parking Star Ships
class Dock {
  Dock() {
    _arrivalHall = createArrivalHall();
    _departureHall = createDepartureHall();
  }

  // memory caches
  late final ArrivalHall _arrivalHall;
  late final DepartureHall _departureHall;

  // protected
  ArrivalHall createArrivalHall() => ArrivalHall();
  // protected
  DepartureHall createDepartureHall() => DepartureHall();

  /// Check received ship for completed package
  ///
  /// @param income - received ship carrying data package (fragment)
  /// @return ship carrying completed data package
  Arrival? assembleArrival(Arrival income) {
    // check fragment from income ship,
    // return a ship with completed package if all fragments received
    return _arrivalHall.assembleArrival(income);
  }

  ///  Add outgoing ship to the waiting queue
  ///
  /// @param outgo - departure task
  /// @return false on duplicated
  bool addDeparture(Departure outgo) {
    return _departureHall.addDeparture(outgo);
  }

  ///  Check response from incoming ship
  ///
  /// @param response - incoming ship with SN
  /// @return finished task
  Departure? checkResponse(Arrival response) {
    // check departure tasks with SN
    // remove package/fragment if matched (check page index for fragments too)
    return _departureHall.checkResponse(response);
  }

  ///  Get next new/timeout task
  ///
  /// @param now - current time
  /// @return departure task
  Departure? getNextDeparture(DateTime now) {
    // this will be remove from the queue,
    // if needs retry, the caller should append it back
    return _departureHall.getNextDeparture(now);
  }

  /// Clear all expired tasks
  int purge([DateTime? now]) {
    int count = 0;
    count += _arrivalHall.purge(now);
    count += _departureHall.purge(now);
    return count;
  }

}


class LockedDock extends Dock {

  DateTime? _nextPurgeTime;
  static const Duration halfMinute = Duration(seconds: 30);

  @override
  int purge([DateTime? now]) {
    now ??= DateTime.now();
    DateTime? nextTime = _nextPurgeTime;
    if (nextTime != null && now.isBefore(nextTime)) {
      return -1;
    } else {
      // next purge after half a minute
      _nextPurgeTime = now.add(halfMinute);
    }
    return super.purge(now);
  }

}
