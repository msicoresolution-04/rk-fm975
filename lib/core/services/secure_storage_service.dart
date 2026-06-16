import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rkfm_broadcast/core/services/crypto_service.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();

  Future<String> getOrCreateEncryptionKey() async {
    final existing = await read(CryptoService.storageKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final key = CryptoService.generateAesKey();
    await write(CryptoService.storageKey, key);
    return key;
  }

  Future<void> storeEncrypted(String key, String value) async {
    final encKey = await getOrCreateEncryptionKey();
    await write(key, CryptoService.encryptData(value, encKey));
  }

  Future<String?> readEncrypted(String key) async {
    final encKey = await getOrCreateEncryptionKey();
    final value = await read(key);
    if (value == null) return null;
    try {
      return CryptoService.decryptData(value, encKey);
    } catch (_) {
      return null;
    }
  }
}
