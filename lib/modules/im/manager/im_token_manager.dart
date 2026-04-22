import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api/rong_get_token_api.dart';

class ImTokenManager {
  static const _cacheKey = 'im_token';

  static String? _token;

  /// 初始化（App启动时调用）
  static Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString(_cacheKey);
  }

  /// 获取 Token（优先缓存）
  static Future<String?> getToken({
    required String userId,
    required String name,
    String? portrait,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _token != null && _token!.isNotEmpty) {
      return _token;
    }

    final token = await RongGetTokenApi.getToken(
      userId: userId,
      name: name,
      portraitUri: portrait,
    );

    if (token != null) {
      _token = token;

      final sp = await SharedPreferences.getInstance();
      await sp.setString(_cacheKey, token);
    }

    return token;
  }

  /// 清除 Token（退出登录用）
  static Future<void> clear() async {
    _token = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_cacheKey);
  }
}