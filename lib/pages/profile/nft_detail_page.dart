import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/nft_asset_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_network_image.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

class NftDetailPage extends StatelessWidget {
  const NftDetailPage({super.key, required this.asset});

  final NftAssetModel asset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chain = _resolveChain(asset.chainId);
    final networkName = chain?.name ?? 'Chain #${asset.chainId}';
    return AppPage(
      showNav: true,
      title: asset.displayLabel,
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.white,
      navBackgroundColor: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = constraints.maxWidth;
          final cardTop = imageHeight - 52;
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: imageHeight,
                child: _buildCoverImage(),
              ),
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: cardTop),
                  child: _buildContentCard(context, l10n, chain, networkName),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: cardTop,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: asset.displayImageUrl.isNotEmpty
                      ? () => _showImagePreview(context)
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContentCard(
    BuildContext context,
    AppLocalizations l10n,
    ChainAccount? chain,
    String networkName,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildTitle(chain, networkName),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (asset.description.isNotEmpty) ...[
                  _buildSection(
                    title: l10n.profileNftDetailDescription,
                    child: Text(
                      asset.description,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.grey700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildSection(
                  title: l10n.profileTokenDetailPaymentDetails,
                  child: Column(
                    children: [
                      _buildDetailRow(
                        context,
                        label: l10n.profileNftDetailCollection,
                        value: asset.collectionName,
                      ),
                      _buildDetailRow(
                        context,
                        label: l10n.profileNftDetailNetwork,
                        value: networkName,
                      ),
                      _buildDetailRow(
                        context,
                        label: l10n.profileNftDetailTokenType,
                        value: nftTokenTypeToString(asset.tokenType),
                      ),
                      _buildDetailRow(
                        context,
                        label: l10n.profileNftDetailBalance,
                        value: asset.balance.toString(),
                      ),
                      _buildDetailRow(
                        context,
                        label: l10n.profileNftDetailContractAddress,
                        value: asset.contractAddress,
                        copyable: true,
                      ),
                      _buildDetailRow(
                        context,
                        label: l10n.profileNftDetailTokenId,
                        value: asset.tokenId,
                        copyable: true,
                      ),
                      _buildDetailRow(
                        context,
                        label: l10n.profileNftDetailOwner,
                        value: asset.ownerAddress,
                        copyable: true,
                      ),
                      if (asset.metadataUri.isNotEmpty)
                        _buildDetailRow(
                          context,
                          label: l10n.profileNftDetailMetadataUri,
                          value: asset.metadataUri,
                          copyable: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: l10n.profileNftDetailStatus,
                  child: Column(
                    children: [
                      _buildDetailRow(
                        context,
                        label: l10n.profileNftDetailSpam,
                        value: asset.isSpam ? l10n.commonYes : l10n.commonNo,
                        compact: false,
                      ),
                      _buildDetailRow(
                        context,
                        label: l10n.profileNftDetailHidden,
                        value: asset.isHidden ? l10n.commonYes : l10n.commonNo,
                        compact: false,
                      ),
                      _buildDetailRow(
                        context,
                        label: l10n.profileNftDetailLastSynced,
                        value: _formatTime(asset.lastSyncedAt),
                        compact: false,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    if (asset.displayImageUrl.isEmpty) {
      return Container(
        color: AppColors.grey100,
        alignment: Alignment.center,
        child: const Icon(Icons.image, size: 54, color: AppColors.grey400),
      );
    }
    return AppNetworkImage(
      url: asset.displayImageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.zero,
    );
  }

  Future<void> _showImagePreview(BuildContext context) async {
    final url = asset.displayImageUrl;
    if (url.isEmpty) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'NFT image preview',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: AppNetworkImage(
                      url: url,
                      width: MediaQuery.sizeOf(context).width,
                      height: MediaQuery.sizeOf(context).height,
                      fit: BoxFit.contain,
                      borderRadius: BorderRadius.zero,
                      placeholder: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: SafeArea(
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  Widget _buildTitle(ChainAccount? chain, String network) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            asset.displayLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h2.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (chain?.logo.isNotEmpty == true) ...[
                AppNetworkImage(
                  url: chain!.logo,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  [
                    if (asset.collectionName.isNotEmpty) asset.collectionName,
                    network,
                    nftTokenTypeToString(asset.tokenType),
                    if (asset.balance > BigInt.one) 'x${asset.balance}',
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.grey500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    bool copyable = false,
    bool compact = true,
    bool isLast = false,
  }) {
    final displayValue = value.isEmpty ? '-' : value;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.grey500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: copyable && value.isNotEmpty
                  ? () => _copy(context, value)
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (copyable && value.isNotEmpty) ...[
                    const Icon(Icons.copy, size: 14, color: AppColors.grey400),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      compact && value.isNotEmpty
                          ? ellipsisMiddle(displayValue, head: 8, tail: 6)
                          : displayValue,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ChainAccount? _resolveChain(int chainId) {
    final wallet = AccountManager().currentWallet;
    if (wallet == null) return null;
    for (final chain in wallet.chains) {
      if (chain.chainId == chainId) {
        return chain;
      }
    }
    return null;
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      AppToast.show(AppLocalizations.of(context)!.commonCopied);
    }
  }

  String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }
}
