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


abstract interface class Processor {

  ///  Do the job
  ///
  /// @return false on nothing to do
  Future<bool> process();

}


abstract interface class Handler {

  ///  Prepare for handling
  Future<void> setup();

  ///  Handling run loop
  Future<void> handle();

  ///  Cleanup after handled
  Future<void> finish();

}


abstract interface class Runnable {

  ///  Run in a thread
  Future<void> run();

}


abstract class Runner implements Runnable, Handler, Processor {

  bool _running = false;

  bool get isRunning => _running;

  Future<void> stop() async => _running = false;

  @override
  Future<void> run() async {
    await setup();
    try {
      await handle();
    } finally {
      await finish();
    }
  }

  @override
  Future<void> setup() async {
    _running = true;
  }

  @override
  Future<void> finish() async {
    _running = false;
  }

  @override
  Future<void> handle() async {
    while (isRunning) {
      if (await process()) {
        // process() return true,
        // means this thread is busy,
        // so process next task immediately
      } else {
        // nothing to do now,
        // have a rest ^_^
        await idle();
      }
    }
  }

  // protected
  Future<void> idle() async =>
      await sleep(Duration.millisecondsPerSecond ~/ 60);

  static Future<void> sleep(int millis) async =>
      await Future.delayed(Duration(milliseconds: millis));

}
