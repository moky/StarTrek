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
import 'dart:typed_data';


/// A {@code Closeable} is a source or destination of data that can be closed.
/// The close method is invoked to release resources that the object is
/// holding (such as open files).
abstract interface class Closeable {

  /// Closes this stream and releases any system resources associated
  /// with it. If the stream is already closed then invoking this
  /// method has no effect.
  ///
  /// <p> As noted in {@link AutoCloseable#close()}, cases where the
  /// close may fail require careful attention. It is strongly advised
  /// to relinquish the underlying resources and to internally
  /// <em>mark</em> the {@code Closeable} as closed, prior to throwing
  /// the {@code IOException}.
  Future<void> close();

}

/// A nexus for I/O operations.
///
/// <p> A channel represents an open connection to an entity such as a hardware
/// device, a file, a network socket, or a program component that is capable of
/// performing one or more distinct I/O operations, for example reading or
/// writing.
///
/// <p> A channel is either open or closed.  A channel is open upon creation,
/// and once closed it remains closed.  Once a channel is closed, any attempt to
/// invoke an I/O operation upon it will cause a {@link ClosedChannelException}
/// to be thrown.  Whether or not a channel is open may be tested by invoking
/// its {@link #isOpen isOpen} method.
///
/// <p> Channels are, in general, intended to be safe for multithreaded access
/// as described in the specifications of the interfaces and classes that extend
/// and implement this interface.
abstract interface class NIOChannel implements Closeable {

  /// Tells whether or not this channel is open.
  ///
  /// @return <tt>true</tt> if, and only if, this channel is open
  bool get isClosed;

}

/// A channel that can read bytes.
///
/// <p> Only one read operation upon a readable channel may be in progress at
/// any given time.  If one thread initiates a read operation upon a channel
/// then any other thread that attempts to initiate another read operation will
/// block until the first operation is complete.  Whether or not other kinds of
/// I/O operations may proceed concurrently with a read operation depends upon
/// the type of the channel. </p>
abstract interface class ReadableByteChannel implements NIOChannel {

  /// Reads a sequence of bytes from this channel into the given buffer.
  ///
  /// <p> An attempt is made to read up to <i>r</i> bytes from the channel,
  /// where <i>r</i> is the number of bytes remaining in the buffer, that is,
  /// <tt>dst.remaining()</tt>, at the moment this method is invoked.
  ///
  /// <p> Suppose that a byte sequence of length <i>n</i> is read, where
  /// <tt>0</tt>&nbsp;<tt>&lt;=</tt>&nbsp;<i>n</i>&nbsp;<tt>&lt;=</tt>&nbsp;<i>r</i>.
  /// This byte sequence will be transferred into the buffer so that the first
  /// byte in the sequence is at index <i>p</i> and the last byte is at index
  /// <i>p</i>&nbsp;<tt>+</tt>&nbsp;<i>n</i>&nbsp;<tt>-</tt>&nbsp;<tt>1</tt>,
  /// where <i>p</i> is the buffer's position at the moment this method is
  /// invoked.  Upon return the buffer's position will be equal to
  /// <i>p</i>&nbsp;<tt>+</tt>&nbsp;<i>n</i>; its limit will not have changed.
  ///
  /// <p> A read operation might not fill the buffer, and in fact it might not
  /// read any bytes at all.  Whether or not it does so depends upon the
  /// nature and state of the channel.  A socket channel in non-blocking mode,
  /// for example, cannot read any more bytes than are immediately available
  /// from the socket's input buffer; similarly, a file channel cannot read
  /// any more bytes than remain in the file.  It is guaranteed, however, that
  /// if a channel is in blocking mode and there is at least one byte
  /// remaining in the buffer then this method will block until at least one
  /// byte is read.
  ///
  /// <p> This method may be invoked at any time.  If another thread has
  /// already initiated a read operation upon this channel, however, then an
  /// invocation of this method will block until the first operation is
  /// complete. </p>
  ///
  /// @param  dst
  ///         The buffer into which bytes are to be transferred
  ///
  /// @return  The number of bytes read, possibly zero, or <tt>-1</tt> if the
  ///          channel has reached end-of-stream
  Future<Uint8List?> read(int maxLen);

}

/// A channel that can write bytes.
///
/// <p> Only one write operation upon a writable channel may be in progress at
/// any given time.  If one thread initiates a write operation upon a channel
/// then any other thread that attempts to initiate another write operation will
/// block until the first operation is complete.  Whether or not other kinds of
/// I/O operations may proceed concurrently with a write operation depends upon
/// the type of the channel. </p>
abstract interface class WritableByteChannel implements NIOChannel {

  /// Writes a sequence of bytes to this channel from the given buffer.
  ///
  /// <p> An attempt is made to write up to <i>r</i> bytes to the channel,
  /// where <i>r</i> is the number of bytes remaining in the buffer, that is,
  /// <tt>src.remaining()</tt>, at the moment this method is invoked.
  ///
  /// <p> Suppose that a byte sequence of length <i>n</i> is written, where
  /// <tt>0</tt>&nbsp;<tt>&lt;=</tt>&nbsp;<i>n</i>&nbsp;<tt>&lt;=</tt>&nbsp;<i>r</i>.
  /// This byte sequence will be transferred from the buffer starting at index
  /// <i>p</i>, where <i>p</i> is the buffer's position at the moment this
  /// method is invoked; the index of the last byte written will be
  /// <i>p</i>&nbsp;<tt>+</tt>&nbsp;<i>n</i>&nbsp;<tt>-</tt>&nbsp;<tt>1</tt>.
  /// Upon return the buffer's position will be equal to
  /// <i>p</i>&nbsp;<tt>+</tt>&nbsp;<i>n</i>; its limit will not have changed.
  ///
  /// <p> Unless otherwise specified, a write operation will return only after
  /// writing all of the <i>r</i> requested bytes.  Some types of channels,
  /// depending upon their state, may write only some of the bytes or possibly
  /// none at all.  A socket channel in non-blocking mode, for example, cannot
  /// write any more bytes than are free in the socket's output buffer.
  ///
  /// <p> This method may be invoked at any time.  If another thread has
  /// already initiated a write operation upon this channel, however, then an
  /// invocation of this method will block until the first operation is
  /// complete. </p>
  ///
  /// @param  src
  ///         The buffer from which bytes are to be retrieved
  ///
  /// @return The number of bytes written, possibly zero
  Future<int> write(Uint8List src);

}

/// A channel that can read and write bytes.  This interface simply unifies
/// the {@link ReadableByteChannel} and {@link WritableByteChannel}; it does not
/// specify any new operations.
abstract interface class ByteChannel implements ReadableByteChannel, WritableByteChannel {

}

