import 'dart:io';
import 'dart:typed_data';
import 'package:file_transfer_mobile/utils/data_reconstruction.dart';

class TransferReceiver {
  final Map<Socket, FileReconstruction> activeSessions = {};

  final Future<bool> Function(String fileName, int fileSize, String deviceId, String deviceName)? onRequestConsent;
  final void Function(double progress)? onProgress;
  final void Function(String fileName, Uint8List fileBytes)? onFileComplete;

  TransferReceiver({
    this.onRequestConsent,
    this.onProgress,
    this.onFileComplete,
  });

  /// Called whenever TcpListener receives raw socket data
  Future<void> handleSocketData(Socket client, List<int> data) async {
    // Get or create a FileReconstruction instance for this specific socket
    final reconstruction = activeSessions.putIfAbsent(
      client,
      () => FileReconstruction(
        onRequestConsent: (fileName, fileSize, deviceId, deviceName) async {
          return await onRequestConsent?.call(fileName, fileSize, deviceId, deviceName) ?? false;
        },
        onProgress: onProgress,
        onFileComplete: (fileName, fileBytes) {
          // Pass RAM payload to caller
          onFileComplete?.call(fileName, fileBytes);
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