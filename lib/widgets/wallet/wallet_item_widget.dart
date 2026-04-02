import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../modules/wallet/model/wallet_model.dart';
import '../base/app_localizations.dart';
import '../common/app_checkbox.dart';

class WalletItemWidget extends StatelessWidget {
  final WalletModel? wallet;
  final String address;
  final bool isSelected;
  final Future<void> Function()? onTap;

  const WalletItemWidget({
    super.key,
    required this.wallet,
    required this.address,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final showName = wallet?.name ??
        '${l10n.profileProfileDetailsWallet} ${(wallet?.aIndex ?? 0) + 1}';

    return GestureDetector(
      onTap: () async {
        if (onTap != null) {
          await onTap!();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          /// 头像
          ClipOval(
            child: Image.asset(
              'assets/images/chat/avatar.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),

          /// 钱包信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showName,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                Text(
                  address,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),

          /// 选中状态
          AppCheckbox(
            value: isSelected,
            isRadio: false,
            size: 24,
          ),
        ],
      ),
    );
  }
}