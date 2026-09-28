// Construct a JSON shaped message used for file processing and handling

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
  required int fileCount,
  required int totalSize,
  required String deviceName,
  required List<Map<String, dynamic>> files,
}) {
  return {
    'type': 'transferRequest',
    'fileCount': fileCount,
    'totalSize': totalSize,
    'files': files,
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