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


/// A channel to a network socket.
///
/// <p> A channel that implements this interface is a channel to a network
/// socket. The {@link #bind(SocketAddress) bind} method is used to bind the
/// socket to a local {@link SocketAddress address}, the {@link #getLocalAddress()
/// getLocalAddress} method returns the address that the socket is bound to, and
/// the {@link #setOption(SocketOption,Object) setOption} and {@link
/// #getOption(SocketOption) getOption} methods are used to set and query socket
/// options.  An implementation of this interface should specify the socket options
/// that it supports.
///
/// <p> The {@link #bind bind} and {@link #setOption setOption} methods that do
/// not otherwise have a value to return are specified to return the network
/// channel upon which they are invoked. This allows method invocations to be
/// chained. Implementations of this interface should specialize the return type
/// so that method invocations on the implementation class can be chained.
abstract interface class NetworkChannel implements NIOChannel {

  /// Binds the channel's socket to a local address.
  ///
  /// <p> This method is used to establish an association between the socket and
  /// a local address. Once an association is established then the socket remains
  /// bound until the channel is closed. If the {@code local} parameter has the
  /// value {@code null} then the socket will be bound to an address that is
  /// assigned automatically.
  ///
  /// @param   local
  ///          The address to bind the socket, or {@code null} to bind the socket
  ///          to an automatically assigned socket address
  ///
  /// @return  This channel
  Future<NetworkChannel?> bind(SocketAddress local);

  /// Returns the socket address that this channel's socket is bound to.
  ///
  /// <p> Where the channel is {@link #bind bound} to an Internet Protocol
  /// socket address then the return value from this method is of type {@link
  /// java.net.InetSocketAddress}.
  ///
  /// @return  The socket address that the socket is bound to, or {@code null}
  ///          if the channel's socket is not bound
  SocketAddress? get localAddress;

}
