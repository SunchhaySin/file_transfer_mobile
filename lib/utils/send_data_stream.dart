import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_transfer_mobile/utils/data_processing.dart';
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
      final responseCompleter = Completer<bool>();
      final decoder = MessageDecoder();

      // 1. Listen ONLY for the acceptance response
      final subscription = socket.listen(
        (data) {
          decoder.addData(data, (message) {
            try {
              final json = jsonDecode(utf8.decode(message));
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
          if (!responseCompleter.isCompleted) responseCompleter.complete(false);
        },
        onDone: () {
          if (!responseCompleter.isCompleted) responseCompleter.complete(false);
        },
      );
      
      // Send hanshake to identify the recipient peer
      socket.add(frameJson(buildHandshake(deviceId: myDeviceId)));
      
      // Send Transfer Request
      socket.add(
        frameJson(
          buildTransferRequest(
            fileName: fileName,
            fileSize: fileSize,
            extension: extension,
            deviceName: myDeviceName,
          ),
        ),
      );

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

      // Send file metadata
      socket.add(
        frameJson(
          buildFileMeta(
            fileName: fileName,
            fileSize: fileSize,
            extension: extension,
          ),
        ),
      );
      await socket.flush();

      // Stream binary chunks sequentially
      int sentBytes = 0;
      final fileStream = file.openRead();

      await for (final chunk in fileStream) {
        socket.add(frameMessage(Uint8List.fromList(chunk)));
        sentBytes += chunk.length;
        onProgress?.call(sentBytes / fileSize);
      }

      // Send completion signal
      socket.add(frameJson(buildTransferComplete()));
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