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
import 'address.dart';
import 'channel.dart';
import 'selectable.dart';


/// A selectable channel for stream-oriented connecting sockets.
///
/// <p> A socket channel is created by invoking one of the {@link #open open}
/// methods of this class.  It is not possible to create a channel for an arbitrary,
/// pre-existing socket. A newly-created socket channel is open but not yet
/// connected.  An attempt to invoke an I/O operation upon an unconnected
/// channel will cause a {@link NotYetConnectedException} to be thrown.  A
/// socket channel can be connected by invoking its {@link #connect connect}
/// method; once connected, a socket channel remains connected until it is
/// closed.  Whether or not a socket channel is connected may be determined by
/// invoking its {@link #isConnected isConnected} method.
///
/// <p> Socket channels support <i>non-blocking connection:</i>&nbsp;A socket
/// channel may be created and the process of establishing the link to the
/// remote socket may be initiated via the {@link #connect connect} method for
/// later completion by the {@link #finishConnect finishConnect} method.
/// Whether or not a connection operation is in progress may be determined by
/// invoking the {@link #isConnectionPending isConnectionPending} method.
///
/// <p> Socket channels support <i>asynchronous shutdown,</i> which is similar
/// to the asynchronous close operation specified in the {@link Channel} class.
/// If the input side of a socket is shut down by one thread while another
/// thread is blocked in a read operation on the socket's channel, then the read
/// operation in the blocked thread will complete without reading any bytes and
/// will return <tt>-1</tt>.  If the output side of a socket is shut down by one
/// thread while another thread is blocked in a write operation on the socket's
/// channel, then the blocked thread will receive an {@link
/// AsynchronousCloseException}.
///
/// <p> Socket options are configured using the {@link #setOption(SocketOption,Object)
/// setOption} method. Socket channels support the following options:
/// <blockquote>
/// <table border summary="Socket options">
///   <tr>
///     <th>Option Name</th>
///     <th>Description</th>
///   </tr>
///   <tr>
///     <td> {@link java.net.StandardSocketOptions#SO_SNDBUF SO_SNDBUF} </td>
///     <td> The size of the socket send buffer </td>
///   </tr>
///   <tr>
///     <td> {@link java.net.StandardSocketOptions#SO_RCVBUF SO_RCVBUF} </td>
///     <td> The size of the socket receive buffer </td>
///   </tr>
///   <tr>
///     <td> {@link java.net.StandardSocketOptions#SO_KEEPALIVE SO_KEEPALIVE} </td>
///     <td> Keep connection alive </td>
///   </tr>
///   <tr>
///     <td> {@link java.net.StandardSocketOptions#SO_REUSEADDR SO_REUSEADDR} </td>
///     <td> Re-use address </td>
///   </tr>
///   <tr>
///     <td> {@link java.net.StandardSocketOptions#SO_LINGER SO_LINGER} </td>
///     <td> Linger on close if data is present (when configured in blocking mode
///          only) </td>
///   </tr>
///   <tr>
///     <td> {@link java.net.StandardSocketOptions#TCP_NODELAY TCP_NODELAY} </td>
///     <td> Disable the Nagle algorithm </td>
///   </tr>
/// </table>
/// </blockquote>
/// Additional (implementation specific) options may also be supported.
///
/// <p> Socket channels are safe for use by multiple concurrent threads.  They
/// support concurrent reading and writing, though at most one thread may be
/// reading and at most one thread may be writing at any given time.  The {@link
/// #connect connect} and {@link #finishConnect finishConnect} methods are
/// mutually synchronized against each other, and an attempt to initiate a read
/// or write operation while an invocation of one of these methods is in
/// progress will block until that invocation is complete.  </p>
abstract class SocketChannel extends AbstractSelectableChannel
    implements ByteChannel {

  Future<SocketChannel?> bind(SocketAddress local);

  bool get isBound;

  /// Tells whether or not this channel's network socket is connected.
  ///
  /// @return  <tt>true</tt> if, and only if, this channel's network socket
  ///          is {@link #isOpen open} and connected
  bool get isConnected;

  /// Connects this channel's socket.
  ///
  /// <p> If this channel is in non-blocking mode then an invocation of this
  /// method initiates a non-blocking connection operation.  If the connection
  /// is established immediately, as can happen with a local connection, then
  /// this method returns <tt>true</tt>.  Otherwise this method returns
  /// <tt>false</tt> and the connection operation must later be completed by
  /// invoking the {@link #finishConnect finishConnect} method.
  ///
  /// <p> If this channel is in blocking mode then an invocation of this
  /// method will block until the connection is established or an I/O error
  /// occurs.
  ///
  /// <p> This method performs exactly the same security checks as the {@link
  /// java.net.Socket} class.  That is, if a security manager has been
  /// installed then this method verifies that its {@link
  /// java.lang.SecurityManager#checkConnect checkConnect} method permits
  /// connecting to the address and port number of the given remote endpoint.
  ///
  /// <p> This method may be invoked at any time.  If a read or write
  /// operation upon this channel is invoked while an invocation of this
  /// method is in progress then that operation will first block until this
  /// invocation is complete.  If a connection attempt is initiated but fails,
  /// that is, if an invocation of this method throws a checked exception,
  /// then the channel will be closed.  </p>
  ///
  /// @param  remote
  ///         The remote address to which this channel is to be connected
  ///
  /// @return  <tt>true</tt> if a connection was established,
  ///          <tt>false</tt> if this channel is in non-blocking mode
  ///          and the connection operation is in progress
  Future<bool> connect(SocketAddress remote);

  /// Returns the remote address to which this channel's socket is connected.
  ///
  /// <p> Where the channel is bound and connected to an Internet Protocol
  /// socket address then the return value from this method is of type {@link
  /// java.net.InetSocketAddress}.
  ///
  /// @return  The remote address; {@code null} if the channel's socket is not
  ///          connected
  SocketAddress? get remoteAddress;

  // Future<int> read(ByteBuffer dst);

  // Future<int> write(ByteBuffer src);

  /// {@inheritDoc}
  /// <p>
  /// If there is a security manager set, its {@code checkConnect} method is
  /// called with the local address and {@code -1} as its arguments to see
  /// if the operation is allowed. If the operation is not allowed,
  /// a {@code SocketAddress} representing the
  /// {@link java.net.InetAddress#getLoopbackAddress loopback} address and the
  /// local port of the channel's socket is returned.
  ///
  /// @return  The {@code SocketAddress} that the socket is bound to, or the
  ///          {@code SocketAddress} representing the loopback address if
  ///          denied by the security manager, or {@code null} if the
  ///          channel's socket is not bound
  SocketAddress? get localAddress;

}
