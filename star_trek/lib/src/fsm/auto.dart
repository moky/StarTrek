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
import 'base.dart';
import 'machine.dart';
import 'ticker.dart';


abstract class AutoMachine<C extends MachineContext, T extends BaseTransition<C>, S extends BaseState<C, T>>
    extends BaseMachine<C, T, S> {

  @override
  Future<bool> start() async {
    bool ok = await super.start();
    PrimeMetronome timer = PrimeMetronome();
    timer.addTicker(this);
    return ok;
  }

  @override
  Future<bool> stop() async {
    PrimeMetronome timer = PrimeMetronome();
    timer.removeTicker(this);
    return await super.stop();
  }

  @override
  Future<bool> pause() async {
    PrimeMetronome timer = PrimeMetronome();
    timer.removeTicker(this);
    return await super.pause();
  }

  @override
  Future<bool> resume() async {
    bool ok = await super.resume();
    PrimeMetronome timer = PrimeMetronome();
    timer.addTicker(this);
    return ok;
  }

}
