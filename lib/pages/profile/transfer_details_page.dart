import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_button.dart';

/// 转账详情页面状态
enum TransferStatus {
  waiting,
  success,
  fail,
}

/// 转账详情页面
class TransferDetailsPage extends StatefulWidget {
  const TransferDetailsPage({super.key});

  @override
  State<TransferDetailsPage> createState() => _TransferDetailsPageState();
}

class _TransferDetailsPageState extends State<TransferDetailsPage> {
  TransferStatus _status = TransferStatus.waiting;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // 模拟等待 2 秒后随机成功或失败
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _status = Random().nextBool() ? TransferStatus.success : TransferStatus.fail;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// 复制文本到剪贴板
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.profileTransferDetailsCopiedToClipboard,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: AppLocalizations.of(context)!.profileTransferDetailsTransferDetails,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 状态图标
            _buildStatusIcon(),
            const SizedBox(height: 16),
            // 金额显示
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '-321',
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/profile/bnb-small.png',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 状态文本
            _buildStatusText(),
            const SizedBox(height: 32),
            // 详情卡片
            _buildDetailsCard(),
            const Spacer(),
            // 底部按钮
            AppButton(
              text: AppLocalizations.of(context)!.profileTransferDetailsContinueToTransfer,
              onPressed: () => context.pop(),
              backgroundColor: AppColors.grey900,
              textColor: Colors.white,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    String iconPath;
    switch (_status) {
      case TransferStatus.waiting:
        iconPath = 'assets/images/profile/transfer-waitting.png';
        break;
      case TransferStatus.success:
        iconPath = 'assets/images/profile/transfer-success.png';
        break;
      case TransferStatus.fail:
        iconPath = 'assets/images/profile/transfer-fail.png';
        break;
    }
    return Image.asset(
      iconPath,
      width: 160,
      height: 160,
    );
  }

  /// 构建状态文本
  Widget _buildStatusText() {
    String text;
    Color color;
    switch (_status) {
      case TransferStatus.waiting:
        text = AppLocalizations.of(context)!.profileTransferDetailsTransferWaiting;
        color = AppColors.grey500;
        break;
      case TransferStatus.success:
        text = AppLocalizations.of(context)!.profileTransferDetailsTransferSuccess;
        color = AppColors.primary;
        break;
      case TransferStatus.fail:
        text = AppLocalizations.of(context)!.profileTransferDetailsTransferFail;
        color = AppColors.error;
        break;
    }
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }

  /// 构建详情卡片
  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            AppLocalizations.of(context)!.profileTransferDetailsSender,
            '0xc84sa01ua125d15uvcbv78fa98uu9daccf915uvc',
            isCopyable: true,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            AppLocalizations.of(context)!.profileTransferDetailsRecipient,
            '0xc84sa01ua125d15uvcbv78fa98uu9daccf915uvc',
            isCopyable: true,
          ),
          const Divider(height: 32, color: AppColors.grey200),
          _buildInfoRow(
            AppLocalizations.of(context)!.profileTransferDetailsTransactionFee,
            '0.000458 BNB',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            AppLocalizations.of(context)!.profileTransferDetailsTransactionHash,
            '0xc84sa01ua125d15uvcbv78fa98uu9daccf915uvc',
            isCopyable: true,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            AppLocalizations.of(context)!.profileTransferDetailsTransactionTime,
            '2024-03-27 12:00:00',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isCopyable = false, bool hasInfoIcon = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
        Row(
          children: [
            if (isCopyable) ...[
              GestureDetector(
                onTap: () => _copyToClipboard(value),
                child: Image.asset(
                  'assets/images/common/copy-grey.png',
                  width: 16,
                  height: 16,
                ),
              ),
              const SizedBox(width: 1),
            ],
            if (hasInfoIcon) ...[
              const Icon(Icons.info_outline, size: 12, color: AppColors.grey400),
              const SizedBox(width: 1),
            ],
            Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.grey800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
