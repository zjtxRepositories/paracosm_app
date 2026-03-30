import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/dotted_border.dart';
import 'package:go_router/go_router.dart';

/// 创建钱包 - 第三步：验证助记词
class WalletCreateStep3Page extends StatefulWidget {
  final List<String>? mnemonic;
  final String? password;

  const WalletCreateStep3Page({super.key, this.mnemonic, this.password});

  @override
  State<WalletCreateStep3Page> createState() => _WalletCreateStep3PageState();
}

class _WalletCreateStep3PageState extends State<WalletCreateStep3Page> {
  // 正确的助记词顺序
  // final List<String> _correctMnemonics = [
  //   'acquire',
  //   'useless',
  //   'tip',
  //   'slam',
  //   'devote',
  //   'venture',
  //   'arrange',
  //   'wealth',
  //   'tuna',
  //   'ginger',
  //   'wrist',
  //   'warrior',
  // ];
  List<String> _correctMnemonics = [];
  // 打乱后的助记词（用于下方选择）
  late List<String> _shuffledMnemonics;
  // 用户当前选择的助记词
  final List<String?> _selectedMnemonics = List.filled(12, null);
  // 记录哪些单词已经被点击选择了
  final Set<String> _clickedWords = {};

  @override
  void initState() {
    super.initState();
    _correctMnemonics = widget.mnemonic ?? [];
    // 初始化时打乱助记词
    _shuffledMnemonics = List.from(_correctMnemonics)..shuffle();
  }

  /// 处理单词点击
  void _onWordTap(String word) {
    if (_clickedWords.contains(word)) return;

    // 找到第一个空位
    int firstEmptyIndex = _selectedMnemonics.indexOf(null);
    if (firstEmptyIndex != -1) {
      setState(() {
        _selectedMnemonics[firstEmptyIndex] = word;
        _clickedWords.add(word);
      });
    }
  }

  /// 处理已选单词移除
  void _onRemoveWord(int index) {
    if (_selectedMnemonics[index] == null) return;
    
    setState(() {
      _clickedWords.remove(_selectedMnemonics[index]);
      _selectedMnemonics[index] = null;
    });
  }

  /// 校验是否全部正确
  bool _isAllCorrect() {
    final clickedList = _clickedWords.toList();
    return listEquals(_correctMnemonics, clickedList);
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
                                        text: 'Step 3',
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
                                    _buildStepIndicator(3),
                                  ],
                                ),
                              ],
                            ),

                            // 3. 确认助记词卡片
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
                                      loc.walletStep3Title,
                                      style: AppTextStyles.h2.copyWith(),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      loc.walletStep3Subtitle,
                                      style: AppTextStyles.body.copyWith(),
                                    ),
                                    const SizedBox(height: 24),

                                    // 助记词确认展示区域
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.grey100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          childAspectRatio: 2.2,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                        ),
                                        itemCount: 12,
                                        itemBuilder: (context, index) {
                                          final word = _selectedMnemonics[index];
                                          final isCorrect = word == null || word == _correctMnemonics[index];
                                          
                                          return GestureDetector(
                                            onTap: () => _onRemoveWord(index),
                                            child: _buildSelectedWordItem(index + 1, word ?? loc.walletStep3SelectHint, isCorrect),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // 备选单词池
                                    Center(
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        alignment: WrapAlignment.center,
                                        children: _shuffledMnemonics.map((word) {
                                          final isUsed = _clickedWords.contains(word);
                                          return GestureDetector(
                                            onTap: () => _onWordTap(word),
                                            child: _buildOptionWordItem(word, isUsed),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 48),

                                    // 继续按钮
                                    AppButton(
                                      text: loc.commonContinue,
                                      onPressed: _isAllCorrect()
                                          ? () {
                                              context.push('/wallet-creating',
                                                extra: {
                                                  'password': widget.password,
                                                  'mnemonics': widget.mnemonic,
                                                },
                                              );
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
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

  /// 构建已选单词项
  Widget _buildSelectedWordItem(int index, String? word, bool isCorrect) {
    if (word == null || word == AppLocalizations.of(context)!.walletStep3SelectHint) {
      // 未选状态：虚线效果边框
      return DottedBorder(
        radius: 8,
        color: AppColors.grey300,
        dashWidth: 4,
        dashSpace: 4,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColors.grey300.withValues(alpha: 0.1), // 稍微给一点背景色
          ),
          child: Text(
            '$index.${AppLocalizations.of(context)!.walletStep3SelectHint}',
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              color: AppColors.grey400,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    // 已选状态：白底
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$index.$word',
        style: AppTextStyles.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isCorrect ? AppColors.grey900 : AppColors.error,
        ),
      ),
    );
  }

  /// 构建备选单词项
  Widget _buildOptionWordItem(String word, bool isUsed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.grey200,
        ),
      ),
      child: Text(
        word,
        style: AppTextStyles.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isUsed ? AppColors.grey400 : AppColors.grey900,
        ),
      ),
    );
  }
}
