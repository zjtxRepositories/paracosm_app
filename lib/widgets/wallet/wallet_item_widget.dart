import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../modules/wallet/model/wallet_model.dart';
import '../base/app_localizations.dart';
import '../common/app_checkbox.dart';
import '../common/app_toast.dart';

class WalletItemWidget extends StatelessWidget {
  final WalletModel? wallet;
  final String address;
  final String? avatarUrl;
  final bool isSelected;
  final Future<void> Function()? onTap;

  const WalletItemWidget({
    super.key,
    required this.wallet,
    required this.address,
    this.avatarUrl,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final showName =
        wallet?.name ??
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
          UserAvatarWidget(
            userId: address.toLowerCase(),
            avatarUrl: avatarUrl,
            size: 44,
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: address));
                        AppToast.show(
                          AppLocalizations.of(context)!.commonCopied,
                        );
                      },
                      child: Image.asset(
                        'assets/images/common/copy-grey.png',
                        width: 16,
                        height: 16,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      ellipsisMiddle(address),
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.grey400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 选中状态
          AppCheckbox(value: isSelected, isRadio: false, size: 24),
        ],
      ),
    );
  }
}
