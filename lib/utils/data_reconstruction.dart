import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_transfer_mobile/utils/data_processing.dart';
import 'package:file_transfer_mobile/utils/security/encryption.dart';

class FileReconstruction {
  final MessageDecoder decoder = MessageDecoder();
  final DataEncryptionService encryptionService = DataEncryptionService();

  // State flags for separated frame sequence
  bool _awaitingHandshake = true;
  bool _awaitingRequest = false;
  bool _awaitingMeta = false;

  String? _peerDeviceId;
  String? expectedFileName;
  int? expectedFileSize;
  int _receivedBytes = 0;
  int _sendCounter = 0; // used to pass into encrypt function - each message must have a different counter attached

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
      // STEP 1: Process Handshake Frame (Identify Device), reply with own public key back to sender
      // -----------------------------------------------------------------
      if (_awaitingHandshake) {
        try {
          final json = jsonDecode(utf8.decode(message));

          if (json['type'] == 'handshake') {
            _peerDeviceId = json['deviceId'] ?? 'unknown_peer';
            final peerPublicKey = json['publicKey'] as String?;
            print('Handshake received from device: $_peerDeviceId');

            if (peerPublicKey == null) {
              print('Handshake missing publicKey — cannot establish secure channel.');
              clientSocket.destroy();
              return;
            }

            // Reply with our own public key
            final myPublicKey = await encryptionService.generatePublicKey();
            clientSocket.add(frameJson({
              'type': 'handshake',
              'publicKey': myPublicKey,
            }));

            await clientSocket.flush();

            // Derive session keys — receiver side
            await encryptionService.deriveSessionKeys(peerPublicKey, isSender: false);

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
        decrypted = await encryptionService.decryptChunk(Uint8List.fromList(message));
      } catch (e) {
        print('Failed to decrypt incoming message: $e');
        clientSocket.destroy();
        return;
      }

      // Process Transfer Request & Respond
      if (_awaitingRequest) {
        try {
          final json = jsonDecode(utf8.decode(decrypted)); // working from the decrypted message data 

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

            // Send (encrypted) response back over socket
            final responseMessage = utf8.encode(jsonEncode({
              'type': 'transferResponse',
              'accepted': accepted,
              'reason': accepted ? 'Accepted by user' : 'Declined by user',
            }));

            final encryptedResponse = await encryptionService.encryptChunk(responseMessage, _sendCounter++);
            clientSocket.add(frameMessage(encryptedResponse));
            // final responseSignal = frameJson({
            //   'type': 'transferResponse',
            //   'accepted': accepted,
            //   'reason': accepted ? 'Accepted by user' : 'Declined by user',
            // });

            // clientSocket.add(responseSignal);

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
          final json = jsonDecode(utf8.decode(decrypted));
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
        final json = jsonDecode(utf8.decode(decrypted));
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
        _ramBuffer.add(decrypted);
        _receivedBytes += decrypted.length;

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
    _sendCounter = 0;
    _ramBuffer.clear();
  }
}