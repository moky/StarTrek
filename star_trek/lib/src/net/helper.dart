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
import '../nio/address.dart';
import '../nio/datagram.dart';
import '../nio/network.dart';
import '../nio/selectable.dart';
import '../nio/socket.dart';

abstract interface class SocketHelper {

  static SocketAddress? socketGetLocalAddress(SelectableChannel sock) {
    if (sock is SocketChannel) {
      // TCP
      return sock.localAddress;
    } else if (sock is DatagramChannel) {
      // UDP
      return sock.localAddress;
    } else {
      assert(false, 'unknown socket channel: $sock');
      return null;
    }
  }

  static SocketAddress? socketGetRemoteAddress(SelectableChannel sock) {
    if (sock is SocketChannel) {
      // TCP
      return sock.remoteAddress;
    } else if (sock is DatagramChannel) {
      // UDP
      return sock.remoteAddress;
    } else {
      assert(false, 'unknown socket channel: $sock');
      return null;
    }
  }


  ///
  /// Flags
  ///


  static bool socketIsBlocking(SelectableChannel sock) {
    return sock.isBlocking;
  }

  static bool socketIsConnected(SelectableChannel sock) {
    if (sock is SocketChannel) {
      // TCP
      return sock.isConnected;
    } else if (sock is DatagramChannel) {
      // UDP
      return sock.isConnected;
    } else {
      assert(false, 'unknown socket channel: $sock');
      return false;
    }
  }

  static bool socketIsBound(SelectableChannel sock) {
    if (sock is SocketChannel) {
      // TCP
      return sock.isBound;
    } else if (sock is DatagramChannel) {
      // UDP
      return sock.isBound;
    } else {
      assert(false, 'unknown socket channel: $sock');
      return false;
    }
  }

  static bool socketIsClosed(SelectableChannel sock) {
    return sock.isClosed;
  }


  /// Ready for reading
  static bool socketIsAvailable(SelectableChannel sock) {
    // TODO: check reading buffer
    return true;
  }

  /// Ready for writing
  static bool socketIsVacant(SelectableChannel sock) {
    // TODO: check writing buffer
    return true;
  }


  ///
  /// Async Socket I/O
  ///


  /// Bind to local address
  static Future<bool> socketBind(NetworkChannel sock, SocketAddress local) async {
    await sock.bind(local);
    return sock is SelectableChannel && socketIsBound(sock as SelectableChannel);
  }

  /// Connect to remote address
  static Future<bool> socketConnect(NetworkChannel sock, SocketAddress remote) async {
    if (sock is SocketChannel) {
      // TCP
      return await sock.connect(remote);
    } else if (sock is DatagramChannel) {
      // UDP
      await sock.connect(remote);
      return sock.isConnected;
    }
    assert(false, 'unknown socket channel: $sock');
    return false;
  }

  ///  Close socket
  static Future<bool> socketDisconnect(SelectableChannel sock) async {
    if (sock is SocketChannel) {
      // TCP
      if (sock.isClosed) {
        // already closed
        return true;
      } else {
        await sock.close();
        return sock.isClosed;
      }
    } else if (sock is DatagramChannel) {
      // UDP
      if (sock.isConnected) {
        await sock.disconnect();
      }
      return !sock.isConnected;
    }
    assert(false, 'unknown socket channel: $sock');
    return false;
  }

}
