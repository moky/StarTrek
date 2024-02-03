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


/// This class represents a Socket Address with no protocol attachment.
/// As an abstract class, it is meant to be subclassed with a specific,
/// protocol dependent, implementation.
/// <p>
/// It provides an immutable object used by sockets for binding, connecting, or
/// as returned values.
abstract interface class SocketAddress {

}


/// This class implements an IP Socket Address (IP address + port number)
/// It can also be a pair (hostname + port number), in which case an attempt
/// will be made to resolve the hostname. If resolution fails then the address
/// is said to be <I>unresolved</I> but can still be used on some circumstances
/// like connecting through a proxy.
/// <p>
/// It provides an immutable object used by sockets for binding, connecting, or
/// as returned values.
/// <p>
/// The <i>wildcard</i> is a special local IP address. It usually means "any"
/// and can only be used for {@code bind} operations.
class InetSocketAddress implements SocketAddress {

  InetSocketAddress(this.host, this.port);

  final String host;
  final int port;

  @override
  String toString() => '("$host", $port)';

  static InetSocketAddress? parse(String string) {
    string = string.replaceAll("'", '');
    string = string.replaceAll('"', '');
    string = string.replaceAll(' ', '');
    string = string.replaceAll('/', '');
    string = string.replaceAll('(', '');
    string = string.replaceAll(')', '');
    List<String> pair = string.split(',');
    if (pair.length == 1) {
      pair = string.split(':');
    }
    if (pair.length == 2) {
      int port = int.parse(pair.last);
      if (port > 0) {
        return InetSocketAddress(pair.first, port);
      }
    }
    return null;
  }

}
