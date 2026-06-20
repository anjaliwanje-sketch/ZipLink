import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionService {
  final encrypt.Key _key;

  EncryptionService(List<int> sharedSecret) : _key = _deriveKey(sharedSecret);

  // Derive a 256-bit (32 bytes) key using SHA-256
  static encrypt.Key _deriveKey(List<int> sharedSecret) {
    var bytes = utf8.encode(base64Encode(sharedSecret));
    var digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  // Encrypt a chunk of data (for streaming)
  Uint8List encryptChunk(List<int> chunk) {
    if (chunk.isEmpty) return Uint8List(0);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
    
    final encrypted = encrypter.encryptBytes(chunk, iv: iv);
    
    // Prepend IV to the ciphertext so we can decrypt it later
    final result = BytesBuilder();
    result.add(iv.bytes);
    // Add length of encrypted data for framing if needed, but since it's chunking we assume fixed size or handle elsewhere
    result.add(encrypted.bytes);
    
    return result.toBytes();
  }

  // Decrypt a chunk of data (for streaming)
  Uint8List decryptChunk(Uint8List encryptedChunk) {
    if (encryptedChunk.length < 16) return Uint8List(0);
    
    // Extract IV
    final ivBytes = encryptedChunk.sublist(0, 16);
    final iv = encrypt.IV(ivBytes);
    
    // Extract Ciphertext
    final cipherBytes = encryptedChunk.sublist(16);
    final encrypted = encrypt.Encrypted(cipherBytes);
    
    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
    
    return Uint8List.fromList(decrypted);
  }

  // Full File Encryption (for small files)
  Future<void> encryptFile(File inputFile, File outputFile) async {
    final bytes = await inputFile.readAsBytes();
    final encrypted = encryptChunk(bytes);
    await outputFile.writeAsBytes(encrypted);
  }

  // Full File Decryption (for small files)
  Future<void> decryptFile(File inputFile, File outputFile) async {
    final bytes = await inputFile.readAsBytes();
    final decrypted = decryptChunk(bytes);
    await outputFile.writeAsBytes(decrypted);
  }
}
