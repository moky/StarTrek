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
import 'package:object_key/object_key.dart';

import 'port/ship.dart';


abstract class ArrivalShip implements Arrival {
  ArrivalShip([DateTime? now]) {
    now ??= DateTime.now();
    _expired = DateTime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch + kExpires);
  }

  late DateTime _expired;

  ///  Arrival task will be expired after 5 minutes
  ///  if still not completed.
  static int kExpires = 300 * 1000;  // milliseconds

  @override
  void touch(DateTime now) {
    // update expired time
    _expired = DateTime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch + kExpires);
  }

  @override
  ShipStatus getStatus(DateTime now) {
    if (now.isAfter(_expired)) {
      return ShipStatus.kExpired;
    } else {
      return ShipStatus.kAssembling;
    }
  }

}


///  Memory cache for Arrivals
///  ~~~~~~~~~~~~~~~~~~~~~~~~~
class ArrivalHall {

  final Set<Arrival> _arrivals = {};
  final Map<dynamic, Arrival> _arrivalMap = WeakValueMap();  // SN => Ship
  final Map<dynamic, DateTime> _arrivalFinished = {};        // SN => timestamp

  ///  Check received ship for completed package
  ///
  /// @param income - received ship carrying data package (fragment)
  /// @return ship carrying completed data package
  Arrival? assembleArrival(Arrival income) {
    // 1. check ship ID (SN)
    dynamic sn = income.sn;
    if (sn == null) {
      // separated package ship must have SN for assembling
      // we consider it to be a ship carrying a whole package here
      return income;
    }
    // 2. check cached ship
    Arrival? completed;
    Arrival? cached = _arrivalMap[sn];
    if (cached == null) {
      // check whether the task has already finished
      DateTime? time = _arrivalFinished[sn];
      if (time != null) {
        // task already finished
        return null;
      }
      // 3. new arrival, try assembling to check whether a fragment
      completed = income.assemble(income);
      if (completed == null) {
        // it's a fragment, waiting for more fragments
        _arrivals.add(income);
        _arrivalMap[sn] = income;
        //income.touch(DateTime.now());
      }
      // else, it's a completed package
    } else {
      // 3. cached ship found, try assembling (insert as fragment)
      //    to check whether all fragments received
      completed = cached.assemble(income);
      if (completed == null) {
        // it's not completed yet, update expired time
        // and wait for more fragments.
        cached.touch(DateTime.now());
      } else {
        // all fragments received, remove cached ship
        _arrivals.remove(cached);
        _arrivalMap.remove(sn);
        // mark finished time
        _arrivalFinished[sn] = DateTime.now();
      }
    }
    return completed;
  }

  ///  Clear all expired tasks
  void purge([DateTime? now]) {
    now ??= DateTime.now();
    // 1. seeking expired tasks
    dynamic sn;
    _arrivals.removeWhere((ship) {
      if (ship.getStatus(now!) == ShipStatus.kExpired) {
        // remove mapping with SN
        sn = ship.sn;
        if (sn != null) {
          _arrivalMap.remove(sn);
          // TODO: callback?
        }
        return true;
      } else {
        return false;
      }
    });
    // 2. seeking neglected finished times
    DateTime ago = DateTime.fromMillisecondsSinceEpoch(
        now.millisecondsSinceEpoch - 3600 * 1000
    );
    _arrivalFinished.removeWhere((sn, when) => when.isBefore(ago));
  }

}
