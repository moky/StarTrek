/* license: https://mit-license.org
 *
 *  Finite State Machine
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

import 'runner.dart';


abstract interface class Ticker {

  ///  Drive current thread forward
  ///
  /// @param now     - current time
  /// @param elapsed - milliseconds from previous tick
  Future<void> tick(DateTime now, Duration elapsed);

}


class Metronome extends Runner {

  // at least wait 1/60 of a second
  static Duration minInterval = Duration(
      microseconds: Duration.microsecondsPerSecond ~/ 60);  //  16 millis

  Metronome(super.interval);

  late DateTime _lastTime;

  final Set<Ticker> _allTickers = WeakSet();

  void addTicker(Ticker ticker) => _allTickers.add(ticker);

  void removeTicker(Ticker ticker) => _allTickers.remove(ticker);

  Future<void> start() async {
    if (isRunning) {
      await stop();
      await idle();
    }
    /*await */run();
  }

  @override
  Future<void> setup() async {
    await super.setup();
    _lastTime = DateTime.now();
  }

  @override
  Future<bool> process() async {
    Set<Ticker> tickers = _allTickers.toSet();
    if (tickers.isEmpty) {
      // nothing to do now,
      // return false to have a rest ^_^
      return false;
    }
    // 1. check time
    DateTime now = DateTime.now();
    Duration elapsed = now.difference(_lastTime);
    Duration waiting = interval - elapsed;
    if (waiting < minInterval) {
      waiting = minInterval;
    }
    await Runner.sleep(waiting);
    now = now.add(waiting);
    elapsed = elapsed + waiting;
    // 2. drive tickers
    for (Ticker item in tickers) {
      try {
        await item.tick(now, elapsed);
      } catch (e, st) {
        await onError(e, st, item);
      }
    }
    // 3. update last time
    _lastTime = now;
    return true;
  }

  // protected
  Future<void> onError(dynamic error, dynamic stacktrace, Ticker ticker) async {}

}


class PrimeMetronome {
  factory PrimeMetronome() => _instance;
  static final PrimeMetronome _instance = PrimeMetronome._internal();
  PrimeMetronome._internal() {
    _metronome = Metronome(Runner.kIntervalSlow);
    /*await */_metronome.start();
  }

  late final Metronome _metronome;

  void addTicker(Ticker ticker) => _metronome.addTicker(ticker);

  void removeTicker(Ticker ticker) => _metronome.removeTicker(ticker);

}
