import 'package:bonsoir/bonsoir.dart';

const String serviceType = '_p2ptransfer._tcp'; // match with the service name defined in info.plist

class Peer {
  final String name;
  final String ip;
  final int port;

  Peer({required this.name, required this.ip, required this.port});

  @override
  String toString() => '$name ($ip:$port)';
}

class PeerDiscovery {
  final String myDeviceId;
  final int myPort;

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  final List<Peer> discoveredPeers = [];

  void Function(List<Peer>)? onPeersChanged;

  PeerDiscovery({required this.myDeviceId, required this.myPort});

  // Simutanously Broadcast and discover at the same time 
  Future<void> start() async {
    await _startBroadcast();
    await _startDiscovery();
  }

  Future<void> _startBroadcast() async {
    final service = BonsoirService(
      name: myDeviceId,
      type: serviceType,
      port: myPort,
    );

    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.initialize();
    await _broadcast!.start();
  }

  Future<void> _startDiscovery() async {
    _discovery = BonsoirDiscovery(type: serviceType);
    await _discovery!.initialize(); 

    _discovery!.eventStream!.listen((event) {
      switch (event) {
        case BonsoirDiscoveryServiceFoundEvent():
          event.service.resolve(_discovery!.serviceResolver);
          break;

        case BonsoirDiscoveryServiceResolvedEvent():
          final resolved = event.service;
          if (resolved == null) return;
          if (resolved.name == myDeviceId) return; 

          final alreadyKnown = discoveredPeers.any((p) => p.name == resolved.name);
          if (alreadyKnown) return;

          discoveredPeers.add(Peer(
            name: resolved.name,
            ip: resolved.host!,
            port: resolved.port,
          ));
          onPeersChanged?.call(discoveredPeers);
          break;

        case BonsoirDiscoveryServiceLostEvent():
          discoveredPeers.removeWhere((p) => p.name == event.service.name);
          onPeersChanged?.call(discoveredPeers);
          break;

        default:
          // BonsoirDiscoveryServiceUpdatedEvent and others — ignore for now
          break;
      }
    });

    await _discovery!.start();
  }

  Future<void> stop() async {
    await _broadcast?.stop();
    await _discovery?.stop();
  }
}