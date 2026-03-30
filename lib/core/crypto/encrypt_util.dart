// import 'package:encrypt/encrypt.dart';
// import 'package:encrypt/encrypt.dart' as ce;
//
// class EncryptUtil {
//
//   /// 32位key
//   static final _key = Key.fromUtf8(
//       "12345678901234567890123456789012");
//
//   /// 16位IV
//   static final _iv = IV.fromUtf8("1234567890123456");
//
//   static final _encrypter =
//   Encrypter(AES(_key));
//
//   /// 加密
//   static String encrypt(String text) {
//
//     final encrypted =
//     _encrypter.encrypt(text, iv: _iv);
//
//     return encrypted.base64;
//
//   }
//
//   /// 解密
//   static String decrypt(String text) {
//
//     return _encrypter.decrypt64(
//       text,
//       iv: _iv,
//     );
//
//   }
//
// }