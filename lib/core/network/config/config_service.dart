import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:paracosm/core/network/client/http_client.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/config_api.dart';
import 'network_config.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();

  factory ConfigService() => _instance;

  ConfigService._internal();

  static const _baseUrlKey = "api_base_url";

  bool _localLoaded = false;
  bool _hasResolvedBaseUrl = false;
  Future<void>? _remoteFetchFuture;

  /// =========================
  /// 初始化（App启动用）
  /// =========================
  Future<void> init() async {
    await _loadLocal();
    refreshRemote(); // 异步，不阻塞
  }

  /// 需要真实 API 地址的业务在请求前调用。
  /// 有缓存时立即返回；无缓存时只异步等待配置请求，不阻塞 UI 线程。
  Future<void> ensureReady({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await _loadLocal();

    if (_hasResolvedBaseUrl) return;

    try {
      await _fetchRemoteOnce().timeout(timeout);
    } catch (e) {
      debugPrint("等待远程配置失败：$e");
    }

    if (!_hasResolvedBaseUrl) {
      throw Exception(
        AppLocalizations.currentText('network_config_unavailable'),
      );
    }
  }

  /// 后台刷新远端配置，多个入口同时调用时只会复用同一个请求。
  void refreshRemote() {
    unawaited(
      _fetchRemoteOnce().catchError((e) {
        debugPrint("后台刷新远程配置失败：$e");
      }),
    );
  }

  /// =========================
  /// 1️⃣ 本地配置（必须成功）
  /// =========================
  Future<void> _loadLocal() async {
    if (_localLoaded) return;

    final prefs = await SharedPreferences.getInstance();

    String? cacheUrl = prefs.getString(_baseUrlKey);

    if (cacheUrl != null && cacheUrl.isNotEmpty) {
      /// 使用缓存地址
      _applyBaseUrl(cacheUrl);
    }

    _localLoaded = true;
  }

  Future<void> _fetchRemoteOnce() {
    final current = _remoteFetchFuture;
    if (current != null) return current;

    final future = _fetchRemote();
    _remoteFetchFuture = future.whenComplete(() {
      _remoteFetchFuture = null;
    });
    return _remoteFetchFuture!;
  }

  void _applyBaseUrl(String apiUrl) {
    NetworkConfig.apiBaseUrl = apiUrl;
    HttpClient().updateBaseUrl(apiUrl);
    _hasResolvedBaseUrl = true;
  }

  /// =========================
  /// 2️⃣ 远程配置（异步刷新）
  /// =========================
  Future<void> _fetchRemote() async {
    Object? lastError;

    for (int i = 0; i < 3; i++) {
      try {
        final config = await ConfigApi.getAppConfig();

        final apiUrl = (config["apiUrl"] as String?)?.trim();
        if (apiUrl == null || apiUrl.isEmpty) {
          throw Exception("远程配置 apiUrl 为空");
        }

        /// 更新
        _applyBaseUrl(apiUrl);

        /// 缓存
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_baseUrlKey, apiUrl);
        return;
      } catch (e) {
        lastError = e;
        debugPrint("远程配置失败，第${i + 1}次重试：$e");
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    debugPrint("远程配置最终失败，继续使用本地/默认配置");
    throw lastError ?? Exception("远程配置最终失败");
  }
}
