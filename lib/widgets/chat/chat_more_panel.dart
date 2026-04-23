import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

class ChatMorePanel extends StatelessWidget {
  const ChatMorePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final functions = [
      {
        'icon': 'assets/images/common/photo.png',
        'label': AppLocalizations.of(context)!.chatDetailAlbum,
      },
      {
        'icon': 'assets/images/common/camera.png',
        'label': AppLocalizations.of(context)!.chatDetailCamera,
      },
      {
        'icon': 'assets/images/common/video.png',
        'label': AppLocalizations.of(context)!.chatDetailVideoCall,
      },
      {
        'icon': 'assets/images/common/voice.png',
        'label': AppLocalizations.of(context)!.chatDetailAudioCall,
      },
      {
        'icon': 'assets/images/common/redbag.png',
        'label': AppLocalizations.of(context)!.chatDetailRedPacket,
      },
      {
        'icon': 'assets/images/common/file.png',
        'label': AppLocalizations.of(context)!.chatDetailFile,
      },
    ];

    return Container(
      height: 260,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(color: Colors.white),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 18,
          crossAxisSpacing: 24,
          childAspectRatio: 0.8,
        ),
        itemCount: functions.length,
        itemBuilder: (context, index) {
          final func = functions[index];
          return Column(
            children: [
              Image.asset(func['icon']!, width: 44, height: 44),
              const SizedBox(height: 8),
              Text(
                func['label']!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.grey700,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
