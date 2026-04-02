import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_network_image.dart';

class WalletCardWidget extends StatelessWidget {
  final String walletName;
  final String? networkSymbol;
  final String? networkLogo;

  final bool isBalanceVisible;
  final double? totalBalance;

  final bool showActions;

  final VoidCallback? onToggleBalance;
  final VoidCallback? onNetworkTap;
  final VoidCallback? onWalletTap;

  const WalletCardWidget({
    super.key,
    required this.walletName,
    required this.isBalanceVisible,
    this.totalBalance,
    this.networkSymbol,
    this.networkLogo,
    this.showActions = true,
    this.onToggleBalance,
    this.onNetworkTap,
    this.onWalletTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 顶部
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// 钱包名
              GestureDetector(
                onTap: onWalletTap,
                child: Row(
                  children: [
                    Text(
                      walletName,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.grey400,
                        fontSize: 14,
                      ),
                    ),
                    if (showActions) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.grey400),
                    ],
                  ],
                ),
              ),

              /// 网络选择
              GestureDetector(
                onTap: onNetworkTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.grey200, width: 1),
                  ),
                  child: Row(
                    children: [
                      if (networkLogo != null)
                        AppNetworkImage(
                          url: networkLogo,
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        networkSymbol ?? '',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 12, color: AppColors.grey400),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// 余额
          Row(
            children: [
              Text(
                isBalanceVisible
                    ? '\$${totalBalance?.toStringAsFixed(2) ?? '0.00'}'
                    : '******',
                style: AppTextStyles.body.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(width: 8),

              GestureDetector(
                onTap: onToggleBalance,
                child: Icon(
                  isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}