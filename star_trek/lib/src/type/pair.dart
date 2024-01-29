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


class AddressPairObject {
  AddressPairObject({SocketAddress? remote, SocketAddress? local})
      : remoteAddress = remote, localAddress = local;

  SocketAddress? remoteAddress;
  SocketAddress? localAddress;

  @override
  bool operator ==(Object other) {
    if (other is AddressPairObject) {
      if (identical(this, other)) {
        // same object
        return true;
      }
      return other.remoteAddress == remoteAddress && other.localAddress == localAddress;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    // name's hashCode is multiplied by an arbitrary prime number (13)
    // in order to make sure there is a difference in the hashCode between
    // these two parameters:
    //  name: a  value: aa
    //  name: aa value: a
    int? remote = remoteAddress?.hashCode;
    int? local = localAddress?.hashCode;
    return (remote ?? 0) * 13 + (local ?? 0);
  }

  @override
  String toString() {
    Type clazz = runtimeType;
    return '<$clazz remote="$remoteAddress" local="$localAddress" />';
  }

}
