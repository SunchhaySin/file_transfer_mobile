import 'package:flutter_riverpod/legacy.dart';
import 'package:file_transfer_mobile/utils/peer_discovery.dart';

class PeerNotifier extends StateNotifier<List<Peer>> {
  PeerNotifier() : super([]);
  PeerDiscovery? peerDiscovery;

  Future<void> start({
    required String deviceId,
    required String deviceName,
    required int port,
  }) async {
    await stop();

    peerDiscovery = PeerDiscovery(myDeviceId: deviceId, myDeviceName: deviceName, myPort: port);
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

  Future<void> stop() async {
    await peerDiscovery?.stop();
    state = [];
  }

  @override
  void dispose() {
    peerDiscovery?.stop();
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