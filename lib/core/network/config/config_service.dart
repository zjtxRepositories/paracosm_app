
import 'package:paracosm/core/network/client/http_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/config_api.dart';
import 'network_config.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();

  factory ConfigService() => _instance;

  ConfigService._internal();

  static const _baseUrlKey = "api_base_url";

  /// =========================
  /// 初始化（App启动用）
  /// =========================
  Future<void> init() async {
    await _loadLocal();
    _fetchRemote(); // 异步，不阻塞
  }

  /// =========================
  /// 1️⃣ 本地配置（必须成功）
  /// =========================
  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();

    String? cacheUrl = prefs.getString(_baseUrlKey);

    if (cacheUrl != null && cacheUrl.isNotEmpty) {

      /// 使用缓存地址
      NetworkConfig.apiBaseUrl = cacheUrl;

      HttpClient().updateBaseUrl(cacheUrl);

    }
  }

  /// =========================
  /// 2️⃣ 远程配置（异步刷新）
  /// =========================
  Future<void> _fetchRemote() async {
    for (int i = 0; i < 3; i++) {
      try {
        final config = await ConfigApi.getAppConfig();

        String apiUrl = config["apiUrl"];

        /// 更新
        NetworkConfig.apiBaseUrl = apiUrl;

        HttpClient().updateBaseUrl(apiUrl);

        /// 缓存
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_baseUrlKey, apiUrl);
        return;
      } catch (e) {
        print("远程配置失败，第${i + 1}次重试");
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    print("远程配置最终失败，继续使用本地/默认配置");
  }
}