import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:file_transfer_mobile/utils/send_data_stream.dart';
import 'package:file_transfer_mobile/utils/peer_discovery.dart';

enum TransferStatus { idle, connecting, sending, completed, failed, declined }

class TransferRequest {
  final String senderDeviceId;
  final String fileName;
  final int fileSize;
  final String extension;

  const TransferRequest({
    required this.senderDeviceId,
    required this.fileName,
    required this.fileSize,
    required this.extension,
  });
}

class TransferState {
  final TransferStatus status;
  final double progress; // 0.0 to 1.0
  final String? fileName;
  final String? errorMessage;
  final TransferRequest? activeRequest;

  const TransferState({
    this.status = TransferStatus.idle,
    this.progress = 0.0,
    this.fileName,
    this.errorMessage,
    this.activeRequest,
  });

  TransferState copyWith({
    TransferStatus? status,
    double? progress,
    String? fileName,
    String? errorMessage,
    TransferRequest? activeRequest,
    bool clearRequest = false,
  }) {
    return TransferState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      fileName: fileName ?? this.fileName,
      errorMessage: errorMessage ?? this.errorMessage,
      activeRequest: clearRequest ? null : (activeRequest ?? this.activeRequest),
    );
  }
}

class TransferNotifier extends StateNotifier<TransferState> {
  TransferNotifier() : super(const TransferState());

  final SendDataStream sender = SendDataStream();

  void setIncomingRequest(TransferRequest request) {
    state = state.copyWith(
      status: TransferStatus.connecting,
      fileName: request.fileName,
      activeRequest: request,
    );
  }

  void clearRequest() {
    state = state.copyWith(clearRequest: true);
  }

  Future<void> sendFiles({
    required Peer peer,
    required String myDeviceId,
    required String myDeviceName,
    required List<dynamic> uploads,
  }) async {
    
  }

  Future<void> sendFile({
    required Peer peer,
    required String myDeviceId,
    required String myDeviceName,
    required File file,
    required String fileName,
    required String extension,
  }) async {
    final fileSize = await file.length();
    state = TransferState(status: TransferStatus.connecting, fileName: fileName);

    final outgoingRequest = TransferRequest(
      senderDeviceId: myDeviceId,
      fileName: fileName,
      fileSize: fileSize,
      extension: extension,
    );

    state = TransferState(
      status: TransferStatus.connecting,
      fileName: fileName,
      activeRequest: outgoingRequest,
    );

    try {
      final bool isSuccess = await sender.sendFile(
        peerIp: peer.ip,
        peerPort: peer.port,
        myDeviceId: myDeviceId,
        myDeviceName: myDeviceName,
        file: file,
        fileName: fileName,
        extension: extension,
        onProgress: (progress) {
          state = state.copyWith(
            status: TransferStatus.sending,
            progress: progress,
          );
        },
      );

     if (isSuccess) {
        state = state.copyWith(
          status: TransferStatus.completed,
          progress: 1.0,
          clearRequest: true,
        );
      } else {
        state = state.copyWith(
          status: TransferStatus.declined,
          errorMessage: 'Transfer request was declined or connection lost.',
        );
      }

      state = state.copyWith(status: TransferStatus.completed, progress: 1.0, clearRequest: true,);
    } catch (e) {
      state = state.copyWith(status: TransferStatus.failed, errorMessage: e.toString(), clearRequest: true,);
    }
  }

  void reset() {
    state = const TransferState(); // clean transfer state
  }
}

final transferProvider = StateNotifierProvider<TransferNotifier, TransferState>((ref) {
  return TransferNotifier();
});