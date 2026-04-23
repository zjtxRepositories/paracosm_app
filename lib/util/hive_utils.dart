import 'dart:io';

import 'package:convert/convert.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../modules/dapp/dapp_account_auth_hive.dart';

class HiveUtils {
  static const hiveSecureKey = 'hiveSecureKey';

  static late HiveAesCipher _cipher;

  // =========================================================
  // 初始化
  // =========================================================
  static Future<void> initHive() async {
    final dir = await getApplicationDocumentsDirectory();

    Hive.init(dir.path);

    _cipher = await _getEncryptionCipher();

    _registerAdapters();

    await _openHiveBoxes();
  }

  // =========================================================
  // 加密 key（只初始化一次）
  // =========================================================
  static Future<HiveAesCipher> _getEncryptionCipher() async {
    const storage = FlutterSecureStorage();

    String? secureKey = await storage.read(key: hiveSecureKey);

    if (secureKey == null || secureKey.isEmpty) {
      final key = Hive.generateSecureKey();
      secureKey = hex.encode(key);

      await storage.write(
        key: hiveSecureKey,
        value: secureKey,
      );

      return HiveAesCipher(key);
    }

    return HiveAesCipher(hex.decode(secureKey));
  }

  // =========================================================
  // 注册 adapter
  // =========================================================
  static void _registerAdapters() {
    // TODO: register adapters
  }

  // =========================================================
  // 打开所有 box
  // =========================================================
  static Future<void> _openHiveBoxes() async {
    await openEncryptionBox(DAppAccountAuthHive.boxName);
  }

  // =========================================================
  // 加密 box
  // =========================================================
  static Future<Box> openEncryptionBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box(name);
    }

    return Hive.openBox(
      name,
      encryptionCipher: _cipher,
    );
  }

  // =========================================================
  // 普通 box
  // =========================================================
  static Future<Box> openBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box(name);
    }

    return Hive.openBox(name);
  }
}