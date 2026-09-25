import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_transfer_mobile/utils/data_processing.dart';
import 'package:file_transfer_mobile/utils/security/encryption.dart';
import 'package:file_transfer_mobile/utils/transfer_protocol.dart';

class SendDataStream {
  Future<bool> sendFile({
    required String peerIp,
    required int peerPort,
    required String myDeviceId,
    required String myDeviceName,
    required File file,
    required String fileName,
    required String extension,
    void Function(double progress)? onProgress,
  }) async {
    Socket? socket;

    try {
      socket = await Socket.connect(
        peerIp,
        peerPort,
        timeout: const Duration(seconds: 5),
      );
      print('Connected to $peerIp');

      final fileSize = await file.length();
      final decoder = MessageDecoder();
      final encryptionService = DataEncryptionService();

      final responseCompleter = Completer<bool>();
      final handshakeCompleter = Completer<String>(); // peer's public key
      var sendCounter = 0; // increments for every message WE encrypt

      // Actively listens for incoming transfer requests for peers
      final subscription = socket.listen(
        (data) {
          decoder.addData(data, (message) async {
            // Get the receriving peer's publicKey from the handshake process
            if(!handshakeCompleter.isCompleted) {
              try {
                final json = jsonDecode(utf8.decode(message));
                if (json['type'] == 'handshake') {
                  final key = json['publicKey'] as String?;
                  if (key != null) {
                    handshakeCompleter.complete(key);
                  } else {
                    handshakeCompleter.completeError('Missing publicKey in handshake reply');
                  }
                }
              } catch (e) {
                print('Error decoding handshake reply: $e');
                handshakeCompleter.completeError(e);
              }
              return;
            }

            try {
              final decrypted = await encryptionService.decryptChunk(Uint8List.fromList(message));
              final json = jsonDecode(utf8.decode(decrypted));
              if (json['type'] == 'transferResponse') {
                final accepted = json['accepted'] == true;
                if (!responseCompleter.isCompleted) {
                  responseCompleter.complete(accepted);
                }
              }
            } catch (e) {
              print('Error decoding response signal: $e');
              if (!responseCompleter.isCompleted) {
                responseCompleter.complete(false);
              }
            }
          });
        },
        onError: (error) {
          print('Socket error: $error');
          if (!handshakeCompleter.isCompleted) handshakeCompleter.completeError(error);
          if (!responseCompleter.isCompleted) responseCompleter.complete(false);
        },
        onDone: () {
          if (!responseCompleter.isCompleted) responseCompleter.complete(false);
        },
      );
      
      // Get publicKey from the DataEncryptionService
      final myPublicKey = await encryptionService.generatePublicKey();

      // Send hanshake to identify the recipient peer (myDeviceId, myPublicKey)
      socket.add(frameJson(buildHandshake(deviceId: myDeviceId, pubicKey: myPublicKey)));
      
      // Wait for the receiver's handshake reply, which must also carry publicKey
      final peerPublicKey = await handshakeCompleter.future;
      await encryptionService.deriveSessionKeys(peerPublicKey, isSender: true);

      // Send Transfer Request (encrypted)

      final requestBytes = utf8.encode(jsonEncode(buildTransferRequest(
        fileName: fileName,
        fileSize: fileSize,
        extension: extension,
        deviceName: myDeviceName,
      )));

      socket.add(frameMessage(await encryptionService.encryptChunk(requestBytes, sendCounter++)));

      await socket.flush();
      print('Handshake and Transfer Request sent. Awaiting peer response...');

      // Pause and wait for peer acceptance signal
      final accepted = await responseCompleter.future;

      // Pause listener stream so it doesn't interfere with streaming logic
      await subscription.cancel();

      if (!accepted) {
        print('Peer declined transfer request.');
        return false;
      }

      print('Peer accepted transfer! Starting binary stream...');

      // Send file metadata (encrypted)
      final metaBytes = utf8.encode(jsonEncode(buildFileMeta(
        fileName: fileName,
        fileSize: fileSize,
        extension: extension,
      )));

      socket.add(frameMessage(await encryptionService.encryptChunk(metaBytes, sendCounter++)));
      await socket.flush();

      // Stream binary chunks sequentially
      int sentBytes = 0;
      final fileStream = file.openRead();

      await for (final chunk in fileStream) {
        final encryptedChunk = await encryptionService.encryptChunk(chunk, sendCounter++); // ecrypts each chunk
        socket.add(frameMessage(encryptedChunk));
        sentBytes += chunk.length;
        onProgress?.call(sentBytes / fileSize);
      }

      // Send completion signal (encrypted)
      final completeBytes = utf8.encode(jsonEncode(buildTransferComplete()));
      socket.add(frameMessage(await encryptionService.encryptChunk(completeBytes, sendCounter++)));
      await socket.flush();
      print('File streaming finished successfully.');

      return true;
    } catch (e) {
      print('Failed to send file: $e');
      return false;
    } finally {
      await socket?.close();
      print("Socket Closed");
    }
  }
}