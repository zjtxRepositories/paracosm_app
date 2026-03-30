import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt.dart' as ce;

import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class CryptoUtil {

  static final _rand = Random.secure();

  static List<int> _randomBytes(int length) =>
      List.generate(length, (_) => _rand.nextInt(256));

  /// PBKDF2（简化实现）
  static List<int> _deriveKey(
      String password,
      List<int> salt,
      ) {
    List<int> key = utf8.encode(password);

    for (int i = 0; i < 10000; i++) {
      key = sha256.convert([...key, ...salt]).bytes;
    }

    return key.sublist(0, 32);
  }

  /// 🔐 加密（带 salt）
  static String encrypt(
      String data,
      String password,
      ) {
    final salt = _randomBytes(16);  // ✅ 每次随机
    final iv = _randomBytes(12);    // GCM推荐12字节

    final keyBytes = _deriveKey(password, salt);
    final key = Key(Uint8List.fromList(keyBytes));

    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

    final encrypted = encrypter.encrypt(
      data,
      iv: IV(Uint8List.fromList(iv)),
    );

    /// 👉 存：salt + iv + 密文
    return base64Encode([
      ...salt,
      ...iv,
      ...encrypted.bytes,
    ]);
  }

  /// 🔓 解密
  static String decrypt(
      String cipherText,
      String password,
      ) {
    final raw = base64Decode(cipherText);

    final salt = raw.sublist(0, 16);
    final iv = raw.sublist(16, 28);
    final cipher = raw.sublist(28);

    final keyBytes = _deriveKey(password, salt);
    final key = Key(Uint8List.fromList(keyBytes));

    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

    return encrypter.decrypt(
      Encrypted(cipher),
      iv: IV(Uint8List.fromList(iv)),
    );
  }

  //AES加密
  static String aesEncryption(String content, String input) {
    final key = ce.Key.fromUtf8(input);
    final encrypt = ce.Encrypter(ce.AES(key, mode: ce.AESMode.cbc));
    final encrypted = encrypt.encrypt(content, iv: ce.IV.fromUtf8(input));
    return encrypted.base64.toString();
  }
}