import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:go_router/go_router.dart';

import 'package:paracosm/widgets/common/app_modal.dart';

import '../../modules/account/service/account_service.dart';
import '../../modules/wallet/service/mnemonic_service.dart';


/// 创建钱包 - 第二步：备份助记词
class WalletCreateStep2Page extends StatefulWidget {
  final String? password;
  const WalletCreateStep2Page({super.key,this.password});

  @override
  State<WalletCreateStep2Page> createState() => _WalletCreateStep2PageState();
}

class _WalletCreateStep2PageState extends State<WalletCreateStep2Page> {
  final List<String> _mnemonics =
  MnemonicService.generateMnemonic().split(" ");

  bool _isCopied = false;
  bool _hasBeenCopied = false;

  @override
  void initState() {
    super.initState();
    _disableScreenshot();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRiskDialog();
    });
  }

  @override
  void dispose() {
    _enableScreenshot();
    super.dispose();
  }

  void _disableScreenshot() async {
    await FlutterWindowManagerPlus.addFlags(
      FlutterWindowManagerPlus.FLAG_SECURE,
    );
  }

  void _enableScreenshot() async {
    await FlutterWindowManagerPlus.clearFlags(
      FlutterWindowManagerPlus.FLAG_SECURE,
    );
  }

  /// 显示截屏风险提示弹窗
  void _showRiskDialog() {
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.commonRiskTips,
      description: AppLocalizations.of(context)!.walletStep2RiskDialog,
      onConfirm: () {
        Navigator.pop(context);
        // 仅关闭弹窗，不执行其他逻辑
      },
    );
  }

  /// 切换复制状态并激活“我已备份”按钮
  void _toggleCopyStatus() {
    setState(() {
      _isCopied = true;
      _hasBeenCopied = true;
    });
    // 2秒后恢复图标状态
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppPage(
      showNav: true,
      showBack: true,
      title: '',
      child: Stack(
        children: [
          // 1. 全屏背景网格图
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallet/grid-bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. 页面内容
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 顶部标题和 Step 信息
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                // 顶部标题 - 创建新钱包 (仅“新钱包”有下划线)
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      loc.walletCreateTitle,
                                      style: AppTextStyles.h1.copyWith(
                                        fontSize: 24,
                                      ),
                                    ),
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          bottom: 4,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 4,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          loc.walletCreateNew,
                                          style: AppTextStyles.h1.copyWith(
                                            fontSize: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Step 信息
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        text: 'Step 2',
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 14,
                                          color: AppColors.grey900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '/3',
                                            style: AppTextStyles.body.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.grey400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 步骤指示条
                                    _buildStepIndicator(2),
                                  ],
                                ),
                              ],
                            ),

                            // 3. 备份助记词卡片
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 40,
                                bottom: 20,
                              ),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  20,
                                  16,
                                  20,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.walletStep2Title,
                                      style: AppTextStyles.h2.copyWith(),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      loc.walletStep2Subtitle,
                                      style: AppTextStyles.body.copyWith(),
                                    ),
                                    const SizedBox(height: 0), // 移除外部间距，因为按钮上方已有 15px 透明热区，下方有 28px Padding

                                    // 助记词展示区域
                                    Stack(
                                      alignment: Alignment.topCenter,
                                      clipBehavior: Clip.none,
                                      children: [
                                        // 下层助记词容器：通过 Padding 为按钮预留空间
                                        Padding(
                                          padding: const EdgeInsets.only(top: 28), // 28px = 15(透明热区) + 13(按钮中心)
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
                                            decoration: BoxDecoration(
                                              color: AppColors.grey100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 3,
                                                childAspectRatio: 2.2,
                                                mainAxisSpacing: 8,
                                                crossAxisSpacing: 8,
                                              ),
                                              itemCount: _mnemonics.length,
                                              itemBuilder: (context, index) {
                                                return Container(
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '${index + 1}.${_mnemonics[index]}',
                                                    style: AppTextStyles.body
                                                        .copyWith(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color:
                                                              AppColors.grey900,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        // 复制按钮：位于 Stack 的 top: 0，不再是负数 overflow，因此点击 100% 灵敏
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          child: Center(
                                            child: GestureDetector(
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(
                                                        text: _mnemonics.join(' ')))
                                                    .then((_) {
                                                  _toggleCopyStatus();
                                                });
                                              },
                                              behavior: HitTestBehavior.opaque,
                                              child: Container(
                                                padding: const EdgeInsets.all(15),
                                                color: Colors.transparent,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.05,
                                                            ),
                                                        blurRadius: 10,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Image.asset(
                                                        'assets/images/common/${_isCopied ? 'copyed' : 'copy'}.png',
                                                        width: 16,
                                                        height: 16,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => Icon(
                                                              _isCopied
                                                                  ? Icons.check
                                                                  : Icons.copy,
                                                              size: 14,
                                                              color: AppColors
                                                                  .grey900,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _isCopied ? loc.commonCopied : loc.commonCopy,
                                                        style: AppTextStyles.body
                                                            .copyWith(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight.w400,
                                                              color: _isCopied
                                                                  ? AppColors
                                                                        .primaryDark
                                                                  : AppColors
                                                                        .grey900,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 36),

                                    // 我已备份按钮
                                    AppButton(
                                      text: loc.walletStep2IHaveBackedUp,
                                      onPressed: () {
                                        context.push(
                                          '/wallet-create-step3',
                                          extra: {
                                            'password': widget.password,
                                            'mnemonics': _mnemonics,
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                )
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建步骤指示器
  Widget _buildStepIndicator(int currentStep) {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index + 1 <= currentStep;
        return Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.grey900 : AppColors.grey200,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
