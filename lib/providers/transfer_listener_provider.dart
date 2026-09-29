import 'dart:io';
import 'package:file_transfer_mobile/utils/receive/data_reconstruction.dart';
import 'package:file_transfer_mobile/utils/receive/transfer_reciever.dart';
import 'package:file_transfer_mobile/utils/socket_services/tcp_socket.dart';
import 'package:flutter_riverpod/legacy.dart';


// Stores the port being listened on 
class TransferListenerProvider extends StateNotifier<int?> {
  TransferListenerProvider() : super(null);

  TcpListener? _listener;
  TransferReceiver? _receiver;

    Future<int> start({
    Future<bool> Function(List<dynamic> uploads, int totalSize, int fileCount, String deviceId, String deviceName, Socket client)? onRequestConsent,
    void Function(Socket client, double progress)? onProgress,
    void Function(Socket client, List<ReceivedFile> files)? onTransferComplete,
  }) async {
    await stop();

    _receiver = TransferReceiver(
      onRequestConsent: onRequestConsent,
      onProgress: onProgress,
      onTransferComplete: onTransferComplete,
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