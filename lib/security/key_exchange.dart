import 'package:cryptography/cryptography.dart';

class KeyExchange {
  final X25519 _x25519 = X25519();
  late SimpleKeyPair _keyPair;

  Future<void> initialize() async {
    _keyPair = await _x25519.newKeyPair();
  }

  Future<List<int>> getPublicKey() async {
    final pk = await _keyPair.extractPublicKey();
    return pk.bytes;
  }

  // Perform Diffie-Hellman Key Exchange to get a shared secret
  Future<List<int>> computeSharedSecret(List<int> remotePublicKeyBytes) async {
    final remotePk = SimplePublicKey(remotePublicKeyBytes, type: KeyPairType.x25519);
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: _keyPair,
      remotePublicKey: remotePk,
    );
    return await sharedSecret.extractBytes();
  }
}
