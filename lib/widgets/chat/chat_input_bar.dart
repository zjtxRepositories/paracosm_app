import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isVoiceMode,
    required this.isRecording,
    required this.isCancelling,
    required this.isMenuExpanded,
    required this.isInputEmpty,
    required this.onToggleVoiceMode,
    required this.onTextFieldTap,
    required this.onActionTap,
    required this.onVoiceLongPressStart,
    required this.onVoiceLongPressMoveUpdate,
    required this.onVoiceLongPressEnd,
  });

  final TextEditingController controller;
  final bool isVoiceMode;
  final bool isRecording;
  final bool isCancelling;
  final bool isMenuExpanded;
  final bool isInputEmpty;
  final VoidCallback onToggleVoiceMode;
  final VoidCallback onTextFieldTap;
  final VoidCallback onActionTap;
  final GestureLongPressStartCallback onVoiceLongPressStart;
  final GestureLongPressMoveUpdateCallback onVoiceLongPressMoveUpdate;
  final GestureLongPressEndCallback onVoiceLongPressEnd;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: bottom > 0 ? bottom : bottom + 12 ,
      ),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleVoiceMode,
            child: Image.asset(
              isVoiceMode
                  ? 'assets/images/chat/keyboard.png'
                  : 'assets/images/chat/microphone.png',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isVoiceMode
                ? GestureDetector(
                    onLongPressStart: onVoiceLongPressStart,
                    onLongPressMoveUpdate: onVoiceLongPressMoveUpdate,
                    onLongPressEnd: onVoiceLongPressEnd,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.topBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isRecording
                            ? (isCancelling
                                ? AppLocalizations.of(context)!.chatDetailReleaseToCancel
                                : AppLocalizations.of(context)!.chatDetailReleaseToEnd)
                            : AppLocalizations.of(context)!.chatDetailHoldToTalk,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.topBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: controller,
                      onTap: onTextFieldTap,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Image.asset('assets/images/chat/emoj.png', width: 24, height: 24),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onActionTap,
            child: Image.asset(
              !isInputEmpty
                  ? 'assets/images/chat/send.png'
                  : (isMenuExpanded
                      ? 'assets/images/chat/function-close.png'
                      : 'assets/images/chat/more-function.png'),
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }
}
