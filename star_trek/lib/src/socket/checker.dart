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
import 'dart:io';
import 'dart:typed_data';

import '../nio/address.dart';
import '../nio/channel.dart';
import '../nio/exception.dart';
import '../nio/selectable.dart';
import 'channel.dart';


abstract interface class ChannelChecker<C extends SelectableChannel> {

  // 1. check E_AGAIN
  //    the socket will raise 'Resource temporarily unavailable'
  //    when received nothing in non-blocking mode,
  //    or buffer overflow while sending too many bytes,
  //    here we should ignore this exception.
  // 2. check timeout
  //    in blocking mode, the socket will wait until send/received data,
  //    but if timeout was set, it will raise 'timeout' error on timeout,
  //    here we should ignore this exception
  IOException? checkError(IOException error, C sock);

  // 1. check timeout
  //    in blocking mode, the socket will wait until received something,
  //    but if timeout was set, it will return nothing too, it's normal;
  //    otherwise, we know the connection was lost.
  IOException? checkData(Uint8List? data, C sock);

}

class BaseChannelChecker<C extends SelectableChannel> extends ChannelChecker<C> {

  @override
  IOException? checkError(IOException error, C sock) {
    // TODO: check 'E_AGAIN' & TimeoutException
    return error;
  }

  @override
  IOException? checkData(Uint8List? data, C sock) {
    // TODO: check Timeout for received nothing
    if (data == null && sock.isClosed) {
      return ClosedChannelException();
    }
    return null;
  }

}


///  Socket Channel Controller
///  ~~~~~~~~~~~~~~~~~~~~~~~~~
///
///  Reader, Writer, ErrorChecker
abstract class ChannelController<C extends SelectableChannel>
    implements ChannelChecker<C> {
  ChannelController(BaseChannel<C> channel) {
    _channelRef = WeakReference(channel);
    _checker = createChecker();
  }

  late final WeakReference<BaseChannel<C>> _channelRef;
  late final ChannelChecker<C> _checker;

  BaseChannel<C>? get channel => _channelRef.target;

  SocketAddress? get remoteAddress => channel?.remoteAddress;
  SocketAddress? get localAddress => channel?.localAddress;

  C? get socket => channel?.socket;

  //
  //  Checker
  //

  @override
  IOException? checkError(IOException error, C sock) =>
      _checker.checkError(error, sock);

  @override
  IOException? checkData(Uint8List? data, C sock) =>
      _checker.checkData(data, sock);

  // protected
  ChannelChecker<C> createChecker() => BaseChannelChecker<C>();

}


abstract class ChannelReader<C extends SelectableChannel>
    extends ChannelController<C>
    implements SocketReader {

  ChannelReader(super.channel);

  // protected
  Future<Uint8List?> tryRead(int maxLen, C sock) async {
    try {
      ReadableByteChannel channel = sock as ReadableByteChannel;
      return await channel.read(maxLen);
    } on IOException catch (error) {
      IOException? ex = checkError(error, sock);
      if (ex != null) {
        // connection lost?
        throw ex;
      }
      // received nothing
      return null;
    }
  }

  @override
  Future<Uint8List?> read(int maxLen) async {
    C? sock = socket;
    if (sock == null) {
      throw ClosedChannelException();
    } else {
      assert(sock is ReadableByteChannel, 'socket error, cannot read data: $sock');
    }
    Uint8List? data = await tryRead(maxLen, sock);
    // check data
    IOException? ex = checkData(data, sock);
    if (ex != null) {
      // connection lost?
      throw ex;
    }
    // OK
    return data;
  }

}

abstract class ChannelWriter<C extends SelectableChannel>
    extends ChannelController<C>
    implements SocketWriter {

  ChannelWriter(super.channel);

  // protected
  Future<int> tryWrite(Uint8List data, C sock) async {
    try {
      WritableByteChannel channel = sock as WritableByteChannel;
      return await channel.write(data);
    } on IOException catch (error) {
      IOException? ex = checkError(error, sock);
      if (ex != null) {
        // connection lost?
        throw ex;
      }
      // buffer overflow!
      return 0;
    }
  }

  @override
  Future<int> write(Uint8List src) async {
    C? sock = socket;
    if (sock == null) {
      throw ClosedChannelException();
    } else {
      assert(sock is WritableByteChannel, 'socket error, cannot write data: ${src.lengthInBytes} byte(s)');
    }
    int sent = 0;
    int rest = src.length;
    int cnt;
    while (true) {  // while (sock.isOpen)
      cnt = await tryWrite(src, sock);
      // check send result
      if (cnt <= 0) {
        // buffer overflow?
        break;
      }
      // something sent, check remaining data
      sent += cnt;
      rest -= cnt;
      if (rest <= 0) {
        // done!
        break;
      } else {
        // remove sent part
        src = src.sublist(cnt);
      }
    }
    // OK
    if (sent > 0) {
      return sent;
    } else  if (cnt < 0) {
      assert(cnt == -1, 'sent error: $cnt');
      return -1;
    } else {
      return  0;
    }
  }

}
