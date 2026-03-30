// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// class TokenManager {
//   static const _storage = FlutterSecureStorage();
//   static const _tokenKey = "token";
//
//   static String? _token;
//
//   /// 初始化
//   static Future<void> init() async {
//     _token = await _storage.read(key: _tokenKey);
//   }
//
//   /// 获取 token
//   static String? getToken() {
//     return _token;
//   }
//
//   /// 保存 token
//   static Future<void> saveToken(String token) async {
//     _token = token;
//     await _storage.write(key: _tokenKey, value: token);
//   }
//
//   /// 删除 token
//   static Future<void> clearToken() async {
//     _token = null;
//     await _storage.delete(key: _tokenKey);
//   }
//
//   /// 是否登录
//   static bool isLogin() {
//     return _token != null && _token!.isNotEmpty;
//   }
// }