import 'package:flutter/material.dart';
import 'package:paracosm/widgets/chat/chat_bubble_painters.dart';

class ChatMessageContextMenu {
  ChatMessageContextMenu._();

  static Future<void> show(
    BuildContext context, {
    required Offset position,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;

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
                      children: const [
                        _ChatMessageContextMenuItem(
                          icon: 'assets/images/chat/copy.png',
                          label: 'Copy',
                        ),
                        _ChatMessageContextMenuItem(
                          icon: 'assets/images/chat/share.png',
                          label: 'transpond',
                        ),
                        _ChatMessageContextMenuItem(
                          icon: 'assets/images/chat/translate.png',
                          label: 'translate',
                        ),
                        _ChatMessageContextMenuItem(
                          icon: 'assets/images/chat/quote.png',
                          label: 'quote',
                        ),
                        _ChatMessageContextMenuItem(
                          icon: 'assets/images/chat/recall.png',
                          label: 'recall',
                        ),
                        _ChatMessageContextMenuItem(
                          icon: 'assets/images/chat/delete-msg.png',
                          label: 'Delete',
                        ),
                        _ChatMessageContextMenuItem(
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
  });

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
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
    );
  }
}
