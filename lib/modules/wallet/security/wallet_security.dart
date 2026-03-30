import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletSecurity {
  static const _storage = FlutterSecureStorage();

  static const _saltKey = "wallet_global_salt";
  static const _initFlag = "wallet_initialized";

  static const _pbkdf2Iterations = 210000;
  static const _keyLength = 32;

  /// =========================
  /// 初始化
  /// =========================
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final initialized = prefs.getBool(_initFlag) ?? false;

    if (!initialized) {
      print('init--------');
      await _storage.deleteAll();
      final all = await _storage.readAll();
      print("删除后: $all");
      final salt = _randomBytes(16);
      await _storage.write(
        key: _saltKey,
        value: base64Encode(salt),
      );

      await prefs.setBool(_initFlag, true);
    }
  }

  /// =========================
  /// 是否有钱包（替代 hasPassword）
  /// =========================
  static Future<bool> hasPassword() async {
    final all = await _storage.readAll();
    return all.keys.any((k) => k.startsWith("wallet_v1_"));
  }

  /// =========================
  /// 校验密码（通过解密）
  /// =========================
  static Future<bool> verifyPassword(String password) async {
    final all = await _storage.readAll();

    final walletKey = all.keys.firstWhere(
          (k) => k.startsWith("wallet_v1_"),
      orElse: () => "",
    );
    if (walletKey.isEmpty) return false;

    try {
      final data = jsonDecode(all[walletKey]!);
      await decryptData(data["mnemonic"], password);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// =========================
  /// 加密
  /// =========================
  static Future<String> encryptData(
      String data,
      String password,
      ) async {
    final salt = await _getSalt();
    final key = _deriveKey(password, salt);

    final iv = _randomBytes(12);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypter.encrypt(
      data,
      iv: encrypt.IV(iv),
    );

    return jsonEncode({
      "iv": base64Encode(iv),
      "data": base64Encode(encrypted.bytes),
    });
  }

  /// =========================
  /// 解密
  /// =========================
  static Future<String> decryptData(
      String encryptedData,
      String password,
      ) async {
    final salt = await _getSalt();
    final key = _deriveKey(password, salt);

    final json = jsonDecode(encryptedData);

    final iv = encrypt.IV(base64Decode(json["iv"]));
    final data = base64Decode(json["data"]);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    return encrypter.decrypt(
      encrypt.Encrypted(data),
      iv: iv,
    );
  }

  /// =========================
  /// 工具方法
  /// =========================

  static Uint8List _randomBytes(int length) {
    final rand = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => rand.nextInt(256)),
    );
  }

  static Future<Uint8List> _getSalt() async {
    final salt = await _storage.read(key: _saltKey);
    if (salt == null) throw Exception("未初始化");
    return base64Decode(salt);
  }

  static encrypt.Key _deriveKey(String password, Uint8List salt) {
    return encrypt.Key(_pbkdf2(password, salt));
  }

  /// 标准 PBKDF2
  static Uint8List _pbkdf2(
      String password,
      Uint8List salt,
      ) {
    final hmac = Hmac(sha256, utf8.encode(password));

    int blockCount = (_keyLength / 32).ceil();
    List<int> output = [];

    for (int i = 1; i <= blockCount; i++) {
      final block = Uint8List.fromList([
        ...salt,
        (i >> 24) & 0xff,
        (i >> 16) & 0xff,
        (i >> 8) & 0xff,
        i & 0xff,
      ]);

      List<int> u = hmac.convert(block).bytes;
      List<int> t = List.from(u);

      for (int j = 1; j < _pbkdf2Iterations; j++) {
        u = hmac.convert(u).bytes;
        for (int k = 0; k < t.length; k++) {
          t[k] ^= u[k];
        }
      }

      output.addAll(t);
    }

    return Uint8List.fromList(output.sublist(0, _keyLength));
  }

  /// =========================
  /// 钱包操作
  /// =========================

  static Future<void> saveWallet({
    required String walletId,
    required String mnemonic,
    String? privateKey,
    required String password,
  }) async {
    print('password：$password');
    final encryptedMnemonic = await encryptData(mnemonic, password);
    final encryptedPk =
    privateKey == null ? '' : await encryptData(privateKey, password);

    await _storage.write(
      key: "wallet_v1_$walletId",
      value: jsonEncode({
        "mnemonic": encryptedMnemonic,
        "privateKey": encryptedPk,
      }),
    );
  }

  static Future<Map<String, dynamic>?> getWallet({
    required String walletId,
    required String password,
  }) async {
    final data = await _storage.read(key: "wallet_v1_$walletId");
    if (data == null) return null;

    final json = jsonDecode(data);

    try {
      final mnemonic =
      await decryptData(json["mnemonic"], password);

      final privateKey = json["privateKey"] != ""
          ? await decryptData(json["privateKey"], password)
          : "";

      return {
        "mnemonic": mnemonic,
        "privateKey": privateKey,
      };
    } catch (e) {
      throw Exception("密码错误");
    }
  }

  static Future<void> deleteWallet(String walletId) async {
    await _storage.delete(key: "wallet_v1_$walletId");
  }

  static Future<bool> hasWallet(String walletId) async {
    final data = await _storage.read(key: "wallet_v1_$walletId");
    return data != null;
  }

  /// =========================
  /// 修改密码（全部钱包）
  /// =========================
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final all = await _storage.readAll();

    final walletKeys =
    all.keys.where((k) => k.startsWith("wallet_v1_"));

    for (final key in walletKeys) {
      final data = jsonDecode(all[key]!);

      final mnemonic =
      await decryptData(data["mnemonic"], oldPassword);

      final privateKey = data["privateKey"] != ""
          ? await decryptData(data["privateKey"], oldPassword)
          : "";

      final newEncryptedMnemonic =
      await encryptData(mnemonic, newPassword);

      final newEncryptedPk = privateKey.isNotEmpty
          ? await encryptData(privateKey, newPassword)
          : "";

      await _storage.write(
        key: key,
        value: jsonEncode({
          "mnemonic": newEncryptedMnemonic,
          "privateKey": newEncryptedPk,
        }),
      );
    }
  }
}