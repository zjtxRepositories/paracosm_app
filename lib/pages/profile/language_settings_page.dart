import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';
import 'package:paracosm/providers/settings_provider.dart';

/// 语言设置页面
class LanguageSettingsPage extends ConsumerStatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  ConsumerState<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends ConsumerState<LanguageSettingsPage> {
  // 语言列表
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'EN', 'desc': 'English'},
    {'code': 'zh', 'name': 'CN', 'desc': '简体中文'},
    {'code': 'es', 'name': 'ES', 'desc': 'Español'},
    {'code': 'ms', 'name': 'MS', 'desc': 'Melayu'},
  ];

  @override
  Widget build(BuildContext context) {
    // 监听 settingsProvider 以获取当前语言状态
    final settings = ref.watch(settingsProvider);
    final selectedLanguageCode = settings.locale.languageCode;

    return AppPage(
      title: AppLocalizations.of(context)!.profileLanguageSettingsChangeLanguage,
      showNav: true,
      showNavBorder: true,
      navBorderColor: AppColors.grey100,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _languages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final code = lang['code']!;
          final isSelected = selectedLanguageCode == code;
          // 仅中英文可被选中和设置
          final isSupported = ['en', 'zh'].contains(code);

          return GestureDetector(
            onTap: () {
              if (isSupported) {
                // 仅支持的语言可点击更新
                ref.read(settingsProvider.notifier).updateLocale(Locale(code));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  // 选中项显示边框
                  color: isSelected ? AppColors.grey900 : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // 复选框/单选框样式
                  AppCheckbox(
                    value: isSelected,
                    isRadio: false,
                    size: 20,
                    onChanged: (value) {
                      if (value == true && isSupported) {
                        // 勾选且为支持语言时更新
                        ref.read(settingsProvider.notifier).updateLocale(Locale(code));
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  // 语言名称和描述
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang['name']!,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSupported ? AppColors.grey900 : AppColors.grey400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang['desc']!,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
