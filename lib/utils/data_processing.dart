import 'dart:convert';
import 'dart:typed_data';

///// SENDER (Encode)

// Wraps a payload with a 4-byte big-endian length prefix.
Uint8List frameMessage(Uint8List payload) {
  final lengthBytes = ByteData(4)..setUint32(0, payload.length, Endian.big);
  final framed = BytesBuilder();
  framed.add(lengthBytes.buffer.asUint8List());
  framed.add(payload);
  return framed.toBytes();
}

// Small helper: encode a Dart Map as JSON, then as framed bytes.
Uint8List frameJson(Map<String, dynamic> data) {
  return frameMessage(Uint8List.fromList(utf8.encode(jsonEncode(data))));
}


///// RECEIVER (Decode)

// Incrementally reconstructs framed messages from a raw byte stream.
class MessageDecoder {
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  int? _expectedLength;

  void addData(List<int> chunk, void Function(Uint8List message) onMessage) {
    _buffer.add(chunk);

    while (true) {
      // Check if we have the 4-byte length header
      if (_expectedLength == null) {
        if (_buffer.length < 4) return;
        
        // Read 4-byte header directly without dumping the whole buffer
        final bytes = _buffer.takeBytes();
        final headerData = ByteData.sublistView(Uint8List.fromList(bytes.sublist(0, 4)));
        _expectedLength = headerData.getUint32(0, Endian.big);

        // Put remaining bytes back into the buffer
        if (bytes.length > 4) {
          _buffer.add(bytes.sublist(4));
        }
      }

      // Check if full payload has arrived
      if (_buffer.length < _expectedLength!) return;

      // Extract exact message length
      final allBytes = _buffer.takeBytes();
      final payload = Uint8List.fromList(allBytes.sublist(0, _expectedLength!));
      
      onMessage(payload);

      // Put leftover bytes (start of next frame) back into the buffer
      if (allBytes.length > _expectedLength!) {
        _buffer.add(allBytes.sublist(_expectedLength!));
      }

      _expectedLength = null; // Reset for next message
    }
  }
}