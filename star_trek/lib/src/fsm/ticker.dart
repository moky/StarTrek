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
  Future<void> tick(DateTime now, int elapsed);

}


class Metronome extends Runner {

  // at least wait 1/60 of a second
  static int minInterval = Duration.millisecondsPerSecond ~/ 60;

  Metronome(int millis) : _interval = millis, _lastTime = 0 {
    assert(millis > 0, 'interval error: $millis');
    _allTickers = WeakSet();
  }

  final int _interval;
  int _lastTime;

  late final Set<Ticker> _allTickers;

  void addTicker(Ticker ticker) => _allTickers.add(ticker);

  void removeTicker(Ticker ticker) => _allTickers.remove(ticker);

  Future<void> start() async => await run();

  @override
  Future<void> setup() async {
    await super.setup();
    _lastTime = DateTime.now().millisecondsSinceEpoch;
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
    int current = now.millisecondsSinceEpoch;
    int elapsed = current - _lastTime;
    int waiting = _interval - elapsed;
    if (waiting < minInterval) {
      waiting = minInterval;
    }
    await Runner.sleep(waiting);
    now = now.add(Duration(milliseconds: waiting));
    elapsed += waiting;
    // 2. drive tickers
    for (Ticker item in tickers) {
      try {
        await item.tick(now, elapsed);
      } catch (e, st) {
        await onError(e, st, item);
      }
    }
    // 3. update last time
    _lastTime = now.millisecondsSinceEpoch;
    return true;
  }

  // protected
  Future<void> onError(dynamic error, dynamic stacktrace, Ticker ticker) async {}

}


class PrimeMetronome {
  factory PrimeMetronome() => _instance;
  static final PrimeMetronome _instance = PrimeMetronome._internal();
  PrimeMetronome._internal() {
    _metronome = Metronome(200);
    _metronome.start();
  }

  late final Metronome _metronome;

  void addTicker(Ticker ticker) => _metronome.addTicker(ticker);

  void removeTicker(Ticker ticker) => _metronome.removeTicker(ticker);

}
