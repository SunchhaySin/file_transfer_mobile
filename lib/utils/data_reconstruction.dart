import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_transfer_mobile/utils/data_processing.dart';

class FileReconstruction {
  final MessageDecoder decoder = MessageDecoder();

  // State flags for separated frame sequence
  bool _awaitingHandshake = true;
  bool _awaitingRequest = false;
  bool _awaitingMeta = false;

  String? _peerDeviceId;
  String? expectedFileName;
  int? expectedFileSize;
  int _receivedBytes = 0;

  // In-RAM memory accumulator (No disk writes!)
  final BytesBuilder _ramBuffer = BytesBuilder(copy: false);

  // Callbacks
  final Future<bool> Function(String fileName, int fileSize, String deviceId, String deviceName)? onRequestConsent;
  final void Function(String fileName, int fileSize)? onFileStart;
  final void Function(double progress)? onProgress;
  final void Function(String fileName, Uint8List fileBytes)? onFileComplete;

  FileReconstruction({
    this.onRequestConsent,
    this.onFileStart,
    this.onProgress,
    this.onFileComplete,
  });

  Future<void> handleIncomingData(List<int> data, Socket clientSocket) async {
    decoder.addData(data, (message) async {

      // -----------------------------------------------------------------
      // STEP 1: Process Handshake Frame (Identify Device)
      // -----------------------------------------------------------------
      if (_awaitingHandshake) {
        try {
          final json = jsonDecode(utf8.decode(message));

          if (json['type'] == 'handshake') {
            _peerDeviceId = json['deviceId'] ?? 'unknown_peer';
            print('Handshake received from device: $_peerDeviceId');

            _awaitingHandshake = false;
            _awaitingRequest = true;
          }
        } catch (e) {
          print('Error parsing handshake signal: $e');
        }
        return;
      }

      // -----------------------------------------------------------------
      // STEP 2: Process Transfer Request & Respond
      // -----------------------------------------------------------------
      if (_awaitingRequest) {
        try {
          final json = jsonDecode(utf8.decode(message));

          if (json['type'] == 'transferRequest') {
            expectedFileName = json['fileName'] ?? 'unknown';
            expectedFileSize = json['fileSize'] ?? 0;

            final senderDeviceName = json['deviceName'] ?? _peerDeviceId ?? 'Unknown Device';
            final senderDeviceId = _peerDeviceId ?? 'unknown_peer';
            print('Transfer request from $senderDeviceName ($senderDeviceId): $expectedFileName ($expectedFileSize bytes)');

            // Prompt receiver UI for approval
            final accepted = await onRequestConsent?.call(
                  expectedFileName!,
                  expectedFileSize!,
                  _peerDeviceId ?? 'unknown_peer',
                  senderDeviceName,
                ) ??
                false;

            // Send response back over socket
            final responseSignal = frameJson({
              'type': 'transferResponse',
              'accepted': accepted,
              'reason': accepted ? 'Accepted by user' : 'Declined by user',
            });
            clientSocket.add(responseSignal);
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

      // -----------------------------------------------------------------
      // STEP 3: Receive File Metadata & Prepare RAM Buffer
      // -----------------------------------------------------------------
      if (_awaitingMeta) {
        try {
          final json = jsonDecode(utf8.decode(message));
          if (json['type'] == 'fileMeta') {
            expectedFileName = json['fileName'];
            expectedFileSize = json['fileSize'];
            _receivedBytes = 0;

            _ramBuffer.clear(); // Ensure clean RAM buffer for new stream

            onFileStart?.call(expectedFileName!, expectedFileSize!);
            _awaitingMeta = false;
            print('Ready to buffer incoming binary chunks into RAM.');
          }
        } catch (e) {
          print('Error parsing metadata signal: $e');
        }
        return;
      }

      // -----------------------------------------------------------------
      // STEP 4: Receive Binary Payload Chunks OR Complete Signal
      // -----------------------------------------------------------------
      try {
        final json = jsonDecode(utf8.decode(message));
        if (json['type'] == 'transferComplete') {
          if (_receivedBytes == expectedFileSize) {
            print('All $_receivedBytes bytes received in RAM successfully.');
            
            // Extract complete payload from RAM and trigger completion callback
            final fileBytes = _ramBuffer.takeBytes();
            onFileComplete?.call(expectedFileName!, fileBytes);
          } else {
            print('Transfer failed: received $_receivedBytes / $expectedFileSize bytes');
            _ramBuffer.clear();
          }
          _resetState();
          return;
        }
      } catch (_) {
        // Not JSON — message is a raw binary chunk. Append to RAM buffer!
        _ramBuffer.add(message);
        _receivedBytes += message.length;

        if (expectedFileSize != null && expectedFileSize! > 0) {
          onProgress?.call(_receivedBytes / expectedFileSize!);
        }
      }
    });
  }

  void _resetState() {
    _awaitingHandshake = true;
    _awaitingRequest = false;
    _awaitingMeta = false;
    _peerDeviceId = null;
    expectedFileName = null;
    expectedFileSize = null;
    _receivedBytes = 0;
    _ramBuffer.clear();
  }
}