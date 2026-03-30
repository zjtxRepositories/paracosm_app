import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

/// MainTabScaffold 是整个应用的主外壳组件。
/// 它使用 StatefulNavigationShell 来管理底部的持久化导航栏。
/// 这种模式下，每个 Tab 都有自己独立的导航栈，且状态在切换时会被保持（如滚动位置）。
class MainTabScaffold extends StatelessWidget {
  const MainTabScaffold({
    super.key,
    required this.navigationShell,
  });

  /// StatefulNavigationShell 是 GoRouter 提供的用于管理 Tab 分支状态的容器
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body 使用 navigationShell，它会自动渲染当前激活的分支页面
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.grey200,
              width: 0.5.w,
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final color = states.contains(WidgetState.selected)
                  ? AppColors.grey900
                  : AppColors.grey900;
              return AppTextStyles.overline.copyWith(
                fontSize: 10.sp,
                color: color,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (int index) {
              // 切换 Tab 分支逻辑
              navigationShell.goBranch(
                index,
                // 如果点击的是当前已经选中的 Tab，通常会回到该分支的根路由
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            // 导航栏外观配置：简洁风格，符合社交 App 审美
            elevation: 0,
            backgroundColor: Colors.white,
            indicatorColor: Colors.transparent, // 移除 Material3 默认的选中背景指示器
            height: 64.h,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: <Widget>[
              _buildDestination(
                index: 0,
                label: 'Chat',
                iconName: 'chat',
              ),
              _buildDestination(
                index: 1,
                label: 'Moments',
                iconName: 'moments',
              ),
              _buildDestination(
                index: 2,
                label: 'Community',
                iconName: 'community',
              ),
              _buildDestination(
                index: 3,
                label: 'Discover',
                iconName: 'discover',
              ),
              _buildDestination(
                index: 4,
                label: 'Profile',
                iconName: 'profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildDestination({
    required int index,
    required String label,
    required String iconName,
  }) {
    return NavigationDestination(
      icon: Image.asset(
        'assets/images/nav/$iconName-default.png',
        width: 24.w,
        height: 24.w,
      ),
      selectedIcon: Image.asset(
        'assets/images/nav/$iconName-active.png',
        width: 24.w,
        height: 24.w,
      ),
      label: label,
    );
  }
}
