import 'dart:io';
import 'package:file_transfer_mobile/utils/identify_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_transfer_mobile/providers/peer_provider.dart';
import 'package:file_transfer_mobile/widgets/peer_avatar_icon.dart';
import 'package:file_transfer_mobile/providers/transfer_provider.dart';

class PeerSelectionDialog {
  final List<dynamic> uploadsByExtensions;
  final List<dynamic> allUploads;
  const PeerSelectionDialog({
    required this.uploadsByExtensions,
    required this.allUploads,
  });

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
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Available Devices",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.broadcast_on_personal_outlined,
                      color: Colors.green.shade700,
                      size: 26,
                    ),
                  ],
                ),
                Divider(color: Colors.black54, height: 14),

                Text("Sharing: ${formatUploadsByExtensions()}"),

                SizedBox(height: 8),

                Consumer(
                  builder: (context, ref, _) {
                    final peers = ref.watch(
                      peerProvider,
                    ); // get discovered peers from peer provider

                    return peers.isNotEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 105,
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
                                            selectedPeer?.id == peer.id;

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
                                          child: PeerAvatarIcon(
                                            displayName: displayName,
                                            peerName: peerName,
                                            isSelected: isSelected,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                              Consumer(
                                builder: (context, ref, _) {
                                  final selectedPeer = ref.watch(
                                    selectedPeerProvider,
                                  );

                                  return SizedBox(
                                    height: 20,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          selectedPeer == null
                                              ? Icons.touch_app_outlined
                                              : Icons.offline_share,
                                          size: 16,
                                          color: selectedPeer == null
                                              ? Colors.black45
                                              : Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            selectedPeer == null
                                                ? "Select a device"
                                                : "Sharing with ${prettifyHostname(selectedPeer.ip)}",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: selectedPeer == null
                                                  ? Colors.black45
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(10),
                                        side: BorderSide(color: Colors.black54),
                                        backgroundColor: Color.fromARGB(
                                          255,
                                          246,
                                          245,
                                          245,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),

                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.bold,
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
                                      return Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.all(10),
                                            backgroundColor: const Color(
                                              0xFF4CAF50,
                                            ),
                                            foregroundColor: Colors.black,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: selectedPeer == null
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
                                              : () async {
                                                  // Save before dialog gets unmounted
                                                  final transferNotifier = ref
                                                      .read(
                                                        transferProvider
                                                            .notifier,
                                                      );
                                                  final identity = ref.read(
                                                    deviceIdentityProvider,
                                                  );
                                                  final peer = selectedPeer;

                                                  Navigator.pop(dialogContext);

                                                  for (final upload
                                                      in allUploads) {
                                                    final file = File(
                                                      upload.path!,
                                                    );

                                                    await transferNotifier
                                                        .sendFile(
                                                          peer: peer,
                                                          myDeviceId:
                                                              identity.id,
                                                          myDeviceName:
                                                              identity.name,
                                                          file: file,
                                                          fileName: upload.name,
                                                          extension:
                                                              upload
                                                                  .extension ??
                                                              '',
                                                        );
                                                  }
                                                },
                                          child: Text(
                                            "Share",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
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
      ref
          .read(selectedPeerProvider.notifier)
          .clearSelection(); // Part of the Future (showDialog) event
    });
  }
}
