import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

class ChatMoreItem {
  final String icon;
  final String label;
  final ChatMoreAction type;

  ChatMoreItem({
    required this.icon,
    required this.label,
    required this.type,
  });
}
enum ChatMoreAction {
  album,
  camera,
  videoCall,
  audioCall,
  redbag,
  file,
}
class ChatMorePanel extends StatelessWidget {
  final Function(ChatMoreItem item)? onItemTap;

  const ChatMorePanel({
    super.key,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final functions = [
      ChatMoreItem(
        icon: 'assets/images/common/photo.png',
        label: AppLocalizations.of(context)!.chatDetailAlbum,
        type: ChatMoreAction.album,
      ),
      ChatMoreItem(
        icon: 'assets/images/common/camera.png',
        label: AppLocalizations.of(context)!.chatDetailCamera,
        type: ChatMoreAction.camera,
      ),
      ChatMoreItem(
        icon: 'assets/images/common/video.png',
        label: AppLocalizations.of(context)!.chatDetailVideoCall,
        type: ChatMoreAction.videoCall,
      ),
      ChatMoreItem(
        icon: 'assets/images/common/voice.png',
        label: AppLocalizations.of(context)!.chatDetailAudioCall,
        type: ChatMoreAction.audioCall,
      ),
      // ChatMoreItem(
      //   icon: 'assets/images/common/redbag.png',
      //   label: AppLocalizations.of(context)!.chatDetailRedPacket,
      //   type: ChatMoreAction.redbag,
      // ),
      ChatMoreItem(
        icon: 'assets/images/common/file.png',
        label: AppLocalizations.of(context)!.chatDetailFile,
        type: ChatMoreAction.file,
      ),
    ];

    return Container(
      height: 240,
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          final item = functions[index];

          return GestureDetector(
            onTap: () => onItemTap?.call(item),
            child: Column(
              children: [
                Image.asset(item.icon, width: 44, height: 44),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.grey700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}