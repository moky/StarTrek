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
import 'ticker.dart';


class Status {

  static const int kStopped = (0);
  static const int kRunning = (1);
  static const int kPaused  = (2);

}


///  State Machine Context
///  ~~~~~~~~~~~~~~~~~~~~~
abstract interface class Context {

}


///  State Transition
///  ~~~~~~~~~~~~~~~~
///
/// @param <C> - context
abstract interface class Transition<C extends Context> {

  ///  Evaluate the current state
  ///
  /// @param ctx     - context (machine)
  /// @param now     - current time
  /// @return true when current state should be changed
  bool evaluate(C ctx, DateTime now);

}


///  Finite State
///  ~~~~~~~~~~~~
///
/// @param <C> - context
/// @param <T> - transition
abstract interface class State<C extends Context, T extends Transition<C>> {

  ///  Called after new state entered
  ///
  /// @param previous - old state
  /// @param ctx      - context (machine)
  /// @param now      - current time
  void onEnter(State<C, T>? previous, C ctx, DateTime now);

  ///  Called before old state exited
  ///
  /// @param next    - new state
  /// @param ctx     - context (machine)
  /// @param now     - current time
  void onExit(State<C, T>? next, C ctx, DateTime now);

  ///  Called before current state paused
  ///
  /// @param ctx - context (machine)
  /// @param now - current time
  void onPause(C ctx, DateTime now);

  ///  Called after current state resumed
  ///
  /// @param ctx - context (machine)
  /// @param now - current time
  void onResume(C ctx, DateTime now);

  ///  Called by machine.tick() to evaluate each transitions
  ///
  /// @param ctx     - context (machine)
  /// @param now     - current time
  /// @return success transition, or null to stay the current state
  T? evaluate(C ctx, DateTime now);

}


///  State Machine Delegate
///  ~~~~~~~~~~~~~~~~~~~~~~
///
/// @param <S> - state
/// @param <C> - context
/// @param <T> - transition
abstract interface class Delegate<C extends Context, T extends Transition<C>, S extends State<C, T>> {

  ///  Called before new state entered
  ///  (get current state from context)
  ///
  /// @param next     - new state
  /// @param ctx      - context (machine)
  /// @param now      - current time (milliseconds, from Jan 1, 1970 UTC)
  void enterState(S? next, C ctx, DateTime now);

  ///  Called after old state exited
  ///  (get current state from context)
  ///
  /// @param previous - old state
  /// @param ctx      - context (machine)
  /// @param now      - current time (milliseconds, from Jan 1, 1970 UTC)
  void exitState(S? previous, C ctx, DateTime now);

  ///  Called after current state paused
  ///
  /// @param current  - current state
  /// @param ctx      - context (machine)
  /// @param now      - current time (milliseconds, from Jan 1, 1970 UTC)
  void pauseState(S? current, C ctx, DateTime now);

  ///  Called before current state resumed
  ///
  /// @param current  - current state
  /// @param ctx      - context (machine)
  /// @param now      - current time (milliseconds, from Jan 1, 1970 UTC)
  void resumeState(S? current, C ctx, DateTime now);

}


///  State machine
///  ~~~~~~~~~~~~~
///
/// @param <S> - state
/// @param <C> - context
/// @param <T> - transition
abstract interface class Machine<C extends Context, T extends Transition<C>, S extends State<C, T>>
    implements Ticker {

  S? get currentState;

  ///  Change current state to 'default'
  void start();

  ///  Change current state to null
  void stop();

  ///  Pause machine, current state not change
  void pause();

  ///  Resume machine with current state
  void resume();

}
