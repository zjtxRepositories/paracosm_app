import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

/// 聊天页扫一扫页面。
class ChatScanPage extends StatefulWidget {
  const ChatScanPage({super.key});

  @override
  State<ChatScanPage> createState() => _ChatScanPageState();
}

class _ChatScanPageState extends State<ChatScanPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();
  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnimation;

  bool _handled = false;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scanLineAnimation = CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    unawaited(_controller.dispose());
    super.dispose();
  }

  String? _firstCode(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  void _returnCode(String? code) {
    if (_handled || code == null || code.trim().isEmpty) {
      return;
    }

    _handled = true;
    context.pop(code.trim());
  }

  Future<void> _pickFromAlbum() async {
    if (_isPicking) {
      return;
    }

    setState(() {
      _isPicking = true;
    });

    try {
      await _controller.stop();
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (!mounted) {
        return;
      }

      if (image == null) {
        await _controller.start();
        return;
      }

      final capture = await _controller.analyzeImage(image.path);
      if (!mounted) {
        return;
      }

      final code = capture == null ? null : _firstCode(capture);
      if (code == null) {
        AppToast.show(AppLocalizations.of(context)!.discoverScanNoResult);
        await _controller.start();
        return;
      }

      _returnCode(code);
    } catch (e) {
      if (mounted) {
        AppToast.show(AppLocalizations.of(context)!.discoverScanNoResult);
        await _controller.start();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: false,
      backTheme: Brightness.dark,
      isAddBottomMargin: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              fit: BoxFit.cover,
              onDetect: (capture) {
                _returnCode(_firstCode(capture));
              },
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
    final l10n = AppLocalizations.of(context)!;

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
            l10n.chatMenuScan,
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _isPicking ? null : _pickFromAlbum,
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
        final screenWidth = MediaQuery.of(context).size.width;
        const scanLineHeight = 164.0;
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
                child: AnimatedBuilder(
                  animation: _scanLineAnimation,
                  child: Image.asset(
                    'assets/images/chat/scan-line.png',
                    fit: BoxFit.fill,
                    alignment: Alignment.center,
                  ),
                  builder: (context, child) {
                    final top = Tween<double>(
                      begin: scanSize - 20,
                      end: -scanLineHeight,
                    ).evaluate(_scanLineAnimation);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: top,
                          left: -(screenWidth - scanSize) / 2,
                          width: screenWidth,
                          height: scanLineHeight,
                          child: child!,
                        ),
                      ],
                    );
                  },
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
    final l10n = AppLocalizations.of(context)!;

    return AppButton(
      text: l10n.chatDetailAlbum,
      onPressed: _isPicking ? null : _pickFromAlbum,
      backgroundColor: AppColors.primary,
      textColor: AppColors.grey900,
      isLoading: _isPicking,
    );
  }
}
