import 'dart:math';
import 'dart:typed_data';
import 'package:file_transfer_mobile/utils/transfer_reciever.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:file_transfer_mobile/utils/tcp_socket.dart';
import 'package:file_transfer_mobile/utils/peer_discovery.dart';

class PeerNotifier extends StateNotifier<List<Peer>> {
  PeerNotifier() : super([]);

  TcpListener? listener; // inilialize the Tcp Listener
  TransferReceiver? receiver;
  PeerDiscovery? peerDiscovery;
  String? deviceId;
  String? deviceName;

  Future<void> start({
    Future<bool> Function(String fileName, int fileSize, String deviceId, String deviceName)? onRequestConsent,
    void Function(double progress)? onProgress,
    void Function(String fileName, Uint8List fileBytes)? onFileComplete,
  }) async {
    await stop();
    
    receiver = TransferReceiver(
      onRequestConsent: onRequestConsent,
      onProgress: onProgress,
      onFileComplete: onFileComplete,
    );

    listener = TcpListener(
      onDataReceived: (client, data) {
        receiver?.handleSocketData(client, data);
      },
      onClientDisconnected: (client) {
        receiver?.handleClientDisconnected(client);
      },
    );

    await listener?.start(); // bind socket first, so we know the real port
    final int? boundPort = listener?.port;
    if (boundPort == null) {
      throw Exception("Failed to bind TCP Listener socket.");
    }

    deviceName = 'Mobile Device'; // default
    deviceId = 'device-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}'; // unique identifiable deviceId for bonsior broadcast and discovery

    peerDiscovery = PeerDiscovery(myDeviceId: deviceId!, myDeviceName: deviceName ?? "Unknown device", myPort: boundPort);
    peerDiscovery!.onPeersChanged = (updatedPeers) {
      state = List.from(updatedPeers);
    };

    await peerDiscovery!.start();
  }

  String resolveDisplayName(String senderDeviceId, String sentName) {
    for (final p in state) {
      if (p.id == senderDeviceId) {
        final cleaned = prettifyHostname(p.ip);
        if (cleaned.isNotEmpty) return cleaned;
      }
    }
    return sentName; // sender not in the peer list, use what it sent
  }

  String prettifyHostname(String host) {
    return host
        .replaceAll(RegExp(r'\d{1,3}(\.\d{1,3}){3}'), '')
        .replaceAll(RegExp(r'\.local\.?', caseSensitive: false), '')
        .replaceAll('-', ' ')
        .trim();
  }
  
  int? get myPort => listener?.port;
  String? get myDeviceId => deviceId; 
  String? get myDeviceName => deviceName;

  Future<void> stop() async {
    await peerDiscovery?.stop();
    await listener?.stop();
    listener = null;
    receiver = null;
  }

  @override
  void dispose() {
    peerDiscovery?.stop();
    listener?.stop();
    super.dispose();
  }
}

final peerProvider = StateNotifierProvider<PeerNotifier, List<Peer>>((ref) {
  return PeerNotifier();
});

// Notifies about selected peer, this is the peer selected to be shared with
class SelectedPeerNotifier extends StateNotifier<Peer?> {
  SelectedPeerNotifier() : super(null); // no peer selected initially

  void selectPeer(Peer peer) {
    state = peer; // replace peers if a different one is select
  }

  void clearSelection() {
    state = null;
  }
}

final selectedPeerProvider = StateNotifierProvider<SelectedPeerNotifier, Peer?>((ref) {
  return SelectedPeerNotifier();
});