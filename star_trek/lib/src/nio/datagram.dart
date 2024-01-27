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

import 'address.dart';
import 'channel.dart';
import 'selectable.dart';


/// A selectable channel for datagram-oriented sockets.
///
/// <p> A datagram channel is created by invoking one of the {@link #open open} methods
/// of this class. It is not possible to create a channel for an arbitrary,
/// pre-existing datagram socket. A newly-created datagram channel is open but not
/// connected. A datagram channel need not be connected in order for the {@link #send
/// send} and {@link #receive receive} methods to be used.  A datagram channel may be
/// connected, by invoking its {@link #connect connect} method, in order to
/// avoid the overhead of the security checks are otherwise performed as part of
/// every send and receive operation.  A datagram channel must be connected in
/// order to use the {@link #read(java.nio.ByteBuffer) read} and {@link
/// #write(java.nio.ByteBuffer) write} methods, since those methods do not
/// accept or return socket addresses.
///
/// <p> Once connected, a datagram channel remains connected until it is
/// disconnected or closed.  Whether or not a datagram channel is connected may
/// be determined by invoking its {@link #isConnected isConnected} method.
///
/// <p> Socket options are configured using the {@link #setOption(SocketOption,Object)
/// setOption} method. A datagram channel to an Internet Protocol socket supports
/// the following options:
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
///     <td> {@link java.net.StandardSocketOptions#SO_REUSEADDR SO_REUSEADDR} </td>
///     <td> Re-use address </td>
///   </tr>
///   <tr>
///     <td> {@link java.net.StandardSocketOptions#SO_BROADCAST SO_BROADCAST} </td>
///     <td> Allow transmission of broadcast datagrams </td>
///   </tr>
///   <tr>
///     <td> {@link java.net.StandardSocketOptions#IP_TOS IP_TOS} </td>
///     <td> The Type of Service (ToS) octet in the Internet Protocol (IP) header </td>
///   </tr>
///   <tr>
///     <td> {@link java.net.StandardSocketOptions#IP_MULTICAST_IF IP_MULTICAST_IF} </td>
///     <td> The network interface for Internet Protocol (IP) multicast datagrams </td>
///   </tr>
///   <tr>
///     <td> {@link java.net.StandardSocketOptions#IP_MULTICAST_TTL
///       IP_MULTICAST_TTL} </td>
///     <td> The <em>time-to-live</em> for Internet Protocol (IP) multicast
///       datagrams </td>
///   </tr>
///   <tr>
///     <td> {@link java.net.StandardSocketOptions#IP_MULTICAST_LOOP
///       IP_MULTICAST_LOOP} </td>
///     <td> Loopback for Internet Protocol (IP) multicast datagrams </td>
///   </tr>
/// </table>
/// </blockquote>
/// Additional (implementation specific) options may also be supported.
///
/// <p> Datagram channels are safe for use by multiple concurrent threads.  They
/// support concurrent reading and writing, though at most one thread may be
/// reading and at most one thread may be writing at any given time.  </p>
abstract class DatagramChannel extends AbstractSelectableChannel
    implements ByteChannel {

  Future<DatagramChannel?> bind(SocketAddress local);

  bool get isBound;

  /// Tells whether or not this channel's socket is connected.
  ///
  /// @return  {@code true} if, and only if, this channel's socket
  ///          is {@link #isOpen open} and connected
  bool get isConnected;

  /// Connects this channel's socket.
  ///
  /// <p> The channel's socket is configured so that it only receives
  /// datagrams from, and sends datagrams to, the given remote <i>peer</i>
  /// address.  Once connected, datagrams may not be received from or sent to
  /// any other address.  A datagram socket remains connected until it is
  /// explicitly disconnected or until it is closed.
  ///
  /// <p> This method performs exactly the same security checks as the {@link
  /// java.net.DatagramSocket#connect connect} method of the {@link
  /// java.net.DatagramSocket} class.  That is, if a security manager has been
  /// installed then this method verifies that its {@link
  /// java.lang.SecurityManager#checkAccept checkAccept} and {@link
  /// java.lang.SecurityManager#checkConnect checkConnect} methods permit
  /// datagrams to be received from and sent to, respectively, the given
  /// remote address.
  ///
  /// <p> This method may be invoked at any time.  It will not have any effect
  /// on read or write operations that are already in progress at the moment
  /// that it is invoked. If this channel's socket is not bound then this method
  /// will first cause the socket to be bound to an address that is assigned
  /// automatically, as if invoking the {@link #bind bind} method with a
  /// parameter of {@code null}. </p>
  ///
  /// @param  remote
  ///         The remote address to which this channel is to be connected
  ///
  /// @return  This datagram channel
  Future<DatagramChannel?> connect(SocketAddress remote);

  /// Disconnects this channel's socket.
  ///
  /// <p> The channel's socket is configured so that it can receive datagrams
  /// from, and sends datagrams to, any remote address so long as the security
  /// manager, if installed, permits it.
  ///
  /// <p> This method may be invoked at any time.  It will not have any effect
  /// on read or write operations that are already in progress at the moment
  /// that it is invoked.
  ///
  /// <p> If this channel's socket is not connected, or if the channel is
  /// closed, then invoking this method has no effect.  </p>
  ///
  /// @return  This datagram channel
  Future<DatagramChannel?> disconnect();

  /// Returns the remote address to which this channel's socket is connected.
  ///
  /// @return  The remote address; {@code null} if the channel's socket is not
  ///          connected
  SocketAddress? get remoteAddress;

  /// Receives a datagram via this channel.
  ///
  /// <p> If a datagram is immediately available, or if this channel is in
  /// blocking mode and one eventually becomes available, then the datagram is
  /// copied into the given byte buffer and its source address is returned.
  /// If this channel is in non-blocking mode and a datagram is not
  /// immediately available then this method immediately returns
  /// <tt>null</tt>.
  ///
  /// <p> The datagram is transferred into the given byte buffer starting at
  /// its current position, as if by a regular {@link
  /// ReadableByteChannel#read(java.nio.ByteBuffer) read} operation.  If there
  /// are fewer bytes remaining in the buffer than are required to hold the
  /// datagram then the remainder of the datagram is silently discarded.
  ///
  /// <p> This method performs exactly the same security checks as the {@link
  /// java.net.DatagramSocket#receive receive} method of the {@link
  /// java.net.DatagramSocket} class.  That is, if the socket is not connected
  /// to a specific remote address and a security manager has been installed
  /// then for each datagram received this method verifies that the source's
  /// address and port number are permitted by the security manager's {@link
  /// java.lang.SecurityManager#checkAccept checkAccept} method.  The overhead
  /// of this security check can be avoided by first connecting the socket via
  /// the {@link #connect connect} method.
  ///
  /// <p> This method may be invoked at any time.  If another thread has
  /// already initiated a read operation upon this channel, however, then an
  /// invocation of this method will block until the first operation is
  /// complete. If this channel's socket is not bound then this method will
  /// first cause the socket to be bound to an address that is assigned
  /// automatically, as if invoking the {@link #bind bind} method with a
  /// parameter of {@code null}. </p>
  ///
  /// @param  dst
  ///         The buffer into which the datagram is to be transferred
  ///
  /// @return  The datagram's source address,
  ///          or <tt>null</tt> if this channel is in non-blocking mode
  ///          and no datagram was immediately available
  Future<SocketAddress?> receive(ByteBuffer dst);

  /// Sends a datagram via this channel.
  ///
  /// <p> If this channel is in non-blocking mode and there is sufficient room
  /// in the underlying output buffer, or if this channel is in blocking mode
  /// and sufficient room becomes available, then the remaining bytes in the
  /// given buffer are transmitted as a single datagram to the given target
  /// address.
  ///
  /// <p> The datagram is transferred from the byte buffer as if by a regular
  /// {@link WritableByteChannel#write(java.nio.ByteBuffer) write} operation.
  ///
  /// <p> This method performs exactly the same security checks as the {@link
  /// java.net.DatagramSocket#send send} method of the {@link
  /// java.net.DatagramSocket} class.  That is, if the socket is not connected
  /// to a specific remote address and a security manager has been installed
  /// then for each datagram sent this method verifies that the target address
  /// and port number are permitted by the security manager's {@link
  /// java.lang.SecurityManager#checkConnect checkConnect} method.  The
  /// overhead of this security check can be avoided by first connecting the
  /// socket via the {@link #connect connect} method.
  ///
  /// <p> This method may be invoked at any time.  If another thread has
  /// already initiated a write operation upon this channel, however, then an
  /// invocation of this method will block until the first operation is
  /// complete. If this channel's socket is not bound then this method will
  /// first cause the socket to be bound to an address that is assigned
  /// automatically, as if by invoking the {@link #bind bind} method with a
  /// parameter of {@code null}. </p>
  ///
  /// @param  src
  ///         The buffer containing the datagram to be sent
  ///
  /// @param  target
  ///         The address to which the datagram is to be sent
  ///
  /// @return   The number of bytes sent, which will be either the number
  ///           of bytes that were remaining in the source buffer when this
  ///           method was invoked or, if this channel is non-blocking, may be
  ///           zero if there was insufficient room for the datagram in the
  ///           underlying output buffer
  Future<int> send(ByteBuffer src, SocketAddress target);

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
