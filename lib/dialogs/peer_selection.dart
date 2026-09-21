import 'package:file_transfer_mobile/utils/peer_discovery.dart';
import 'package:flutter/material.dart';


class PeerSelectionDialog {
  final List<Peer> peers;

  const PeerSelectionDialog({required this.peers});

  void openDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
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

                peers.isNotEmpty
                    ? SizedBox(
                        height: 80,
                        child: ListView.builder(
                          itemCount: peers.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final peer = peers[index];
                            final peerName = peer.ip.isNotEmpty ? peer.ip[0].toUpperCase() : '?';

                            return Center(
                              child: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade700,
                                  ]),
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [BoxShadow(
                                    color: Colors.green.shade300,
                                    spreadRadius: 0.5,
                                    blurRadius: 2,
                                  )]
                                ),
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                child: Center(child: Text(peerName),) 
                              ),
                            );
                          },
                        ),
                      )

                    : const SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mobile_off_outlined),
                            SizedBox(width: 5,),
                            Text(
                              "No Devices Found on this network",
                              style: TextStyle(color: Colors.black87, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
