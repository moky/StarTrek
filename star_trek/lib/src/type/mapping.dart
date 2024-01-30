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
import 'package:object_key/object_key.dart';

import '../nio/address.dart';


abstract interface class KeyPairMap<K, V> {

  ///  Get all mapped values
  ///
  /// @return values
  Set<V> get items;

  ///  Get value by key pair (remote, local)
  ///
  /// @param remote - remote address
  /// @param local  - local address
  /// @return mapped value
  V? getItem({K? remote, K? local});

  ///  Set value by key pair (remote, local)
  ///
  /// @param remote - remote address
  /// @param local  - local address
  /// @param value  - mapping value
  void setItem(V? value, {K? remote, K? local});

  ///  Remove mapping by key pair (remote, local)
  ///
  /// @param remote - remote address
  /// @param local  - local address
  /// @param value  - mapped value (Optional)
  /// @return removed value
  V? removeItem(V? value, {K? remote, K? local});

}


abstract class WeakKeyPairMap<K, V> implements KeyPairMap<K, V> {
  WeakKeyPairMap(K any) {
    _defaultKey = any;
    _map = {};
  }

  late final K _defaultKey;

  // because the remote address will always different to local address, so
  // we shared the same map for all directions here:
  //    mapping: (remote, local) => Connection
  //    mapping: (remote, null) => Connection
  //    mapping: (local, null) => Connection
  late final Map<K, Map<K, V>> _map;

  @override
  V? getItem({K? remote, K? local}) {
    K? key1, key2;
    if (remote == null) {
      assert(local != null, 'local & remote addresses should not empty at the same time');
      key1 = local;
      key2 = null;
    } else {
      key1 = remote;
      key2 = local;
    }
    Map<K, V>? table = _map[key1];
    if (table == null) {
      return null;
    }
    V? value;
    if (key2 != null) {
      // mapping: (remote, local) => Connection
      value = table[key2];
      if (value != null) {
        return value;
      }
      // take any Connection connected to remote
      return table[_defaultKey];
    }
    // mapping: (remote, null) => Connection
    // mapping: (local, null) => Connection
    value = table[_defaultKey];
    if (value != null) {
      // take the value with empty key2
      return value;
    }
    // take any Connection connected to remote / bound to local
    for (V? v in table.values) {
      if (v != null) {
        return v;
      }
    }
    return null;
  }

  @override
  void setItem(V? value, {K? remote, K? local}) {
    // create indexes with key pair (remote, local)
    K? key1, key2;
    if (remote == null) {
      assert(local != null, 'local & remote addresses should not empty at the same time');
      key1 = local;
      key2 = _defaultKey;
    } else if (local == null) {
      key1 = remote;
      key2 = _defaultKey;
    } else {
      key1 = remote;
      key2 = local;
    }
    Map<K, V>? table = _map[key1];
    if (table != null) {
      if (value == null) {
        table.remove(key2);
      } else {
        table[key2!] = value;
      }
    } else if (value != null) {
      table = WeakValueMap();
      table[key2!] = value;
      _map[key1!] = table;
    }
  }

  @override
  V? removeItem(V? value, {K? remote, K? local}) {
    // remove indexes with key pair (remote, local)
    K? key1, key2;
    if (remote == null) {
      assert(local != null, 'local & remote addresses should not empty at the same time');
      key1 = local;
      key2 = _defaultKey;
    } else if (local == null) {
      key1 = remote;
      key2 = _defaultKey;
    } else {
      key1 = remote;
      key2 = local;
    }
    Map<K, V>? table = _map[key1];
    return table?.remove(key2);
  }

}


class HashKeyPairMap<K, V> extends WeakKeyPairMap<K, V> {
  HashKeyPairMap(super.any);

  final Set<V> _values = {};

  @override
  Set<V> get items => _values.toSet();

  @override
  void setItem(V? value, {K? remote, K? local}) {
    if (value != null) {
      // the caller may create different values with same pair (remote, local)
      // so here we should try to remove it first to make sure it's clean
      _values.remove(value);
      // cache it
      _values.add(value);
    }
    // create indexes
    super.setItem(value, remote: remote, local: local);
  }

  @override
  V? removeItem(V? value, {K? remote, K? local}) {
    // remove indexes
    V? old = super.removeItem(value, remote: remote, local: local);
    if (old != null) {
      _values.remove(old);
    }
    // clear cached value
    if (value != null && value != old) {
      _values.remove(value);
    }
    return old ?? value;
  }

}


class AddressPairMap<V> extends HashKeyPairMap<SocketAddress, V> {
  AddressPairMap() : super(anyAddress);

  static final SocketAddress anyAddress = InetSocketAddress('0.0.0.0', 0);

}
