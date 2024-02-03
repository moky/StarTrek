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


/// Signals that an I/O exception of some sort has occurred. This
/// class is the general class of exceptions produced by failed or
/// interrupted I/O operations.
class IOException implements Exception {
  IOException(this.message);

  final String message;

  @override
  String toString() => 'IOException: $message';

}


/// Thrown to indicate that there is an error creating or accessing a Socket.
class SocketException extends IOException {
  SocketException(super.message);

}


/// Checked exception thrown when an attempt is made to invoke or complete an
/// I/O operation upon channel that is closed, or at least closed to that
/// operation.  That this exception is thrown does not necessarily imply that
/// the channel is completely closed.  A socket channel whose write half has
/// been shut down, for example, may still be open for reading.
class ClosedChannelException extends IOException {
  ClosedChannelException() : super('channel closed');

}


/// Thrown when a serious I/O error has occurred.
class IOError extends Error {
  IOError(this.cause);

  final dynamic cause;

  @override
  String toString() => 'IOError: $cause';

}
