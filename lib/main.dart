import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paracosm/router/app_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/providers/settings_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/app_init.dart';

/// 应用入口函数
Future<void> main() async {
  // 确保 Flutter 框架已初始化，这对 ScreenUtilInit 是必需的
  WidgetsFlutterBinding.ensureInitialized();
  await AppInit.init();
  // 加载持久化的语言设置
  final initialLocale = await SettingsNotifier.loadLocale();
  
  // 使用 ProviderScope 包裹根组件以启用 Riverpod 状态管理
  runApp(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith((ref) => SettingsNotifier(initialLocale)),
      ],
      child: const MyApp(),
    ),
  );

}

/// 根应用组件
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听语言设置状态
    final settings = ref.watch(settingsProvider);
    
    // 使用 ScreenUtilInit 初始化屏幕适配方案
    // 设计稿尺寸设为常见的 375x812
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // 使用 OKToast 包装 MaterialApp 以启用全局 Toast
        return OKToast(
          child: MaterialApp.router(
            title: 'Paracosm',
            // 移除调试模式的水印
            debugShowCheckedModeBanner: false,
            // 应用全局主题配置
            theme: ThemeData(
              // 从 Figma 提取的精准主色
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                error: AppColors.error,
              ),
              useMaterial3: true,
              // 全局字体家族：优先使用 Poppins
              fontFamily: 'Poppins',
              // 全局背景色设为白色
              scaffoldBackgroundColor: AppColors.white,
              // 统一配置 AppBar 样式
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.white,
                elevation: 0,
                centerTitle: true,
              ),
            ),
            // 将路由配置委托给 AppRouter
            routerConfig: AppRouter.router,
            // 国际化配置
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh'),
              Locale('en'),
            ],
            locale: settings.locale, // 使用 provider 中的语言设置
            // 全局点击空白处收起键盘
            builder: (context, child) {
              child = EasyLoading.init()(context, child);
              return GestureDetector(
                onTap: () {
                  // 获取当前焦点节点
                  FocusScopeNode currentFocus = FocusScope.of(context);
                  // 如果当前有焦点且不是在主焦点上，则收起键盘
                  if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  }
                },
                behavior: HitTestBehavior.translucent, // 确保点击穿透，不影响子组件交互
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}
