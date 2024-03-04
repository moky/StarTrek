import 'dart:typed_data';

import 'package:startrek/fsm.dart';
import 'package:startrek/nio.dart';
import 'package:startrek/startrek.dart';


abstract class BaseGate<H extends Hub>
    extends StarGate {
  BaseGate(super.keeper);

  H? hub;

  //
  //  Docker
  //

  @override
  Docker? getDocker({required SocketAddress remote, SocketAddress? local}) =>
      super.getDocker(remote: remote);

  @override
  void setDocker(Docker docker, {required SocketAddress remote, SocketAddress? local}) =>
      super.setDocker(docker, remote: remote);

  @override
  Docker? removeDocker(Docker? docker, {required SocketAddress remote, SocketAddress? local}) =>
      super.removeDocker(docker, remote: remote);

  // @override
  // Future<void> heartbeat(Connection connection) async {
  //   // let the client to do the job
  //   if (connection is ActiveConnection) {
  //     super.heartbeat(connection);
  //   }
  // }

  @override
  List<Uint8List> cacheAdvanceParty(Uint8List data, Connection connection) {
    // TODO: cache the advance party before decide which docker to use
    List<Uint8List> array = [];
    if (data.isNotEmpty) {
      array.add(data);
    }
    return array;
  }

  @override
  void clearAdvanceParty(Connection connection) {
    // TODO: remove advance party for this connection
  }

}


abstract class AutoGate <H extends Hub>
    extends BaseGate<H> implements Runnable {
  AutoGate(super.keeper);

  bool _running = false;

  bool get isRunning => _running;

  Future<void> start() async {
    if (isRunning) {
      await stop();
      await idle();
    }
    /*await */run();
  }

  Future<void> stop() async => _running = false;

  @override
  Future<void> run() async {
    _running = true;
    while (isRunning) {
      if (await process()) {
        // process() return true,
        // means this thread is busy,
        // so process next task immediately
      } else {
        // nothing to do now,
        // have a rest ^_^
        await idle();
      }
    }
  }

  // protected
  Future<void> idle() async => await Runner.sleep(milliseconds: 128);

  @override
  Future<bool> process() async {
    bool incoming = await hub!.process();
    bool outgoing = await super.process();
    return incoming || outgoing;
  }

}
