import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../modules/account/manager/account_manager.dart';
import '../../modules/wallet/model/chain_account.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/base/app_page.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_modal.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/app_network_selector.dart';
import '../../widgets/base/app_localizations.dart';

/// 转账页面
class TransferPage extends StatefulWidget {
  final Map<String, dynamic> initialNetwork;

  const TransferPage({
    super.key,
    required this.initialNetwork,
  });

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  ChainAccount? _selectedNetwork;
  final _wallet = AccountManager().currentWallet;

  // 模拟数据
  final String _balance = '5,452.24';
  final String _fiatBalance = '0.251544';
  double _feeProgress = 0.0; // 0: Slow, 0.5: Middle, 1: Fast

  @override
  void initState() {
    super.initState();
    if (_wallet != null){
      _selectedNetwork = _wallet.currentChain;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// 显示网络选择弹窗
  void _showNetworkSelector() {
    if (_wallet == null) return;
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileProfileDetailsChooseNetwork,
      confirmText: null, // 移除底部确认按钮，改为点击项即选择并关闭
      onConfirm: () {},
      child: AppNetworkSelector(
        initialNetwork: _selectedNetwork ?? _wallet.chains.first,
        networks: _wallet.chains,
        onSelected: (network) {
          setState(() {
            _selectedNetwork = network;
          });
          context.pop();
        },
      ),
    );
  }

  /// 显示支付详情弹窗
  void _showPaymentDetails() {
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileTransferPaymentDetails,
      confirmText: AppLocalizations.of(context)!.profileTransferConfirmPayment,
      onConfirm: () {
        context.pop();
        _showPasswordModal();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // 金额显示
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '-${_amountController.text.isEmpty ? '0' : _amountController.text}',
                style: AppTextStyles.h1.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(width: 4),
              AppNetworkImage(
                url: _selectedNetwork?.logo,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 预估金额
          Text(
            '0.000139 OMT (Absenteeism)',
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: 24),
          // 分割线
          Container(
            height: 1,
            color: AppColors.grey100,
          ),
          const SizedBox(height: 16),
          // 地址详情
          _buildDetailRow('From', '0X5E4F...1EE4'),
          const SizedBox(height: 12),
          _buildDetailRow('To', _addressController.text.isEmpty ? '0X5E4F...1EE4' : _addressController.text),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 显示密码输入弹窗
  void _showPasswordModal() {
    final passwordController = TextEditingController();
    bool isObscure = true;

    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileTransferPassword,
      confirmText: AppLocalizations.of(context)!.profileTransferConfirm,
      onConfirm: () {
        context.pop(); // 关闭密码弹窗
        // TODO: 密码验证逻辑
         context.push('/transfer-details');
      },
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final isEmpty = passwordController.text.isEmpty;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isEmpty ? AppColors.grey100 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEmpty ? Colors.transparent : AppColors.grey900,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: passwordController,
                        obscureText: isObscure,
                        onChanged: (value) => setModalState(() {}),
                        decoration: const InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey900,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setModalState(() => isObscure = !isObscure),
                      child: Image.asset(
                        isObscure ? 'assets/images/common/eye-off-line.png' : 'assets/images/common/eye-line.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.grey600,
          ),
        ),
        Text(
          value.length > 20 ? '${value.substring(0, 8)}...${value.substring(value.length - 4)}' : value,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.grey800,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      title: AppLocalizations.of(context)!.profileTransferTransfer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 金额输入卡片
            _buildAmountCard(),
            const SizedBox(height: 24),
            // 收款地址输入
            _buildAddressInput(),
            const SizedBox(height: 38),
            // 矿工费滑动条
            _buildMinerFeeSection(),
            const Spacer(),
            // 继续按钮
            AppButton(
              text: AppLocalizations.of(context)!.profileTransferConfirm,
              onPressed: () {
                if (_amountController.text.isNotEmpty) {
                  _showPaymentDetails();
                }
              },
              backgroundColor: _amountController.text.isEmpty ? AppColors.grey300 : AppColors.grey900,
              textColor: Colors.white,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 构建金额输入卡片
  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: AppTextStyles.h1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey300,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              // 网络选择下拉框
              GestureDetector(
                onTap: _showNetworkSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.grey200, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppNetworkImage(
                        url: _selectedNetwork?.logo,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedNetwork?.symbol ?? '',
                        style: AppTextStyles.body.copyWith(
                           fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 12, color: AppColors.grey400),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${_amountController.text.isEmpty ? '0.00' : _fiatBalance}',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: AppColors.grey400,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.profileTransferBalance}: $_balance',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.grey700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _amountController.text = _balance.replaceAll(',', '');
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.grey900,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text(
                        'Max',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建收款地址输入
  Widget _buildAddressInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.profileTransferAddress,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.grey600,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: 处理扫描逻辑
              },
              child: Image.asset(
                'assets/images/profile/user/scan.png',
                width: 16,
                height: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: TextField(
                controller: _addressController,
                maxLines: null,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.grey900,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.profileTransferPleaseEnter,
                  hintStyle: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.grey400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical:8),
                ),
              ),
            ),
            // 粘贴按钮
            Positioned(
              bottom: -16,
              child: GestureDetector(
                onTap: () {
                  // TODO: 处理粘贴逻辑
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.grey200),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.black.withValues(alpha: 0.05),
                    //     blurRadius: 4,
                    //     offset: const Offset(0, 2),
                    //   ),
                    // ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/wallet/word.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '粘贴',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建矿工费部分
  Widget _buildMinerFeeSection() {
    final labels = [
      AppLocalizations.of(context)!.profileTransferSlow,
      'Middle',
      AppLocalizations.of(context)!.profileTransferFast
    ];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.profileTransferNetworkFees,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.grey600,
              ),
            ),
            Text(
              '0.00 (Estimated)',
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.grey400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            // 滑动条 (放在底层)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                activeTrackColor: const Color(0xFFD4FF00),
                inactiveTrackColor: AppColors.grey200,
                thumbColor: Colors.white,
                overlayColor: const Color(0xFFD4FF00).withValues(alpha: 0.1),
                thumbShape: const TransferSliderThumbShape(),
                trackShape: const TransferTrackShape(),
                tickMarkShape: SliderTickMarkShape.noTickMark,
              ),
              child: Slider(
                value: _feeProgress,
                min: 0,
                max: 1,
                divisions: 2, // Slow, Middle, Fast 对应 0, 0.5, 1
                onChanged: (value) {
                  setState(() {
                    _feeProgress = value;
                  });
                },
              ),
            ),
            // 轨道上的刻度点 (放在顶层以确保可见，同时使用 IgnorePointer 避免干扰 Slider 点击)
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(labels.length, (index) {
                    // 当前选中的项留空，由 Slider 的 Thumb 覆盖，以显示 Thumb 的白色中心
                    if ((index * 0.5) == _feeProgress) return const SizedBox(width: 0);
                    // 判断当前进度是否已经达到或超过该点
                    // Slider value 为 0, 0.5, 1.0 (3个点)
                    final isReached = (index * 0.5) <= _feeProgress;
                    return SizedBox(
                      width: 0,
                      child: UnconstrainedBox(
                        clipBehavior: Clip.none,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isReached ? const Color(0xFFD4FF00) : AppColors.grey200,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 38),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final isSelected = (index * 0.5) == _feeProgress;
              return SizedBox(
                width: 0,
                child: UnconstrainedBox(
                  clipBehavior: Clip.none,
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? AppColors.grey900 : AppColors.grey400,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                    softWrap: false,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeLabel(String label, bool isActive) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
        fontSize: 12,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        color: isActive ? AppColors.grey900 : AppColors.grey400,
      ),
    );
  }
}

/// 自定义滑块滑块形状
class TransferSliderThumbShape extends SliderComponentShape {
  const TransferSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(16, 16);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final paint = Paint()
      ..color = sliderTheme.activeTrackColor ?? const Color(0xFFD4FF00)
      ..style = PaintingStyle.fill;

    // 外圈尺寸 16 (半径 8)
    canvas.drawCircle(center, 8, paint);

    // 内圈白色尺寸 10 (半径 5)
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, whitePaint);
  }
}

/// 自定义轨道形状
class TransferTrackShape extends RoundedRectSliderTrackShape {
  const TransferTrackShape();
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    // 这里的 38 是为了让滑块（thumb）的移动范围缩小，从而在两头留出轨道
    // 32 (Row padding) + 6 (thumb radius adjustment)
    final double trackLeft = offset.dx + 38;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - 76;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    // 绘制范围：从 12 到 width - 12
    final double margin = 12.0;
    final Rect trackRect = Rect.fromLTWH(
      offset.dx + margin,
      offset.dy + (parentBox.size.height - sliderTheme.trackHeight!) / 2,
      parentBox.size.width - (margin * 2),
      sliderTheme.trackHeight!,
    );

    final Paint activePaint = Paint()..color = sliderTheme.activeTrackColor!;
    final Paint inactivePaint = Paint()..color = sliderTheme.inactiveTrackColor!;

    // 绘制背景（未激活部分）
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, const Radius.circular(3)),
      inactivePaint,
    );

    // 绘制激活部分（从轨道起点到滑块中心）
    final Rect activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(activeRect, const Radius.circular(3)),
      activePaint,
    );
  }
}
