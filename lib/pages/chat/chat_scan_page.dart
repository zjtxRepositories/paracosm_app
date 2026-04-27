import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';

/// 聊天页扫一扫静态页面。
///
/// 这里只还原 UI，不接入真实相机能力。
class ChatScanPage extends StatelessWidget {
  const ChatScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: false,
      backTheme: Brightness.dark,
      isAddBottomMargin: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/chat/scan-bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC000000),
                    Color(0x8A000000),
                    Color(0xDD000000),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.18)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  _buildTopBar(context),
                  const Spacer(flex: 2),
                  _buildScanArea(),
                  const SizedBox(height: 80),
                  _buildHintText(context),
                  const Spacer(flex: 3),
                  _buildAlbumButton(context),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  // _buildHomeIndicator(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Image.asset(
              'assets/images/common/back-icon-black.png',
              width: 32,
              height: 32,
            ),
          ),
          const Spacer(),
          Text(
            'Scan',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Image.asset(
              'assets/images/chat/photo.png',
              width: 32,
              height: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanSize = constraints.maxWidth * 0.66;
        return SizedBox(
          width: scanSize,
          height: scanSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/chat/border.png',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: OverflowBox(
                    minWidth: MediaQuery.of(context).size.width,
                    maxWidth: MediaQuery.of(context).size.width,
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: const Offset(0, 40),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 164,
                        child: Image.asset(
                          'assets/images/chat/scan-line.png',
                          fit: BoxFit.fill,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHintText(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        'Put the QR code/bar code into the box and it can be scanned automatically',
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(
          color: const Color(0xFF8A8A8A),
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildAlbumButton(BuildContext context) {
    return AppButton(
      text: 'Album',
      onPressed: () {},
      backgroundColor: AppColors.primary,
      textColor: AppColors.grey900
    );
  }

  Widget _buildHomeIndicator() {
    return Container(
      width: 120,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
