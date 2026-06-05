import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api/rong_get_token_api.dart';
import '../service/im_service.dart';

typedef ImTokenFetcher =
    Future<RongTokenResult?> Function({
      required String userId,
      required String name,
      String? portraitUri,
    });

class ImTokenManager {
  static SharedPreferences? _sp;

  static String? _token;
  static String? _currentUserId;
  static ImTokenFetcher? _getTokenProviderForTesting;

  static String _cacheKey(String userId) => 'im_token_$userId';
  static String _appKeyCacheKey(String userId) => 'im_app_key_$userId';

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
      _token = _cachedToken(userId);
      _restoreCachedAppKey(userId);
    }

    // 👉 有缓存直接返回
    if (!forceRefresh && _token != null && _token!.isNotEmpty) {
      return _token;
    }

    // 👉 请求新 token
    final result = await _fetchToken(
      userId: userId,
      name: name,
      portraitUri: portrait,
    );

    if (result != null) {
      await _cacheResult(userId, result);
    }

    return result?.token;
  }

  static Future<void> restoreAppKey(String userId) async {
    await init();
    _restoreCachedAppKey(userId);
  }

  static void _restoreCachedAppKey(String userId) {
    final appKey = _sp!.getString(_appKeyCacheKey(userId));
    if (appKey != null && appKey.isNotEmpty) {
      ImConfig.updateAppKey(appKey);
    }
  }

  static String? _cachedToken(String userId) {
    return _sp!.getString(_cacheKey(userId));
  }

  static Future<RongTokenResult?> _fetchToken({
    required String userId,
    required String name,
    String? portraitUri,
  }) {
    final fetcher = _getTokenProviderForTesting ?? RongGetTokenApi.getToken;
    return fetcher(userId: userId, name: name, portraitUri: portraitUri);
  }

  static Future<void> _cacheResult(
    String userId,
    RongTokenResult result,
  ) async {
    _token = result.token;
    await _sp!.setString(_cacheKey(userId), result.token);
    await _cacheAppKey(userId, result.appKey);
  }

  static Future<void> _cacheAppKey(String userId, String? appKey) async {
    if (appKey == null || appKey.isEmpty) return;
    ImConfig.updateAppKey(appKey);
    await _sp!.setString(_appKeyCacheKey(userId), appKey);
  }

  /// 清除当前用户 Token
  static Future<void> clear(String userId) async {
    await init();

    await _sp!.remove(_cacheKey(userId));
    await _sp!.remove(_appKeyCacheKey(userId));

    if (_currentUserId == userId) {
      _token = null;
      _currentUserId = null;
    }
  }

  static void setGetTokenProviderForTesting(ImTokenFetcher? provider) {
    _getTokenProviderForTesting = provider;
  }

  static void resetForTesting() {
    _sp = null;
    _token = null;
    _currentUserId = null;
    _getTokenProviderForTesting = null;
  }
}
