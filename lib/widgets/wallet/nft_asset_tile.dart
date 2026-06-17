import 'package:flutter/material.dart';
import 'package:paracosm/modules/wallet/model/nft_asset_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/common/app_network_image.dart';

class NftAssetTile extends StatelessWidget {
  const NftAssetTile({
    super.key,
    required this.asset,
    this.networkLogo,
    this.onTap,
    this.isCompact = false,
  });

  final NftAssetModel asset;
  final String? networkLogo;
  final VoidCallback? onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isCompact ? 10 : 12,
          horizontal: isCompact ? 0 : 12,
        ),
        decoration: isCompact
            ? null
            : BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200, width: 1),
              ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildNftImage(),
                ),
                if (networkLogo?.isNotEmpty == true)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: AppNetworkImage(
                        url: networkLogo,
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    asset.displaySubLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            if (asset.balance > BigInt.one) ...[
              const SizedBox(width: 8),
              Text(
                'x${asset.balance}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNftImage() {
    final imageUrl = asset.displayImageUrl;
    if (imageUrl.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image, size: 22, color: AppColors.grey400),
      );
    }
    return AppNetworkImage(
      url: imageUrl,
      width: 44,
      height: 44,
      fit: BoxFit.cover,
    );
  }
}
