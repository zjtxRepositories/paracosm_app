import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'app_localizations_keys.dart';

/// 应用国际化管理类 - 支持从 JSON 文件加载
/// 
/// 核心管理逻辑与翻译 Key 已分离。Key 管理请参见 [app_localizations_keys.dart]。
class AppLocalizations {
  final Locale locale;
  Map<String, String>? _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// 从 assets 加载 JSON 翻译文件
  Future<bool> load() async {
    String jsonString = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  /// 根据 key 获取翻译内容，并支持可选的占位符替换
  String translate(String key, [Map<String, dynamic>? params]) {
    String value = _localizedStrings?[key] ?? key;
    if (params != null) {
      params.forEach((k, v) {
        value = value.replaceAll('{$k}', v.toString());
      });
    }
    return value;
  }
}

/// 国际化代理类
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
