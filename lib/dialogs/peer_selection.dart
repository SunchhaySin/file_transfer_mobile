import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_transfer_mobile/providers/peer_provider.dart';
import 'package:file_transfer_mobile/widgets/peer_avatar_icon.dart';

class PeerSelectionDialog {
  final List<dynamic> uploadsByExtensions;

  const PeerSelectionDialog({required this.uploadsByExtensions});

  String formatUploadsByExtensions() {
    const imageExtensions = {'jpg', 'jpeg', 'png', 'heic'};
    const videoExtensions = {'mov', 'mp4'};

    int photoCount = 0;
    int videoCount = 0;
    int fileCount = 0;

    for (final ext in uploadsByExtensions) {
      final normalized = ext.toString().toLowerCase();
      if (imageExtensions.contains(normalized)) {
        photoCount++;
      } else if (videoExtensions.contains(normalized)) {
        videoCount++;
      } else {
        fileCount++;
      }
    }

    final parts = <String>[];
    if (photoCount > 0) {
      parts.add('$photoCount ${photoCount == 1 ? 'photo' : 'photos'}');
    }
    if (videoCount > 0) {
      parts.add('$videoCount ${videoCount == 1 ? 'video' : 'videos'}');
    }
    if (fileCount > 0) {
      parts.add('$fileCount ${fileCount == 1 ? 'file' : 'files'}');
    }

    if (parts.isEmpty) return 'No files';

    if (parts.length == 1) return parts.first;

    return '${parts.sublist(0, parts.length - 1).join(', ')}, ${parts.last}';
  }

  String prettifyHostname(String host) {
    return host
        .replaceAll('.local.', '')
        .replaceAll('.local', '')
        .replaceAll('-', ' ');
  }

  void openDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.only(top: 24, bottom: 12, right: 24, left: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Available Devices",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.broadcast_on_personal_outlined,
                      color: Colors.green.shade700,
                    ),
                  ],
                ),
                Divider(color: Colors.black54, height: 14),

                Text("Sharing: ${formatUploadsByExtensions()}"),

                SizedBox(height: 8),

                Consumer(
                  builder: (context, ref, _) {
                    final peers = ref.watch(peerProvider); // get discovered peers from peer provider

                    return peers.isNotEmpty
                        ? SizedBox(
                            height: 150,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    itemCount: peers.length,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, index) {
                                      final peer = peers[index];
                                      final displayName = prettifyHostname(
                                        peer.ip,
                                      );
                                      final peerName = peer.ip.isNotEmpty
                                          ? prettifyHostname(
                                              peer.ip,
                                            )[0].toUpperCase()
                                          : '?'; // IP contains the actual deviceName from mDNS

                                      // Consumes the provider widgets functions to select/deselect the peers
                                      return Consumer(
                                        builder: (context, ref, _) {
                                          final selectedPeer = ref.watch(
                                            selectedPeerProvider,
                                          );
                                          final isSelected =
                                              selectedPeer?.name == peer.name;

                                          return GestureDetector(
                                            onTap: () {
                                              final notifier = ref.read(
                                                selectedPeerProvider.notifier,
                                              );
                                              if (isSelected) {
                                                notifier.clearSelection();
                                              } else {
                                                notifier.selectPeer(peer);
                                              }
                                            },
                                            child: PeerAvatarIcon(displayName: displayName, peerName: peerName, isSelected: isSelected)
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),

                                SizedBox(height: 4),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        border: Border.all(
                                          color: Colors.black54,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () =>
                                            Navigator.pop(dialogContext),
                                        child: Text(
                                          "Cancel",
                                          style: TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4),

                                    // This consumes the selectedpeer from the peer provider and updates the button's UI
                                    Consumer(
                                      builder: (context, ref, _) {
                                        final selectedPeer = ref.watch(
                                          selectedPeerProvider,
                                        );

                                        return Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.shade200,
                                            ),
                                            color: Colors.green.shade400,
                                          ),
                                          child: InkWell(
                                            onTap: selectedPeer == null
                                                ? () => {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: const Text(
                                                          "No device selected for transfer",
                                                        ),
                                                      ),
                                                    ),
                                                  }
                                                : () {
                                                    Navigator.pop(
                                                      dialogContext,
                                                    );
                                                    // trigger actual send/transfer logic here, using selectedPeer
                                                  },
                                            child: Text(
                                              selectedPeer == null
                                                  ? "Share"
                                                  : "Sharing with ${prettifyHostname(selectedPeer.ip)}",
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(
                            height: 40,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mobile_off_outlined),
                                SizedBox(width: 5),
                                Text(
                                  "No Devices Found on this network",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      ref.read(selectedPeerProvider.notifier).clearSelection(); // Part of the Future (showDialog) event
    });
  }
}
