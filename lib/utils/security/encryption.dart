import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class DataEncryptionService {
  final aesGcm = AesGcm.with256bits(); // encryption & decryption 
  final x25519 = X25519(); // key exchage algorithm

  SimpleKeyPair? myKeyPair;
  SecretKey? sendKey;
  SecretKey? recvKey;

  // returns your public key to send (Sender)
  Future<String> generatePublicKey() async {
    myKeyPair = await x25519.newKeyPair();
    final pubicKey = await myKeyPair!.extractPublicKey();
    return base64Encode(pubicKey.bytes);
  }

  /// Call once the peer's public key arrives in their handshake message.
  /// Derives SEPARATE keys for each direction so a sender and receiver

  Future<void> deriveSessionKeys(String peerPublicKeyBase64, {required bool isSender}) async {
    final peerPublicKey = SimplePublicKey(
      base64Decode(peerPublicKeyBase64),
      type: KeyPairType.x25519,
    );

    final sharedKey = await x25519.sharedSecretKey(
      keyPair: myKeyPair!,
      remotePublicKey: peerPublicKey,
    );
    final sharedBytes = await sharedKey.extractBytes();

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

    // "a2b"/"b2a" labels ensure the initiator's send key = the
    // responder's recv key, and vice versa.
    final k1 = await hkdf.deriveKey(
      secretKey: SecretKey(sharedBytes),
      info: utf8.encode('a2b'),
    );
    final k2 = await hkdf.deriveKey(
      secretKey: SecretKey(sharedBytes),
      info: utf8.encode('b2a'),
    );

    sendKey = isSender ? k1 : k2;
    recvKey = isSender ? k2 : k1;
  }

  /// Encrypts one chunk with unique counter (part of the aesGcm algorithm)
  Future<Uint8List> encryptChunk(List<int> plainBytes, int counter) async {
    final nonce = _nonceFromCounter(counter);
    final box = await aesGcm.encrypt(
      plainBytes,
      secretKey: sendKey!,
      nonce: nonce,
    );
    // Wire format: [12-byte nonce][ciphertext][16-byte tag]
    return Uint8List.fromList([...box.nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  Future<Uint8List> decryptChunk(Uint8List packed) async {
    final nonce = packed.sublist(0, 12);
    final tag = Mac(packed.sublist(packed.length - 16));
    final cipherText = packed.sublist(12, packed.length - 16);

    final plain = await aesGcm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: tag),
      secretKey: recvKey!,
    );
    return Uint8List.fromList(plain);
  }

  /// 12-byte GCM nonce: 4 random session bytes + 8-byte big-endian counter.
  /// Guarantees no two chunks in a session ever reuse a nonce.
  final sessionSalt = Uint8List.fromList(
    List.generate(4, (_) => Random.secure().nextInt(256)),
  );

  Uint8List _nonceFromCounter(int counter) {
    final nonce = Uint8List(12);
    nonce.setRange(0, 4, sessionSalt);
    final counterBytes = ByteData(8)..setUint64(0, counter, Endian.big);
    nonce.setRange(4, 12, counterBytes.buffer.asUint8List());
    return nonce;
  }
}