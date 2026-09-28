import 'package:flutter_riverpod/legacy.dart';
import 'package:file_transfer_mobile/utils/transfer/send_data_stream.dart';
import 'package:file_transfer_mobile/utils/socket_services/peer_discovery.dart';

enum TransferStatus { idle, connecting, sending, completed, failed, declined }

class TransferRequest {
  final String senderDeviceId;
  final List<dynamic> uploads;
  // final String fileName;
  // final int fileSize;
  // final String extension;

  const TransferRequest({
    required this.senderDeviceId,
    required this.uploads,
    // required this.fileName,
    // required this.fileSize,
    // required this.extension,
  });
}

class TransferState {
  final TransferStatus status;
  final double progress; // 0.0 to 1.0
  // final String? fileName;
  final List<dynamic>? uploads;
  final String? errorMessage;
  final TransferRequest? activeRequest;

  const TransferState({
    this.status = TransferStatus.idle,
    this.progress = 0.0,
    // this.fileName,
    this.uploads,
    this.errorMessage,
    this.activeRequest,
  });

  TransferState copyWith({
    TransferStatus? status,
    double? progress,
    // String? fileName,
    List<dynamic>? uploads,
    String? errorMessage,
    TransferRequest? activeRequest,
    bool clearRequest = false,
  }) {
    return TransferState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      // fileName: fileName ?? this.fileName,
      uploads: uploads,
      errorMessage: errorMessage ?? this.errorMessage,
      activeRequest: clearRequest ? null : (activeRequest ?? this.activeRequest),
    );
  }
}

class TransferNotifier extends StateNotifier<TransferState> {
  TransferNotifier() : super(const TransferState());

  final SendDataStream sender = SendDataStream();

  // void setIncomingRequest(TransferRequest request) {
  //   state = state.copyWith(
  //     status: TransferStatus.connecting,
  //     // fileName: request.fileName,
  //     uploads: request.uploads,
  //     activeRequest: request,
  //   );
  // }

  // void clearRequest() {
  //   state = state.copyWith(clearRequest: true);
  // }

  // Future<void> sendFiles({
  //   required Peer peer,
  //   required String myDeviceId,
  //   required String myDeviceName,
  //   required List<dynamic> uploads,
  // }) async {
    
  // }

  Future<void> sendFiles({
    required Peer peer,
    required String myDeviceId,
    required String myDeviceName,
    // required File file,
    required List<dynamic> uploads,
    // required String fileName,
    // required String extension,
  }) async {
    // final fileSize = await file.length();
    state = TransferState(status: TransferStatus.connecting, uploads: uploads);

    final outgoingRequest = TransferRequest(
      senderDeviceId: myDeviceId,
      // fileName: fileName,
      // fileSize: fileSize,
      // extension: extension,
      uploads: uploads,
    );

    state = TransferState(
      status: TransferStatus.connecting,
      // fileName: fileName,
      uploads: uploads,
      activeRequest: outgoingRequest,
    );

    try {
      final bool isSuccess = await sender.sendFile(
        peerIp: peer.ip,
        peerPort: peer.port,
        myDeviceId: myDeviceId,
        myDeviceName: myDeviceName,
        uploads: uploads ,
        // file: file,
        // fileName: fileName,
        // extension: extension,
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