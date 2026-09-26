import 'dart:typed_data';
import 'package:file_transfer_mobile/utils/transfer_reciever.dart';
import 'package:file_transfer_mobile/utils/tcp_socket.dart';
import 'package:flutter_riverpod/legacy.dart';


// Stores the port being listened on 
class TransferListenerProvider extends StateNotifier<int?> {
  TransferListenerProvider() : super(null);

  TcpListener? _listener;
  TransferReceiver? _receiver;

    Future<int> start({
    Future<bool> Function(String fileName, int fileSize, String deviceId, String deviceName)? onRequestConsent,
    void Function(double progress)? onProgress,
    void Function(String fileName, Uint8List fileBytes)? onFileComplete,
  }) async {
    await stop();

    _receiver = TransferReceiver(
      onRequestConsent: onRequestConsent,
      onProgress: onProgress,
      onFileComplete: onFileComplete,
    );

    _listener = TcpListener(
      onDataReceived: (client, data) => _receiver?.handleSocketData(client, data),
      onClientDisconnected: (client) => _receiver?.handleClientDisconnected(client),
    );

    await _listener!.start();
    final boundPort = _listener!.port;
    if (boundPort == null) {
      throw Exception('Failed to bind TCP Listener socket.');
    }
    state = boundPort;
    return boundPort;
  }

    Future<void> stop() async {
    await _listener?.stop();
    _listener = null;
    _receiver = null;
    state = null;
  }

  @override
  void dispose() {
    _listener?.stop();
    super.dispose();
  }
}

final transferListenerProvider = StateNotifierProvider<TransferListenerProvider, int?>((ref) {
  return TransferListenerProvider();
});