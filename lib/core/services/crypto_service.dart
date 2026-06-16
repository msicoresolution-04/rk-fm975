import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class CryptoService {
  static const _storageKey = 'rkfm_aes_key_v1';

  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password$salt');
    return sha256.convert(bytes).toString();
  }

  static String generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(values);
  }

  static String encryptData(String plainText, String keyBase64) {
    final key = enc.Key.fromBase64(keyBase64);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decryptData(String cipherText, String keyBase64) {
    final parts = cipherText.split(':');
    if (parts.length != 2) return cipherText;
    final key = enc.Key.fromBase64(keyBase64);
    final iv = enc.IV.fromBase64(parts[0]);
    final encrypter = enc.Encrypter(enc.AES(key));
    return encrypter.decrypt64(parts[1], iv: iv);
  }

  static String generateAesKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(values);
  }

  static String get storageKey => _storageKey;
}
