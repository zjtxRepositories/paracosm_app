import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api/rong_get_token_api.dart';

class ImTokenManager {
  static SharedPreferences? _sp;

  static String? _token;
  static String? _currentUserId;

  static String _cacheKey(String userId) => 'im_token_$userId';

  /// 初始化（App启动调用一次）
  static Future<void> init() async {
    _sp ??= await SharedPreferences.getInstance();
  }

  /// 获取 Token
  static Future<String?> getToken({
    required String userId,
    required String name,
    String? portrait,
    bool forceRefresh = false,
  }) async {
    await init();

    // 👉 用户切换时，重新读取缓存
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _token = _sp!.getString(_cacheKey(userId));
    }

    // 👉 有缓存直接返回
    if (!forceRefresh && _token != null && _token!.isNotEmpty) {
      return _token;
    }

    // 👉 请求新 token
    final token = await RongGetTokenApi.getToken(
      userId: userId,
      name: name,
      portraitUri: portrait,
    );

    if (token != null) {
      _token = token;
      await _sp!.setString(_cacheKey(userId), token);
    }

    return token;
  }

  /// 清除当前用户 Token
  static Future<void> clear(String userId) async {
    await init();

    await _sp!.remove(_cacheKey(userId));

    if (_currentUserId == userId) {
      _token = null;
      _currentUserId = null;
    }
  }
}