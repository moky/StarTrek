import 'dart:typed_data';

import 'package:startrek/fsm.dart';
import 'package:startrek/startrek.dart';


abstract class BaseGate<H extends Hub>
    extends StarGate {
  BaseGate(super.keeper);

  H? hub;

  //
  //  Docker
  //

  Docker? fetchDocker(List<Uint8List> data, {required SocketAddress remote, SocketAddress? local}) {
    Docker? docker = getDocker(remote: remote, local: local);
    if (docker == null) {
      Connection? conn = hub?.connect(remote: remote, local: local);
      if (conn != null) {
        docker = createDocker(conn, data);
        if (docker == null) {
          assert(false, 'failed to create docker: $remote, $local');
        } else {
          setDocker(docker, remote: remote, local: local);
        }
      }
    }
    return docker;
  }

  @override
  Docker? getDocker({required SocketAddress remote, SocketAddress? local}) =>
      super.getDocker(remote: remote);

  @override
  void setDocker(Docker docker, {required SocketAddress remote, SocketAddress? local}) =>
      super.setDocker(docker, remote: remote);

  @override
  void removeDocker(Docker? docker, {required SocketAddress remote, SocketAddress? local}) =>
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
    await stop();
    await idle();
    _running = true;
    await run();
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
  Future<void> idle() async => await Runner.sleep(128);

  @override
  Future<bool> process() async {
    bool incoming = await hub!.process();
    bool outgoing = await super.process();
    return incoming || outgoing;
  }

}
