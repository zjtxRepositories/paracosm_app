import 'package:flutter/material.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/widgets/modals/wallet_modals.dart';

import '../../modules/wallet/model/nft_asset_model.dart';
import '../../modules/wallet/model/token_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../base/app_localizations.dart';
import '../common/app_modal.dart';

class CommunityModals {
  static Future<void> showSelectedDao({
    required BuildContext context,
    required Function(TokenModel) onTokenSelected,
    Function(NftAssetModel)? onNftSelected,
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
                showSelectTokenModal(
                  context: context,
                  onSelected: onTokenSelected,
                );
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
                showSelectNftModal(context: context, onSelected: onNftSelected);
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 显示选择代币弹窗
  static void showSelectTokenModal({
    required BuildContext context,
    required Function(TokenModel) onSelected,
  }) {
    final currentWallet = AccountManager().currentWallet;
    if (currentWallet == null) return;
    WalletModals.showTokenSelector(
      context: context,
      wallet: currentWallet,
      onSelected: (token) {
        onSelected(token);
      },
    );
  }

  /// 显示选择 NFT 弹窗
  static void showSelectNftModal({
    required BuildContext context,
    Function(NftAssetModel)? onSelected,
  }) {
    final currentWallet = AccountManager().currentWallet;
    if (currentWallet == null) return;
    WalletModals.showNftSelector(
      context: context,
      wallet: currentWallet,
      onSelected: (asset) {
        onSelected?.call(asset);
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
                  const Icon(Icons.stars, size: 48, color: AppColors.grey400),
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
}
