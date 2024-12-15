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
  Porter? getPorter({required SocketAddress remote, SocketAddress? local}) =>
      super.getPorter(remote: remote);

  @override
  Porter? setPorter(Porter porter, {required SocketAddress remote, SocketAddress? local}) =>
      super.setPorter(porter, remote: remote);

  @override
  Porter? removePorter(Porter? porter, {required SocketAddress remote, SocketAddress? local}) =>
      super.removePorter(porter, remote: remote);

  // @override
  // Future<void> heartbeat(Connection connection) async {
  //   // let the client to do the job
  //   if (connection is ActiveConnection) {
  //     super.heartbeat(connection);
  //   }
  // }

}


abstract class AutoGate <H extends Hub>
    extends BaseGate<H> implements Runnable {
  AutoGate(super.keeper);

  final Duration _interval = Duration(milliseconds: 128);

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
  Future<void> idle() async => await Runner.sleep(_interval);

  @override
  Future<bool> process() async {
    bool incoming = await hub!.process();
    bool outgoing = await super.process();
    return incoming || outgoing;
  }

}
