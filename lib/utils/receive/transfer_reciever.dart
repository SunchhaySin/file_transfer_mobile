import 'dart:io';
import 'package:file_transfer_mobile/utils/receive/data_reconstruction.dart';

class TransferReceiver {
  final Map<Socket, FileReconstruction> activeSessions = {};

  // Callbacks
  final Future<bool> Function(List<dynamic> uploads, int totalSize, int fileCount, String deviceId, String deviceName, Socket client)? onRequestConsent;
  final void Function(Socket client, double progress)? onProgress;
  final void Function(Socket client, List<ReceivedFile> files)? onTransferComplete;

  TransferReceiver({
    this.onRequestConsent,
    this.onProgress,
    this.onTransferComplete,
  });

  /// Called whenever TcpListener receives raw socket data
  Future<void> handleSocketData(Socket client, List<int> data) async {
    // Get or create a FileReconstruction instance for this specific socket
    final reconstruction = activeSessions.putIfAbsent(
      client,
      () => FileReconstruction(
        onRequestConsent: (uploads, fileSize, fileCount, deviceId, deviceName) async {
          return await onRequestConsent?.call(uploads, fileSize, fileCount, deviceId, deviceName, client) ?? false;
        },
        onProgress: (progress) {
          onProgress?.call(client, progress);
        },
        onTransferComplete: (files) {
          onTransferComplete?.call(client, files);
          activeSessions.remove(client);
        },
      ),
    );

    try {
      await reconstruction.handleIncomingData(data, client);
    } catch (e) {
      print('Error decoding socket stream from ${client.remoteAddress.address}: $e');
    }
  }

  /// Clean up state when a client disconnects
  void handleClientDisconnected(Socket client) {
    activeSessions.remove(client);
  }
}