import 'package:bonsoir/bonsoir.dart';

const String serviceType = '_p2ptransfer._tcp'; // match with the service name defined in info.plist

class Peer {
  final String id;
  final String deviceName;
  final String ip;
  final int port;

  Peer({required this.id, required this.deviceName, required this.ip, required this.port});

  @override
  String toString() => '$deviceName [$id] ($ip:$port)';
}

class PeerDiscovery {
  final String myDeviceId;
  final String myDeviceName;
  final int myPort;

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  final List<Peer> discoveredPeers = [];

  void Function(List<Peer>)? onPeersChanged;

  PeerDiscovery({required this.myDeviceId, required this.myDeviceName, required this.myPort});

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
      attributes: {
        'deviceName': myDeviceName, 
      },
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
          if (resolved.name == myDeviceId) return; 

          final alreadyKnown = discoveredPeers.any((p) => p.id == resolved.name);
          if (alreadyKnown) return;

          final peerDeviceName = resolved.attributes['deviceName'] ?? 'Unknown Device';

          discoveredPeers.add(Peer(
            id: resolved.name, // the name attribute containes a numerical ID
            deviceName: peerDeviceName,
            ip: resolved.host!,
            port: resolved.port,
          ));
          onPeersChanged?.call(discoveredPeers);
          break;

        case BonsoirDiscoveryServiceLostEvent():
          discoveredPeers.removeWhere((p) => p.id == event.service.name);
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