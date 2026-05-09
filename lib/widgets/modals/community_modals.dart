import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/widgets/modals/wallet_modals.dart';
import 'package:paracosm/widgets/modals/wallet_select_token_modal.dart';

import '../../modules/wallet/model/token_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../base/app_localizations.dart';
import '../common/app_modal.dart';

class CommunityModals {
  static Future<void> showSelectedDao({
    required BuildContext context,
    required Function(TokenModel) onSelected,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    AppModal.show(
      context,
      title: l10n.communityModalSelectDaoTypeTitle,
      confirmText: null, // 移除底部确认按钮
      onConfirm: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDaoTypeCard(
            icon: 'assets/images/community/token.png',
            title: l10n.communityModalTokenHoldingGroupTitle,
            description: l10n.communityModalTokenHoldingGroupDesc,
            onTap: () async {
              await Future.delayed(const Duration(milliseconds: 200));

              if (context.mounted) {
                showSelectTokenModal(context: context, type: AssetType.token,onSelected: onSelected);
              }
            },
          ),
          const SizedBox(height: 16),
          _buildDaoTypeCard(
            icon: 'assets/images/community/nft.png',
            title: l10n.communityModalNftHoldingGroupTitle,
            description: l10n.communityModalNftHoldingGroupDesc,
            onTap: () async {
              await Future.delayed(const Duration(milliseconds: 200));

              if (context.mounted) {
                showSelectTokenModal(context: context, type: AssetType.nft,onSelected: onSelected);
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  /// 显示选择代币弹窗
  static showSelectTokenModal({
    required BuildContext context,
    required AssetType type,
    required Function(TokenModel) onSelected,
  }) {
    final currentWallet = AccountManager().currentWallet;
    if (currentWallet == null) return;
    WalletModals.showTokenSelector(
      context: context,
      wallet: currentWallet,
      type: type,
      onSelected: (token) {
        onSelected(token);
      },
    );
  }
  static Widget _buildDaoTypeCard({
    required String icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          children: [
            // 图标容器
            Image.asset(
              icon,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.stars,size: 48, color: AppColors.grey400),
            ),
            const SizedBox(width: 16),
            // 文本信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            // 右侧箭头
            const Icon(Icons.chevron_right, color: AppColors.grey400, size: 24),
          ],
        ),
      ),
    );
  }

  /// 构建弹窗中的网络筛选 Chip
 static Widget _buildNetworkChip({
    required String icon,
    required String label,
    required bool isSelected,
    bool showArrow = false,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 4,top: 5, right: 12, bottom: 5),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? Colors.transparent : AppColors.grey200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            icon,
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.public, size: 20, color: AppColors.grey400),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.grey900,
            ),
          ),
          if (showArrow) ...[
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                size: 16, color: AppColors.grey400),
          ],
        ],
      ),
    );
  }

  /// 构建弹窗中的代币列表项
  static Widget _buildTokenModalItem({
    required String icon,
    required String symbol,
    required String amount,
    required String value,
  }) {
    return Row(
      children: [
        // 代币图标
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Image.asset(
            icon,
            width: 44,
            height: 44,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.token, size: 44, color: AppColors.grey200),
          ),
        ),
        const SizedBox(width: 8),
        // 右侧内容区域（带下划线）
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.grey100, width: 1),
              ),
            ),
            child: Row(
              children: [
                // 符号
                Expanded(
                  child: Text(
                    symbol,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey900,
                    ),
                  ),
                ),
                // 数量和价值
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}