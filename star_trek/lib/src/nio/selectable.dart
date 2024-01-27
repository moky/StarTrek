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
import 'channel.dart';


abstract interface class InterruptibleChannel implements NIOChannel {

}

/// Base implementation class for interruptible channels.
///
/// <p> This class encapsulates the low-level machinery required to implement
/// the asynchronous closing and interruption of channels.  A concrete channel
/// class must invoke the {@link #begin begin} and {@link #end end} methods
/// before and after, respectively, invoking an I/O operation that might block
/// indefinitely.  In order to ensure that the {@link #end end} method is always
/// invoked, these methods should be used within a
/// <tt>try</tt>&nbsp;...&nbsp;<tt>finally</tt> block:
///
/// <blockquote><pre>
/// boolean completed = false;
/// try {
///     begin();
///     completed = ...;    // Perform blocking I/O operation
///     return ...;         // Return result
/// } finally {
///     end(completed);
/// }</pre></blockquote>
///
/// <p> The <tt>completed</tt> argument to the {@link #end end} method tells
/// whether or not the I/O operation actually completed, that is, whether it had
/// any effect that would be visible to the invoker.  In the case of an
/// operation that reads bytes, for example, this argument should be
/// <tt>true</tt> if, and only if, some bytes were actually transferred into the
/// invoker's target buffer.
///
/// <p> A concrete channel class must also implement the {@link
/// #implCloseChannel implCloseChannel} method in such a way that if it is
/// invoked while another thread is blocked in a native I/O operation upon the
/// channel then that operation will immediately return, either by throwing an
/// exception or by returning normally.  If a thread is interrupted or the
/// channel upon which it is blocked is asynchronously closed then the channel's
/// {@link #end end} method will throw the appropriate exception.
///
/// <p> This class performs the synchronization required to implement the {@link
/// java.nio.channels.Channel} specification.  Implementations of the {@link
/// #implCloseChannel implCloseChannel} method need not synchronize against
/// other threads that might be attempting to close the channel.  </p>
abstract class AbstractInterruptibleChannel implements InterruptibleChannel {

  bool _open = true;

  @override
  bool get isClosed => !_open;

  @override
  Future<void> close() async {
    if (_open) {
      _open = false;
      await implCloseChannel();
    }
  }

  /// Closes this channel.
  ///
  /// <p> This method is invoked by the {@link #close close} method in order
  /// to perform the actual work of closing the channel.  This method is only
  /// invoked if the channel has not yet been closed, and it is never invoked
  /// more than once.
  ///
  /// <p> An implementation of this method must arrange for any other thread
  /// that is blocked in an I/O operation upon this channel to return
  /// immediately, either by throwing an exception or by returning normally.
  /// </p>
  Future<void> implCloseChannel();

}

/// A channel that can be multiplexed via a {@link Selector}.
///
/// <p> In order to be used with a selector, an instance of this class must
/// first be <i>registered</i> via the {@link #register(Selector,int,Object)
/// register} method.  This method returns a new {@link SelectionKey} object
/// that represents the channel's registration with the selector.
///
/// <p> Once registered with a selector, a channel remains registered until it
/// is <i>deregistered</i>.  This involves deallocating whatever resources were
/// allocated to the channel by the selector.
///
/// <p> A channel cannot be deregistered directly; instead, the key representing
/// its registration must be <i>cancelled</i>.  Cancelling a key requests that
/// the channel be deregistered during the selector's next selection operation.
/// A key may be cancelled explicitly by invoking its {@link
/// SelectionKey#cancel() cancel} method.  All of a channel's keys are cancelled
/// implicitly when the channel is closed, whether by invoking its {@link
/// Channel#close close} method or by interrupting a thread blocked in an I/O
/// operation upon the channel.
///
/// <p> If the selector itself is closed then the channel will be deregistered,
/// and the key representing its registration will be invalidated, without
/// further delay.
///
/// <p> A channel may be registered at most once with any particular selector.
///
/// <p> Whether or not a channel is registered with one or more selectors may be
/// determined by invoking the {@link #isRegistered isRegistered} method.
///
/// <p> Selectable channels are safe for use by multiple concurrent
/// threads. </p>
///
///
/// <a name="bm"></a>
/// <h2>Blocking mode</h2>
///
/// A selectable channel is either in <i>blocking</i> mode or in
/// <i>non-blocking</i> mode.  In blocking mode, every I/O operation invoked
/// upon the channel will block until it completes.  In non-blocking mode an I/O
/// operation will never block and may transfer fewer bytes than were requested
/// or possibly no bytes at all.  The blocking mode of a selectable channel may
/// be determined by invoking its {@link #isBlocking isBlocking} method.
///
/// <p> Newly-created selectable channels are always in blocking mode.
/// Non-blocking mode is most useful in conjunction with selector-based
/// multiplexing.  A channel must be placed into non-blocking mode before being
/// registered with a selector, and may not be returned to blocking mode until
/// it has been deregistered.
abstract class SelectableChannel extends AbstractInterruptibleChannel {

  /// Adjusts this channel's blocking mode.
  ///
  /// <p> If this channel is registered with one or more selectors then an
  /// attempt to place it into blocking mode will cause an {@link
  /// IllegalBlockingModeException} to be thrown.
  ///
  /// <p> This method may be invoked at any time.  The new blocking mode will
  /// only affect I/O operations that are initiated after this method returns.
  /// For some implementations this may require blocking until all pending I/O
  /// operations are complete.
  ///
  /// <p> If this method is invoked while another invocation of this method or
  /// of the {@link #register(Selector, int) register} method is in progress
  /// then it will first block until the other operation is complete. </p>
  ///
  /// @param  block  If <tt>true</tt> then this channel will be placed in
  ///                blocking mode; if <tt>false</tt> then it will be placed
  ///                non-blocking mode
  ///
  /// @return  This selectable channel
  SelectableChannel? configureBlocking(bool block);

  /// Tells whether or not every I/O operation on this channel will block
  /// until it completes.  A newly-created channel is always in blocking mode.
  ///
  /// <p> If this channel is closed then the value returned by this method is
  /// not specified. </p>
  ///
  /// @return <tt>true</tt> if, and only if, this channel is in blocking mode
  bool get isBlocking;

}


/// Base implementation class for selectable channels.
///
/// <p> This class defines methods that handle the mechanics of channel
/// registration, deregistration, and closing.  It maintains the current
/// blocking mode of this channel as well as its current set of selection keys.
/// It performs all of the synchronization required to implement the {@link
/// java.nio.channels.SelectableChannel} specification.  Implementations of the
/// abstract protected methods defined in this class need not synchronize
/// against other threads that might be engaged in the same operations.  </p>
abstract class AbstractSelectableChannel extends SelectableChannel {

  bool _blocking = true;

  @override
  bool get isBlocking => _blocking;

  @override
  SelectableChannel? configureBlocking(bool block) {
    if (isClosed) {
      assert(false, 'channel closed');
      return null;
    } else if (_blocking = block) {
      return this;
    }
    implConfigureBlocking(block);
    _blocking = block;
    return this;
  }

  /// Adjusts this channel's blocking mode.
  ///
  /// <p> This method is invoked by the {@link #configureBlocking
  /// configureBlocking} method in order to perform the actual work of
  /// changing the blocking mode.  This method is only invoked if the new mode
  /// is different from the current mode.  </p>
  ///
  /// @param  block  If <tt>true</tt> then this channel will be placed in
  ///                blocking mode; if <tt>false</tt> then it will be placed
  ///                non-blocking mode
  void implConfigureBlocking(bool block);

}
