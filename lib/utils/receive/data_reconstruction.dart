import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_transfer_mobile/utils/data_processing.dart';
import 'package:file_transfer_mobile/utils/security/encryption.dart';

class ReceivedFile {
  final String fileName;
  final Uint8List fileBytes;

  ReceivedFile({required this.fileName, required this.fileBytes});
}

class FileReconstruction {
  final MessageDecoder decoder = MessageDecoder();
  final DataEncryptionService encryptionService = DataEncryptionService();

  // State flags for separated frame sequence
  bool _awaitingHandshake = true;
  bool _awaitingRequest = false;
  bool _awaitingMeta = false;

  String? _peerDeviceId;

  // Batch file (List)
  int? expectedTotalFileSize; // total size (bulk)
  List<dynamic>? expectedFiles; // list of all files expected to receive
  int? expectedFileCount;
  int _totalReceivedBytes = 0;

  // Individual Files
  String? expectedFileName;
  int? expectedFileSize;

  // Tracks progress
  int _receivedBytes = 0;
  int _completedFileCount = 0;
  double _lastReportedProgress = 0.0;

  int _sendCounter = 0; // used to pass into encrypt function - each message must have a different counter attached

  // In-RAM memory accumulator (No disk writes!)
  final BytesBuilder _ramBuffer = BytesBuilder(copy: false);

  final List<ReceivedFile> _completedFiles = [];

  // Callbacks
  final Future<bool> Function(
    List<dynamic> uploads,
    int totalSize,
    int fileCount,
    String deviceId,
    String deviceName,
  )?
  onRequestConsent;
  final void Function(double progress)? onProgress;
  final void Function(List<ReceivedFile> files)? onTransferComplete;

  FileReconstruction({
    this.onRequestConsent,
    this.onProgress,
    this.onTransferComplete,
  });

  Future<void> handleIncomingData(List<int> data, Socket clientSocket) async {
    await decoder.addData(data, (message) async {
      
      // Process Handshake Frame (Identify Device), reply with own public key back to sender
      if (_awaitingHandshake) {
        try {
          final json = jsonDecode(utf8.decode(message));

          if (json['type'] == 'handshake') {
            _peerDeviceId = json['deviceId'] ?? 'unknown_peer';
            final peerPublicKey = json['publicKey'] as String?;
            print('Handshake received from device: $_peerDeviceId');

            if (peerPublicKey == null) {
              print(
                'Handshake missing publicKey — cannot establish secure channel.',
              );
              clientSocket.destroy();
              return;
            }

            // Reply with our own public key
            final myPublicKey = await encryptionService.generatePublicKey();
            clientSocket.add(
              frameJson({'type': 'handshake', 'publicKey': myPublicKey}),
            );

            await clientSocket.flush();

            // Derive session keys — receiver side
            await encryptionService.deriveSessionKeys(
              peerPublicKey,
              isSender: false,
            );

            _awaitingHandshake = false;
            _awaitingRequest = true;
          }
        } catch (e) {
          print('Error parsing handshake signal: $e');
        }
        return;
      }

      // Data Decryption
      final Uint8List decrypted;
      try {
        decrypted = await encryptionService.decryptChunk(
          Uint8List.fromList(message),
        );
      } catch (e) {
        print('Failed to decrypt incoming message: $e');
        clientSocket.destroy();
        return;
      }

      // Process Transfer Request & Respond
      if (_awaitingRequest) {
        try {
          final json = jsonDecode(
            utf8.decode(decrypted),
          ); // working from the decrypted message data

          if (json['type'] == 'transferRequest') {
            expectedFiles = json['files'] ?? [];
            expectedTotalFileSize = json['totalSize'] ?? 0;
            expectedFileCount = json['fileCount'] ?? 0;

            final senderDeviceName =
                json['deviceName'] ?? _peerDeviceId ?? 'Unknown Device';
            final senderDeviceId = _peerDeviceId ?? 'unknown_peer';
            print(
              'Transfer request from $senderDeviceName ($senderDeviceId): $expectedFileCount files, ($expectedTotalFileSize bytes)',
            );

            // Prompt receiver UI for approval
            final accepted =
                await onRequestConsent?.call(
                  expectedFiles!,
                  expectedTotalFileSize!,
                  expectedFileCount!,
                  _peerDeviceId ?? 'unknown_peer',
                  senderDeviceName,
                ) ??
                false;

            // Send (encrypted) response back over socket
            final responseMessage = utf8.encode(
              jsonEncode({
                'type': 'transferResponse',
                'accepted': accepted,
                'reason': accepted ? 'Accepted by user' : 'Declined by user',
              }),
            );

            final encryptedResponse = await encryptionService.encryptChunk(
              responseMessage,
              _sendCounter++,
            );
            clientSocket.add(frameMessage(encryptedResponse));

            await clientSocket.flush();

            if (accepted) {
              _awaitingRequest = false;
              _awaitingMeta = true;
              print('Transfer accepted by user. Awaiting file metadata...');
            } else {
              print('Transfer declined by user. Closing socket.');
              clientSocket.destroy();
            }
          }
        } catch (e) {
          print('Error parsing request signal: $e');
        }
        return;
      }

      // Detects message from socket for transfer complete signal
      bool isTransferComplete = false;

      try {
        final json = jsonDecode(utf8.decode(decrypted));

        if (json['type'] == 'transferComplete') {
          isTransferComplete = true;
        }
      } catch (_) {
        // Not JSON — this is a raw binary file chunk.
      }

      // Call onTransferComplete if the signal comes through
      if (isTransferComplete) {
        if (_completedFileCount == expectedFileCount) {
          print(
            'All files received successfully: '
            '$_completedFileCount / $expectedFileCount',
          );

          onTransferComplete?.call(_completedFiles);
        } else {
          print(
            'Transfer failed: '
            '$_completedFileCount / $expectedFileCount files completed.',
          );

          _ramBuffer.clear();
        }

        _resetState();
        return;
      }

      if (_awaitingMeta) {
        try {
          final json = jsonDecode(utf8.decode(decrypted));

          if (json['type'] == 'fileMeta') {
            expectedFileName = json['fileName'];
            expectedFileSize = json['fileSize'];
            _receivedBytes = 0;

            _ramBuffer.clear();
            _awaitingMeta = false;

            print('Ready to receive ${expectedFileName!}.');
          }
        } catch (e) {
          print('Error parsing metadata signal: $e');
        }

        return;
      }

      // Decrypt incoming data and sace directly into RAM chunk by chunk
      _ramBuffer.add(decrypted);
      _receivedBytes += decrypted.length;
      _totalReceivedBytes += decrypted.length;
      
      if (expectedTotalFileSize != null && expectedTotalFileSize! > 0) {
        final progress = _totalReceivedBytes / expectedTotalFileSize!;

        // only update the progress in increments of 5% of the file actual size 
        // keeps progress bar working reletively smoothly
        if (progress - _lastReportedProgress >= 0.05 || progress >= 1.0) {
          _lastReportedProgress = progress;
          onProgress?.call(progress);
        }
      }

      // Check whether the CURRENT file has finished.
      if (_receivedBytes == expectedFileSize) {
        print(
          'File completed: $expectedFileName ($_receivedBytes / $expectedFileSize bytes)',
        );

        final fileBytes = _ramBuffer.takeBytes();

        _completedFiles.add(
          ReceivedFile(fileName: expectedFileName!, fileBytes: fileBytes),
        );

        _completedFileCount++;

        // await for next file's metadata if transfer is not complete.
        _awaitingMeta = true;

        print('Completed $_completedFileCount / $expectedFileCount files.');
      }
    });
  }

  void _resetState() {
    _awaitingHandshake = true;
    _awaitingRequest = false;
    _awaitingMeta = false;
    _peerDeviceId = null;

    expectedFiles = null;
    expectedTotalFileSize = null;
    expectedFileCount = null;

    expectedFileName = null;
    expectedFileSize = null;

    _receivedBytes = 0;
    _totalReceivedBytes = 0;
    _completedFileCount = 0;

    _sendCounter = 0;
    _ramBuffer.clear();
  }
}
