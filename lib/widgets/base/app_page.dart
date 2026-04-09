import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';

/// 通用页面包装组件
/// 提供统一的导航栏管理、背景色设置、返回拦截等基础功能。
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.title,
    this.showNav = true,
    this.showBack = true,
    this.isCustomHeader = false,
    this.renderCustomHeader,
    this.backgroundColor = AppColors.grey100, // 页面整体背景色
    this.navBackgroundColor = Colors.transparent, // 导航栏背景颜色
    this.titleColor = AppColors.black, // 标题文字颜色
    this.backTheme = Brightness.light, // light 表示黑色图标, dark 表示白色图标
    this.onBeforeBack,
    this.isAddBottomMargin = true,
    this.headerActions,
    this.appBarBottom,
    this.fixedView,
    this.useRefresh = false,
    this.onRefresh,
    this.extendBodyBehindAppBar = false,
    this.showNavBorder = false, // 是否显示导航栏底部边框
    this.navBorderColor = AppColors.grey100, // 导航栏边框颜色
  });

  /// 页面主内容
  final Widget child;

  /// 导航栏标题
  final String? title;

  /// 是否显示导航栏
  final bool showNav;

  /// 是否显示返回按钮
  final bool showBack;

  /// 是否使用自定义导航栏
  final bool isCustomHeader;

  /// 自定义导航栏内容
  final Widget? renderCustomHeader;

  /// 页面整体背景色
  final Color backgroundColor;

  /// 导航栏背景颜色
  final Color navBackgroundColor;

  /// 标题文字颜色
  final Color titleColor;

  /// 状态栏与图标亮度模式
  final Brightness backTheme;

  /// 返回拦截回调
  final Future<bool> Function()? onBeforeBack;

  /// 是否适配底部安全区
  final bool isAddBottomMargin;

  /// 导航栏右侧操作项
  final List<Widget>? headerActions;

  /// 导航栏底部插槽
  final PreferredSizeWidget? appBarBottom;

  /// 固定定位视图
  final Widget? fixedView;

  /// 是否开启下拉刷新
  final bool useRefresh;

  /// 下拉刷新回调
  final Future<void> Function()? onRefresh;

  /// 内容是否延伸至导航栏下方
  final bool extendBodyBehindAppBar;

  /// 是否显示导航栏底部边框
  final bool showNavBorder;

  /// 导航栏边框颜色
  final Color navBorderColor;

  @override
  Widget build(BuildContext context) {
    // 1. 处理返回拦截逻辑 (Flutter 3.12+ 推荐用法)
    // 使用 PopScope 替代已废弃的 WillPopScope
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            backTheme == Brightness.light ? Brightness.dark : Brightness.light,
        statusBarBrightness: backTheme,
      ),
      child: PopScope(
        canPop: onBeforeBack == null,
        onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (onBeforeBack != null) {
              final shouldPop = await onBeforeBack!();
              if (shouldPop && context.mounted && context.canPop()) {
                context.pop();
              }
            }
          },
        child: Scaffold(
          backgroundColor: backgroundColor,
          extendBodyBehindAppBar: !showNav ? true : extendBodyBehindAppBar,
          // 2. 动态渲染顶部导航栏 (AppBar)
          appBar: _buildAppBar(context),
          // 3. 页面主内容布局
          body: Stack(
            children: [
              // 下拉刷新包裹
              useRefresh
                  ? RefreshIndicator(
                      onRefresh: onRefresh ?? () async {},
                      child: _buildContent(context),
                    )
                  : _buildContent(context),
              // 固定层布局 (如悬浮按钮、底部固定栏)
              if (fixedView != null) Positioned.fill(child: fixedView!),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建内部内容区域，处理安全区边距
  Widget _buildContent(BuildContext context) {
    return SafeArea(
      top: showNav && !extendBodyBehindAppBar,
      bottom: isAddBottomMargin,
      child: child,
    );
  }

  /// 构建导航栏
  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    if (!showNav) return null;

    // 如果使用完全自定义的 Header
    if (isCustomHeader && renderCustomHeader != null) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: renderCustomHeader!,
      );
    }

    // 标准 AppBar
    Widget appBar = AppBar(
      backgroundColor: navBackgroundColor,
      elevation: 0,
      centerTitle: true,
      title: title != null
          ? Text(
              title!,
              style: AppTextStyles.h2.copyWith(color: titleColor),
            )
          : null,
      leading: showBack
          ? IconButton(
              icon: Image.asset(
                'assets/images/common/back-icon.png',
                width: 32,
                height: 32,
              ),
              onPressed: () async {
                if (onBeforeBack != null) {
                  final shouldPop = await onBeforeBack!();
                  if (shouldPop && context.mounted && context.canPop()) {
                    context.pop();
                  }
                } else if (context.canPop()) {
                  context.pop();
                }
              },
            )
          : null,
      actions: headerActions,
      bottom: appBarBottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            backTheme == Brightness.light ? Brightness.dark : Brightness.light,
        statusBarBrightness: backTheme,
      ),
    );

    if (showNavBorder) {
      return PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + (appBarBottom?.preferredSize.height ?? 0)),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: navBorderColor,
                width: 1,
              ),
            ),
          ),
          child: appBar,
        ),
      );
    }

    return appBar as PreferredSizeWidget;
  }
}
