import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/chat/chat_bubble_painters.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

class ChatMessageContextMenu {
  ChatMessageContextMenu._();

  static Future<void> show(
    BuildContext context, {
    required Offset position,
    String? copyText,
    VoidCallback? onDelete,
    VoidCallback? onRecall,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final trimmedCopyText = copyText?.trim();
    final canCopy = trimmedCopyText != null && trimmedCopyText.isNotEmpty;

    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => Stack(
        children: [
          Positioned(
            left: 20,
            right: 20,
            bottom: screenHeight - position.dy + 25,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Wrap(
                      spacing: 0,
                      runSpacing: 20,
                      alignment: WrapAlignment.start,
                      children: [
                        _ChatMessageContextMenuItem(
                          icon: 'assets/images/chat/copy.png',
                          label: 'Copy',
                          enabled: canCopy,
                          onTap: canCopy
                              ? () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: trimmedCopyText),
                                  );
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                  if (context.mounted) {
                                    AppToast.show(
                                      AppLocalizations.of(
                                        context,
                                      )!.commonCopied,
                                    );
                                  }
                                }
                              : null,
                        ),
                        const _ChatMessageContextMenuItem(
                          icon: 'assets/images/chat/share.png',
                          label: 'transpond',
                        ),
                        const _ChatMessageContextMenuItem(
                          icon: 'assets/images/chat/translate.png',
                          label: 'translate',
                        ),
                        const _ChatMessageContextMenuItem(
                          icon: 'assets/images/chat/quote.png',
                          label: 'quote',
                        ),
                        if (onRecall != null)
                          _ChatMessageContextMenuItem(
                            icon: 'assets/images/chat/recall.png',
                            label: 'recall',
                            onTap: () {
                              Navigator.pop(dialogContext);
                              onRecall();
                            },
                          ),
                        _ChatMessageContextMenuItem(
                          icon: 'assets/images/chat/delete-msg.png',
                          label: 'Delete',
                          enabled: onDelete != null,
                          onTap: onDelete == null
                              ? null
                              : () {
                                  Navigator.pop(dialogContext);
                                  onDelete();
                                },
                        ),
                        const _ChatMessageContextMenuItem(
                          icon: 'assets/images/chat/select.png',
                          label: 'select',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: (position.dx - 20 - 10).clamp(
                        16.0,
                        MediaQuery.of(context).size.width - 72,
                      ),
                    ),
                    child: CustomPaint(
                      size: const Size(20, 10),
                      painter: TrianglePainter(),
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
}

class _ChatMessageContextMenuItem extends StatelessWidget {
  const _ChatMessageContextMenuItem({
    required this.icon,
    required this.label,
    this.enabled = true,
    this.onTap,
  });

  final String icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? (onTap ?? () => Navigator.pop(context)) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: SizedBox(
          width: (MediaQuery.of(context).size.width - 72) / 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(icon, width: 24, height: 24, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
