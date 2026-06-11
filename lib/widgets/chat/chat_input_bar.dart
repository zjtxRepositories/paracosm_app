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
    required this.isEmojiPanelExpanded,
    required this.isInputEmpty,
    required this.onToggleVoiceMode,
    required this.onTextFieldTap,
    required this.onEmojiTap,
    required this.onActionTap,
    required this.onVoiceLongPressStart,
    required this.onVoiceLongPressMoveUpdate,
    required this.onVoiceLongPressEnd,
    this.isDisabled = false,
    this.disabledText,
    this.quoteText,
    this.onClearQuote,
  });

  final TextEditingController controller;
  final bool isVoiceMode;
  final bool isRecording;
  final bool isCancelling;
  final bool isMenuExpanded;
  final bool isEmojiPanelExpanded;
  final bool isInputEmpty;
  final VoidCallback onToggleVoiceMode;
  final VoidCallback onTextFieldTap;
  final VoidCallback onEmojiTap;
  final VoidCallback onActionTap;
  final GestureLongPressStartCallback onVoiceLongPressStart;
  final GestureLongPressMoveUpdateCallback onVoiceLongPressMoveUpdate;
  final GestureLongPressEndCallback onVoiceLongPressEnd;
  final bool isDisabled;
  final String? disabledText;
  final String? quoteText;
  final VoidCallback? onClearQuote;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final quote = quoteText?.trim();
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: bottom > 0 ? bottom : bottom + 12,
      ),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quote != null && quote.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.topBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      quote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClearQuote,
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              GestureDetector(
                onTap: isDisabled ? null : onToggleVoiceMode,
                child: Opacity(
                  opacity: isDisabled ? 0.4 : 1,
                  child: Image.asset(
                    isVoiceMode
                        ? 'assets/images/chat/keyboard.png'
                        : 'assets/images/chat/microphone.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isDisabled
                    ? Container(
                        height: 44,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.topBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          disabledText ??
                              AppLocalizations.of(
                                context,
                              )!.chatDetailGroupMutedInputHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : isVoiceMode
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
                                      ? AppLocalizations.of(
                                          context,
                                        )!.chatDetailReleaseToCancel
                                      : AppLocalizations.of(
                                          context,
                                        )!.chatDetailReleaseToEnd)
                                : AppLocalizations.of(
                                    context,
                                  )!.chatDetailHoldToTalk,
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isDisabled ? null : onEmojiTap,
                child: Opacity(
                  opacity: isDisabled ? 0.4 : 1,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset(
                      isEmojiPanelExpanded
                          ? 'assets/images/chat/keyboard.png'
                          : 'assets/images/chat/emoj.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: isDisabled ? null : onActionTap,
                child: Opacity(
                  opacity: isDisabled ? 0.4 : 1,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
