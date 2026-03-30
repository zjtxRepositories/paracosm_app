import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言设置状态
class SettingsState {
  final Locale locale;

  SettingsState({required this.locale});

  SettingsState copyWith({Locale? locale}) {
    return SettingsState(
      locale: locale ?? this.locale,
    );
  }
}

/// 语言设置通知器
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _localeKey = 'app_locale';

  SettingsNotifier(Locale initialLocale) : super(SettingsState(locale: initialLocale));

  /// 更新语言并持久化
  Future<void> updateLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  /// 从持久化中加载语言
  static Future<Locale> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      return Locale(languageCode);
    }
    return const Locale('zh'); // 默认中文
  }
}

/// 全局设置提供者
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  // 注意：这里默认返回一个初始值，实际加载应在 main.dart 中完成并覆盖
  return SettingsNotifier(const Locale('zh'));
});
