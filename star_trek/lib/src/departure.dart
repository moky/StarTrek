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


abstract class DepartureShip implements Departure {
  DepartureShip({int? priority, int? maxTries}) {
    assert(maxTries != 0, 'max tries should not be 0');
    _prior = priority ?? 0;
    _expired = null;
    _tries = maxTries ?? 1 + RETRIES;
  }

  DateTime? _expired;
  // how many times to try sending
  late int _tries;
  // task priority, smaller is faster
  late final int _prior;

  ///  Departure task will be expired after 2 minutes
  ///  if no response received.
  static Duration EXPIRES = Duration(minutes: 2);

  ///  Important departure task will be retried 2 times
  ///  if response timeout.
  static int RETRIES = 2;
  // ignore_for_file: non_constant_identifier_names

  @override
  int get priority => _prior;

  @override
  void touch(DateTime now) {
    assert(_tries > 0, 'touch error, tries=$_tries');
    // decrease counter
    --_tries;
    // update retried time
    _expired = now.add(EXPIRES);
  }

  @override
  ShipStatus getStatus(DateTime now) {
    DateTime? expired = _expired;
    if (fragments.isEmpty) {
      return ShipStatus.done;
    } else if (expired == null) {
      return ShipStatus.init;
    // } else if (!isImportant) {
    //   return ShipStatus.done;
    } else if (now.isBefore(expired)) {
      return ShipStatus.waiting;
    } else if (_tries > 0) {
      return ShipStatus.timeout;
    } else {
      return ShipStatus.failed;
    }
  }

}


///  Memory cache for Departures
///  ~~~~~~~~~~~~~~~~~~~~~~~~~~~
class DepartureHall {

  // all departure ships
  final Set<Departure> _allDepartures = WeakSet();
  // new ships waiting to send out
  final List<Departure> _newDepartures = [];

  // ships waiting for responses
  final Map<int, List<Departure>> _departureFleets = {};  // priority => List
  final List<int> _priorities = [];

  // index
  final Map<dynamic, Departure> _departureMap = WeakValueMap();  // SN => ship
  final Map<dynamic, DateTime> _departureFinished = {};          // SN => timestamp
  final Map<dynamic, int> _departureLevel = {};                  // SN => priority

  ///  Add outgoing ship to the waiting queue
  ///
  /// @param outgo - departure task
  /// @return false on duplicated
  bool addDeparture(Departure outgo) {
    // 1. check duplicated
    if (_allDepartures.contains(outgo)) {
      return false;
    } else {
      _allDepartures.add(outgo);
    }
    // 2. insert to the sorted queue
    int priority = outgo.priority;
    int index = 0;
    for (; index < _newDepartures.length; ++index) {
      if (_newDepartures[index].priority > priority) {
        // take the place before first ship
        // which priority is greater then this one.
        break;
      }
    }
    _newDepartures.insert(index, outgo);
    return true;
  }

  ///  Check response from incoming ship
  ///
  /// @param response - incoming ship with SN
  /// @return finished task
  Departure? checkResponse(Arrival response) {
    dynamic sn = response.sn;
    assert(sn != null, 'Ship SN not found: $response');
    // check whether this task has already finished
    DateTime? time = _departureFinished[sn];
    if (time != null) {
      return null;
    }
    // check departure
    Departure? ship = _departureMap[sn];
    if (ship != null && ship.checkResponse(response)) {
      // all fragments sent, departure task finished
      // remove it and clear mapping when SN exists
      _removeShip(ship, sn);
      // mark finished time
      _departureFinished[sn] = DateTime.now();
      return ship;
    }
    return null;
  }
  void _removeShip(Departure ship, dynamic sn) {
    int priority = _departureLevel[sn] ?? 0;
    List<Departure>? fleet = _departureFleets[priority];
    if (fleet != null) {
      fleet.remove(ship);
      // remove array when empty
      if (fleet.isEmpty) {
        _departureFleets.remove(priority);
      }
    }
    // remove mapping by SN
    _departureMap.remove(sn);
    _departureLevel.remove(sn);
    _allDepartures.remove(ship);
  }

  ///  Get next new/timeout task
  ///
  /// @param now - current time
  /// @return departure task
  Departure? getNextDeparture(DateTime now) {
    Departure? next = _getNextNewDeparture(now);  // task.expired == 0
    next ??= _getNextTimeoutDeparture(now);       // task.expired < now
    return next;
  }

  Departure? _getNextNewDeparture(DateTime now) {
    if (_newDepartures.isEmpty) {
      return null;
    }
    // get first ship
    Departure outgo = _newDepartures.removeAt(0);
    dynamic sn = outgo.sn;
    if (outgo.isImportant && sn != null) {
      // this task needs response
      // choose an array with priority
      int priority = outgo.priority;
      _insertShip(outgo, priority, sn);
      // build index for it
      _departureMap[sn] = outgo;
    } else {
      // disposable ship needs no response,
      // remove it immediately
      _allDepartures.remove(outgo);
    }
    // update expired time
    outgo.touch(now);
    return outgo;
  }
  void _insertShip(Departure outgo, int priority, dynamic sn) {
    List<Departure>? fleet = _departureFleets[priority];
    if (fleet == null) {
      // create new array for this priority
      fleet = [];
      _departureFleets[priority] = fleet;
      // insert the priority in a sorted list
      _insertPriority(priority);
    }
    // append to the tail, and build index for it
    fleet.add(outgo);
    _departureLevel[sn] = priority;
  }
  void _insertPriority(int priority) {
    int index = 0, value;
    // seeking position for new priority
    for (; index < _priorities.length; ++index) {
      value = _priorities[index];
      if (value == priority) {
        // duplicated
        return;
      } else if (value > priority) {
        // got it
        break;
      }
      // current value is smaller than the new value,
      // keep going
    }
    // insert new value before the bigger one
    _priorities.insert(index, priority);
  }

  Departure? _getNextTimeoutDeparture(DateTime now) {
    List<Departure> departures;
    List<Departure>? fleet;
    ShipStatus status;
    dynamic sn;
    List<int> priorityList = _priorities.toList();  // copy
    for (int prior in priorityList) {
      // 1. get tasks with priority
      fleet = _departureFleets[prior];
      if (fleet == null) {
        continue;
      }
      // 2. seeking timeout task in this priority
      departures = fleet.toList();  // copy
      for (Departure ship in departures) {
        sn = ship.sn;
        assert(sn != null, 'Ship ID should not be empty here');
        status = ship.getStatus(now);
        if (status == ShipStatus.timeout) {
          // response timeout, needs retry now.
          // move to next priority
          fleet.remove(ship);
          _insertShip(ship, prior + 1, sn);
          // update expired time
          ship.touch(now);
          return ship;
        } else if (status == ShipStatus.failed) {
          // try too many times and still missing response,
          // task failed, remove this ship.
          fleet.remove(ship);
          // remove mapping by SN
          _departureMap.remove(sn);
          _departureLevel.remove(sn);
          _allDepartures.remove(ship);
          return ship;
        }
      }
    }
    return null;
  }

  ///  Clear all expired tasks
  int purge([DateTime? now]) {
    now ??= DateTime.now();
    int count = 0;
    // 1. seeking finished tasks
    List<Departure> departures;
    List<Departure>? fleet;
    dynamic sn;
    List<int> priorityList = _priorities.toList();  // copy
    for (int prior in priorityList) {
      fleet = _departureFleets[prior];
      if (fleet == null) {
        // this priority is empty
        _priorities.remove(prior);
        continue;
      }
      departures = fleet.toList();  // copy
      for (Departure ship in departures) {
        if (ship.getStatus(now) == ShipStatus.done) {
          // task done, remove if from memory cache
          fleet.remove(ship);
          sn = ship.sn;
          assert(sn != null, 'Ship SN should not be empty here');
          _departureMap.remove(sn);
          _departureLevel.remove(sn);
          // mark finished time
          _departureFinished[sn] = now;
          ++count;
        }
      }
      // remove array when empty
      if (fleet.isEmpty) {
        _departureFleets.remove(prior);
        _priorities.remove(prior);
      }
    }
    // 2. seeking neglected finished times
    DateTime ago = DateTime.fromMillisecondsSinceEpoch(
        now.millisecondsSinceEpoch - 3600 * 1000
    );
    _departureFinished.removeWhere((sn, when) => when.isBefore(ago));
    return count;
  }

}
