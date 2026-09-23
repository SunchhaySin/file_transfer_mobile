import 'dart:math';
import 'package:flutter_riverpod/legacy.dart';
import 'package:file_transfer_mobile/utils/tcp_socket.dart';
import 'package:file_transfer_mobile/utils/peer_discovery.dart';

class PeerNotifier extends StateNotifier<List<Peer>> {
  PeerNotifier() : super([]);

  PeerDiscovery? peerDiscovery;
  final TcpListener listener = TcpListener(); // inilialize the TcpListneterTest

  Future<void> start() async {
    await listener.start(); // bind socket first, so we know the real port

    final deviceId =
        'device-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}'; // unique identifiable deviceId for bonsior broadcast and discovery

    peerDiscovery = PeerDiscovery(myDeviceId: deviceId, myPort: listener.port!);
    peerDiscovery!.onPeersChanged = (updatedPeers) {
      state = List.from(updatedPeers);
    };

    await peerDiscovery!.start();
  }

  int? get myPort => listener.port;

  Future<void> stop() async {
    await peerDiscovery?.stop();
    await listener.stop();
  }

  @override
  void dispose() {
    peerDiscovery?.stop();
    listener.stop();
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
    state = peer; // replaces whatever was selected before — only one at a time
  }

  void clearSelection() {
    state = null;
  }
}

final selectedPeerProvider = StateNotifierProvider<SelectedPeerNotifier, Peer?>((ref) {
  return SelectedPeerNotifier();
});