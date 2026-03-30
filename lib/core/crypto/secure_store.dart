import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _storage = FlutterSecureStorage();

  static Future<void> set(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> get(String key) async {
    return await _storage.read(key: key);
  }
}