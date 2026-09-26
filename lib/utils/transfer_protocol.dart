// Construct a JSON shaped message used for file processing and handling

enum MessageType { handshake, fileMeta, fileChunk, transferComplete }

/// Sent first, right after the socket connects.
Map<String, dynamic> buildHandshake({
  required String deviceId,
  String? deviceName,
  required String pubicKey,
}) {
  return {
    'type': 'handshake',
    'deviceId': deviceId,
    if (deviceName != null) 'deviceName': deviceName,
    'publicKey': pubicKey,
  };
}

Map<String, dynamic> buildTransferRequest({
  required String fileName,
  required int fileSize,
  required String extension,
  required String deviceName,
}) {
  return {
    'type': 'transferRequest',
    'fileName': fileName,
    'fileSize': fileSize,
    'extension': extension,
    'deviceName': deviceName,

  };
}

Map<String, dynamic> buildTransferResponse({
  required bool accepted,
  String? reason,
}) {
  return {
    'type': 'transferResponse',
    'accepted': accepted,
    if (reason != null) 'reason': reason,
  };
}

// Sent once, before any file chunks — tells the receiver what's coming.
Map<String, dynamic> buildFileMeta({
  required String fileName,
  required int fileSize,
  required String extension,
}) {
  return {
    'type': 'fileMeta',
    'fileName': fileName,
    'fileSize': fileSize,
    'extension': extension,
  };
}

/// Sent once, after all chunks — lets the receiver know the transfer is done.
Map<String, dynamic> buildTransferComplete() {
  return {'type': 'transferComplete'};
}